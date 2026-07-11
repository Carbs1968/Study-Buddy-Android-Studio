# Study Buddy Account Deletion Process

Last updated: 2026-07-10

## Purpose

This document defines the v1 account deletion process for Study Buddy.

The app provides a Settings link to:

- https://studybuddynote.com/delete-account

Users may request account deletion from the website. The app should also support an authenticated in-app deletion flow before public Play Store launch if it can be implemented and tested safely.

## Verification model

### In-app deletion

If the user is signed in, Firebase Auth identifies the account by:

- `uid`
- Google sign-in email

For a destructive in-app delete flow, require recent Google reauthentication before deleting the Firebase Auth user and associated data.

### Website/manual deletion request

A website request alone is not enough verification because anyone can submit another person's email.

Manual request process:

1. User submits the Google email used for Study Buddy sign-in.
2. Normalize the email to lowercase.
3. Look up:
   - `userEmailLookup/{emailLower}`
4. If found, identify the UID.
5. Send a verification email to the same email address.
6. Require the user to reply with an explicit confirmation phrase, such as:
   - `DELETE STUDY BUDDY`
7. Only process deletion after confirmation from the same email address.

If no active account is found, reply that no active Study Buddy account was found for the submitted email. This may happen if the account was already deleted.

## User-owned Firestore data

Delete the following Firestore data for the confirmed UID:

- `users/{uid}`
  - includes nested subcollections such as:
    - `academicSettings`
    - `sessions`
    - `academicYears`
    - semesters
    - classes
    - class materials
    - class Study Guides
- `userEmailLookup/{emailLower}`
- top-level `aiJobs` documents where `uid == confirmed uid`

Known active paths from current code:

- `users/{uid}/academicSettings/current`
- `users/{uid}/sessions/{sessionId}`
- `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}`
- `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/materials/{materialId}`
- `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/studyGuides/{guideId}`
- `aiJobs/{jobId}` where `uid == confirmed uid`
- `userEmailLookup/{emailLower}`

## User-owned Firebase Storage data

Delete these Storage prefixes for the confirmed UID:

- `recordings/{uid}/`
- `classMaterials/{uid}/`
- `user_photos/{uid}/`

Known active Storage paths from current code:

- `recordings/{uid}/{fileName}`
- `classMaterials/{uid}/{academicYearId}/{semesterId}/{classId}/{materialId}/{fileName}`
- `user_photos/{uid}/{fileName}`

## Firebase Auth data

After Firestore and Storage cleanup, delete the Firebase Auth user for the confirmed UID.

For manual deletion, this should be done with trusted admin credentials, not client-side code.

## Already-deleted accounts

If a deletion request is received for an account that appears already deleted:

1. Check `userEmailLookup/{emailLower}`.
2. If no lookup exists, check any internal deletion request log.
3. If no active account or user data is found, respond:

> We could not find an active Study Buddy account associated with this email. If you previously deleted your account, no further action is required.

If a UID is still known from a prior lookup or deletion log, verify there is no remaining Firestore, Storage, or Auth data for that UID.

## Minimal internal deletion log

Maintain a minimal internal deletion log outside the user-owned app data.

Do not store study content, transcripts, recordings, materials, summaries, notes, quizzes, or Study Guides in the deletion log.

Suggested fields:

- `emailLower`
- `uid`, if known
- `requestedAt`
- `verifiedAt`
- `completedAt`
- `status`
  - `pending_verification`
  - `completed`
  - `no_account_found`
  - `rejected_unverified`
- `source`
  - `web`
  - `in_app`
- `notes`

## Manual deletion checklist

For each verified deletion request:

1. Normalize submitted email.
2. Look up `userEmailLookup/{emailLower}`.
3. Confirm UID.
4. Send verification email to submitted email.
5. Confirm reply from the same email.
6. Delete Storage:
   - `recordings/{uid}/`
   - `classMaterials/{uid}/`
   - `user_photos/{uid}/`
7. Delete top-level `aiJobs` where `uid == confirmed uid`.
8. Recursively delete `users/{uid}` and all subcollections.
9. Delete `userEmailLookup/{emailLower}`.
10. Delete Firebase Auth user for UID.
11. Record minimal deletion-log entry.
12. Reply to the user confirming deletion is complete.

## Planned in-app deletion flow

The in-app deletion flow should:

1. Require signed-in user.
2. Show a destructive confirmation screen.
3. Require recent Google reauthentication.
4. Call a trusted Cloud Function.
5. Cloud Function deletes:
   - Storage prefixes
   - `aiJobs` for UID
   - `users/{uid}` recursively
   - `userEmailLookup/{emailLower}`
   - Firebase Auth user
6. App signs out and returns to login.
7. User receives confirmation.

## Website page copy requirements

The public deletion page should clearly say:

- Users can request deletion of their Study Buddy account.
- They must submit the Google email used to sign in.
- Study Buddy will verify the request by sending a confirmation email to that address.
- Deletion includes account profile, recordings, uploaded materials, transcripts, summaries, notes, quizzes, and Study Guides.
- If no active account is found, Study Buddy will notify the requester.
- Some minimal records may be retained if required for legal, security, fraud-prevention, or compliance purposes.
