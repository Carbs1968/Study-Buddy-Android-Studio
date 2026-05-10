const fs = require("fs");
const os = require("os");
const path = require("path");

const OpenAI = require("openai");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { defineSecret } = require("firebase-functions/params");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

initializeApp();

const REGION = "us-central1";
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const TRANSCRIPT_TYPE = "transcript";
const SUPPORTED_OUTPUT_TYPES = new Set(["summary", "notes", "quiz"]);

const db = getFirestore();
const storage = getStorage();

function now() {
  return FieldValue.serverTimestamp();
}

function trimOrEmpty(value) {
  return typeof value === "string" ? value.trim() : "";
}

function resolveSessionId(job) {
  return trimOrEmpty(job.sessionId) || trimOrEmpty(job.recordingId);
}

function sessionDocumentPath(uid, sessionId) {
  return `users/${uid}/sessions/${sessionId}`;
}

function statusFieldForType(type) {
  return `${type}Status`;
}

function timestampMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return typeof value === "number" ? value : 0;
}

function latestAiJobSortValue(snapshot) {
  const job = snapshot.data() || {};
  return timestampMillis(job.completedAt) || timestampMillis(job.updatedAt);
}

function safeTmpAudioPath(jobId, audioStoragePath) {
  const audioFileName = path.basename(audioStoragePath) || "audio-file";
  const safeFileName = audioFileName.replace(/[^a-zA-Z0-9._-]/g, "_");
  return path.join(os.tmpdir(), `${jobId}-${Date.now()}-${safeFileName}`);
}

async function transcribeAudioFile(localAudioPath) {
  const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });
  const transcription = await openai.audio.transcriptions.create({
    file: fs.createReadStream(localAudioPath),
    model: "whisper-1",
  });

  return trimOrEmpty(transcription && transcription.text);
}

async function writeAiJobError(jobRef, errorCode, message, extra = {}) {
  await jobRef.set(
    {
      status: "error",
      errorCode,
      error: message,
      errorMessage: message,
      updatedAt: now(),
      ...extra,
    },
    { merge: true },
  );
}

async function writeSessionError(sessionRef, type, errorCode, message) {
  await sessionRef.set(
    {
      [statusFieldForType(type)]: "error",
      [`${type}ErrorCode`]: errorCode,
      [`${type}ErrorMessage`]: message,
      updatedAt: now(),
    },
    { merge: true },
  );
}

function buildDeterministicOutput(type, transcriptText) {
  switch (type) {
    case "summary":
      return {
        text: `Diagnostic summary stub for transcript: ${transcriptText}`,
      };
    case "notes":
      return {
        text: `Diagnostic notes stub for transcript: ${transcriptText}`,
        bullets: ["Diagnostic notes stub generated from the existing transcript."],
      };
    case "quiz":
      return {
        questions: [
          {
            question: "Diagnostic quiz stub: was transcript text available?",
            answer: "Yes.",
          },
        ],
      };
    default:
      return { text: `Diagnostic ${type} stub.` };
  }
}

exports.onAiJobCreated = onDocumentCreated(
  {
    document: "aiJobs/{jobId}",
    region: REGION,
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const job = snapshot.data() || {};
    const jobRef = snapshot.ref;
    const jobId = event.params.jobId;
    const uid = trimOrEmpty(job.uid);
    const type = trimOrEmpty(job.type);
    const sessionId = resolveSessionId(job);

    if (!uid) {
      await writeAiJobError(jobRef, "missing-uid", "AI job is missing required uid.");
      return;
    }

    if (!sessionId) {
      await writeAiJobError(
        jobRef,
        "missing-session-id",
        "AI job is missing required sessionId or recordingId.",
      );
      return;
    }

    if (type !== TRANSCRIPT_TYPE && !SUPPORTED_OUTPUT_TYPES.has(type)) {
      await writeAiJobError(
        jobRef,
        "unsupported-ai-job-type",
        `Unsupported AI job type '${type || "<empty>"}'.`,
      );
      return;
    }

    const sessionPath = sessionDocumentPath(uid, sessionId);
    const sessionRef = db.doc(sessionPath);
    const sessionSnapshot = await sessionRef.get();

    if (!sessionSnapshot.exists) {
      await writeAiJobError(
        jobRef,
        "session-not-found",
        `Session document not found at ${sessionPath}.`,
        { sessionPath },
      );
      return;
    }

    const session = sessionSnapshot.data() || {};

    if (type === TRANSCRIPT_TYPE) {
      const audioStoragePath = trimOrEmpty(session.audioStoragePath);

      if (!audioStoragePath) {
        const message =
          "Session is missing audioStoragePath; Firebase Storage audio cannot be checked.";
        await writeAiJobError(jobRef, "missing-audio-storage-path", message, {
          sessionPath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "missing-audio-storage-path",
          message,
        );
        return;
      }

      const [audioExists] = await storage.bucket().file(audioStoragePath).exists();

      if (!audioExists) {
        const message =
          `Audio file was not found in Firebase Storage at '${audioStoragePath}'.`;
        await writeAiJobError(jobRef, "audio-storage-object-not-found", message, {
          sessionPath,
          audioStoragePath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "audio-storage-object-not-found",
          message,
        );
        return;
      }

      const localAudioPath = safeTmpAudioPath(jobId, audioStoragePath);
      const startedAt = now();

      await jobRef.set(
        {
          status: "running",
          startedAt,
          updatedAt: startedAt,
        },
        { merge: true },
      );

      await sessionRef.set(
        {
          transcriptStatus: "processing",
          sessionStatus: "processing",
          updatedAt: startedAt,
        },
        { merge: true },
      );

      try {
        await storage.bucket().file(audioStoragePath).download({
          destination: localAudioPath,
        });

        const transcriptText = await transcribeAudioFile(localAudioPath);
        if (!transcriptText) {
          throw new Error("OpenAI returned an empty transcription response.");
        }

        const timestamp = now();

        await sessionRef.set(
          {
            transcriptStatus: "done",
            sessionStatus: "ready",
            transcriptText,
            transcriptUpdatedAt: timestamp,
            updatedAt: timestamp,
          },
          { merge: true },
        );

        await jobRef.set(
          {
            status: "done",
            output: { text: transcriptText },
            sessionPath,
            audioStoragePath,
            completedAt: timestamp,
            updatedAt: timestamp,
          },
          { merge: true },
        );
      } catch (error) {
        const errorMessage =
          error && error.message ? error.message : String(error);
        const message =
          `Audio download or OpenAI transcription failed for '${audioStoragePath}': ${errorMessage}`;
        await writeAiJobError(jobRef, "transcription-failed", message, {
          sessionPath,
          audioStoragePath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "transcription-failed",
          message,
        );
      } finally {
        try {
          if (fs.existsSync(localAudioPath)) {
            fs.unlinkSync(localAudioPath);
          }
        } catch (cleanupError) {
          console.warn(
            `Failed to clean up temporary audio file '${localAudioPath}'.`,
            cleanupError,
          );
        }
      }
      return;
    }

    const transcriptText = trimOrEmpty(session.transcriptText);
    if (session.transcriptStatus !== "done" || !transcriptText) {
      const message =
        `Cannot create ${type} stub because transcriptStatus is not done or transcriptText is empty.`;
      await writeAiJobError(jobRef, "transcript-not-ready", message, {
        sessionPath,
      });
      await writeSessionError(sessionRef, type, "transcript-not-ready", message);
      return;
    }

    const output = buildDeterministicOutput(type, transcriptText);
    const timestamp = now();

    await sessionRef.set(
      {
        [statusFieldForType(type)]: "done",
        [`${type}Output`]: output,
        updatedAt: timestamp,
      },
      { merge: true },
    );

    await jobRef.set(
      {
        status: "done",
        output,
        sessionPath,
        completedAt: timestamp,
        updatedAt: timestamp,
      },
      { merge: true },
    );

    console.log(`Completed diagnostic ${type} job ${jobId} for ${sessionPath}.`);
  },
);

exports.onTranscriptRequested = onDocumentUpdated(
  { document: "users/{uid}/sessions/{sessionId}", region: REGION },
  async (event) => {
    const afterSnapshot = event.data && event.data.after;
    if (!afterSnapshot) return;

    const session = afterSnapshot.data() || {};
    const transcribeRequested = session.transcribeRequested === true;
    const transcriptPending = session.transcriptStatus === "pending";
    const audioStoragePath = trimOrEmpty(session.audioStoragePath);

    if (transcribeRequested && transcriptPending && !audioStoragePath) {
      await afterSnapshot.ref.set(
        {
          transcriptStatus: "error",
          transcriptErrorCode: "missing-audio-storage-path",
          transcriptErrorMessage:
            "transcribeRequested is true but audioStoragePath is missing; no AI job was created.",
          updatedAt: now(),
        },
        { merge: true },
      );
    }
  },
);

exports.getTranscriptText = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const recordingId = trimOrEmpty(request.data && request.data.recordingId);
  if (!recordingId) {
    throw new HttpsError("invalid-argument", "recordingId is required.");
  }

  const sessionSnapshot = await db
    .doc(sessionDocumentPath(request.auth.uid, recordingId))
    .get();

  if (!sessionSnapshot.exists) {
    return { text: "" };
  }

  const session = sessionSnapshot.data() || {};
  return {
    text: typeof session.transcriptText === "string" ? session.transcriptText : "",
  };
});

exports.getAiJobOutput = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const requestedType = trimOrEmpty(request.data && request.data.type);
  const sessionId =
    trimOrEmpty(request.data && request.data.sessionId) ||
    trimOrEmpty(request.data && request.data.recordingId);

  if (!sessionId) {
    throw new HttpsError(
      "invalid-argument",
      "sessionId or recordingId is required.",
    );
  }

  if (!requestedType) {
    throw new HttpsError("invalid-argument", "type is required.");
  }

  const querySnapshot = await db
    .collection("aiJobs")
    .where("uid", "==", request.auth.uid)
    .where("sessionId", "==", sessionId)
    .where("type", "==", requestedType)
    .where("status", "==", "done")
    .get();

  if (querySnapshot.empty) {
    return {
      data: null,
      jobId: null,
      sessionId,
      type: requestedType,
    };
  }

  const [jobSnapshot] = querySnapshot.docs.sort(
    (left, right) => latestAiJobSortValue(right) - latestAiJobSortValue(left),
  );
  const job = jobSnapshot.data() || {};

  return {
    data: job.output || null,
    jobId: jobSnapshot.id,
    sessionId,
    type: requestedType,
  };
});
