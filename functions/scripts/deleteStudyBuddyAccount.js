#!/usr/bin/env node

/**
 * Study Buddy manual account deletion tool.
 *
 * Run from the functions directory:
 *
 * Dry run:
 *   node scripts/deleteStudyBuddyAccount.js --uid UID --email user@example.com
 *
 * Confirmed deletion:
 *   node scripts/deleteStudyBuddyAccount.js --uid UID --email user@example.com --confirm-delete
 *
 * This script requires Firebase Admin credentials in the environment.
 * Recommended local setup:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
 */

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const storage = getStorage();

function parseArgs(argv) {
  const args = {
    confirmDelete: false,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = argv[index];

    if (value === "--confirm-delete") {
      args.confirmDelete = true;
      continue;
    }

    if (value === "--uid") {
      args.uid = argv[index + 1];
      index += 1;
      continue;
    }

    if (value === "--email") {
      args.email = argv[index + 1];
      index += 1;
      continue;
    }

    throw new Error(`Unknown argument: ${value}`);
  }

  return args;
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function requireArgs(args) {
  if (!args.uid || !args.email) {
    throw new Error(
      "Missing required args. Usage: node scripts/deleteStudyBuddyAccount.js --uid UID --email user@example.com [--confirm-delete]"
    );
  }
}

async function listStorageFilesByPrefix(bucket, prefix) {
  const [files] = await bucket.getFiles({ prefix });
  return files;
}

async function deleteStorageFiles(bucket, files, dryRun) {
  for (const file of files) {
    console.log(`${dryRun ? "[dry-run]" : "[delete]"} Storage: ${file.name}`);
    if (!dryRun) {
      await file.delete({ ignoreNotFound: true });
    }
  }
}

async function deleteQuerySnapshot(snapshot, dryRun, label) {
  for (const doc of snapshot.docs) {
    console.log(`${dryRun ? "[dry-run]" : "[delete]"} ${label}: ${doc.ref.path}`);
    if (!dryRun) {
      await doc.ref.delete();
    }
  }
}

async function recursiveDeleteDoc(docRef, dryRun) {
  console.log(`${dryRun ? "[dry-run]" : "[delete]"} Firestore recursive: ${docRef.path}`);
  if (!dryRun) {
    await db.recursiveDelete(docRef);
  }
}

async function main() {
  const args = parseArgs(process.argv);
  requireArgs(args);

  const uid = args.uid.trim();
  const emailLower = normalizeEmail(args.email);
  const dryRun = !args.confirmDelete;

  console.log("");
  console.log("Study Buddy account deletion tool");
  console.log("--------------------------------");
  console.log(`UID: ${uid}`);
  console.log(`Email: ${emailLower}`);
  console.log(`Mode: ${dryRun ? "DRY RUN" : "CONFIRMED DELETE"}`);
  console.log("");

  const lookupRef = db.collection("userEmailLookup").doc(emailLower);
  const lookupSnap = await lookupRef.get();

  if (lookupSnap.exists) {
    const lookup = lookupSnap.data() || {};
    if (lookup.uid !== uid) {
      throw new Error(
        `Refusing to continue. userEmailLookup/${emailLower} uid=${lookup.uid} does not match provided uid=${uid}.`
      );
    }
    console.log(`Verified email lookup: userEmailLookup/${emailLower} -> ${uid}`);
  } else {
    console.log(
      `No userEmailLookup/${emailLower} document found. Continuing only because UID was explicitly provided.`
    );
  }

  try {
    const authUser = await auth.getUser(uid);
    const authEmail = normalizeEmail(authUser.email);
    if (authEmail && authEmail !== emailLower) {
      throw new Error(
        `Refusing to continue. Firebase Auth email=${authEmail} does not match provided email=${emailLower}.`
      );
    }
    console.log(`Verified Firebase Auth user: ${uid}`);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      console.log(`Firebase Auth user not found for UID ${uid}. It may already be deleted.`);
    } else {
      throw error;
    }
  }

  const deletionLogRef = db.collection("accountDeletionRequests").doc();
  console.log(
    `${dryRun ? "[dry-run]" : "[write]"} Minimal deletion log: ${deletionLogRef.path}`
  );

  if (!dryRun) {
    await deletionLogRef.set({
      uid,
      emailLower,
      source: "manual_admin_script",
      status: "running",
      startedAt: FieldValue.serverTimestamp(),
    });
  }

  try {
    const bucket = storage.bucket();
    const storagePrefixes = [
      `recordings/${uid}/`,
      `classMaterials/${uid}/`,
      `user_photos/${uid}/`,
    ];

    for (const prefix of storagePrefixes) {
      const files = await listStorageFilesByPrefix(bucket, prefix);
      console.log(`Found ${files.length} Storage file(s) under ${prefix}`);
      await deleteStorageFiles(bucket, files, dryRun);
    }

    const aiJobsSnap = await db.collection("aiJobs").where("uid", "==", uid).get();
    console.log(`Found ${aiJobsSnap.size} aiJobs document(s) for UID ${uid}`);
    await deleteQuerySnapshot(aiJobsSnap, dryRun, "Firestore aiJob");

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      await recursiveDeleteDoc(userRef, dryRun);
    } else {
      console.log(`No users/${uid} document found.`);
    }

    if (lookupSnap.exists) {
      console.log(`${dryRun ? "[dry-run]" : "[delete]"} Firestore lookup: ${lookupRef.path}`);
      if (!dryRun) {
        await lookupRef.delete();
      }
    }

    if (!dryRun) {
      try {
        await auth.deleteUser(uid);
        console.log(`[delete] Firebase Auth user: ${uid}`);
      } catch (error) {
        if (error.code === "auth/user-not-found") {
          console.log(`Firebase Auth user already deleted: ${uid}`);
        } else {
          throw error;
        }
      }

      await deletionLogRef.set({
        status: "completed",
        completedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  } catch (error) {
    if (!dryRun) {
      await deletionLogRef.set({
        status: "failed",
        failedAt: FieldValue.serverTimestamp(),
        errorMessage: String(error && error.message ? error.message : error),
      }, { merge: true });
    }
    throw error;
  }

  console.log("");
  console.log(dryRun ? "Dry run complete. No data was deleted." : "Deletion complete.");
}

main().catch((error) => {
  console.error("");
  console.error("Account deletion failed:");
  console.error(error);
  process.exit(1);
});
