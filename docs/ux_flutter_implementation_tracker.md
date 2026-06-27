# Study Buddy UX Flutter Implementation Tracker

## Source of Truth

- Repository: `Carbs1968/Study-Buddy-Android-Studio`
- Branch: `dev`
- Real local working repo: `/Users/developerdave/Projects/Study-Buddy-Android-Studio`
- Source of truth: latest `origin/dev`
- Current Google Play app name: `Study Buddy Note`
- Google Drive upload/folder logic is not part of the current baseline.

## Required Academic Structure

`Academic Year → Semester → Class → Topic`

This structure must remain in the UX and Firestore metadata.

## Baseline Features That Must Not Regress

- Firebase Auth login/logout
- Firebase Storage upload
- Firestore metadata/session save
- User email lookup/troubleshooting support
- Academic settings loading
- Library/session loading
- Recording start/pause/resume/stop/timer
- Android foreground/locked-screen recording
- Wakelock while recording
- Local file cleanup after upload/discard
- AI transcript/summary/notes/quiz flow
- Responsive UI with no controls blocked by system bars
- No Google Drive logic reintroduced

## UX Implementation Approach

Figma is the approved UX direction, but the Flutter work is a safe native migration, not a pixel-perfect Figma conversion.

Current approach:

- Preserve existing app architecture.
- Make small targeted UI changes.
- Test each step on a physical Android phone.
- Avoid broad rewrites.
- Do not touch Firebase, Firestore, recorder, upload, or AI logic during visual-only work.

## Completed and Pushed UX Milestones

### Home Dashboard

Commits:
- `2e6e754 Add home dashboard tab`
- `64f758d Polish home dashboard layout`

Status:
- Home tab added.
- Dashboard visually polished.
- Record and Upload cards are visual only for now.
- No Firebase/Firestore/recording/upload/AI logic changed.

### Class Recordings

Commit:
- `9c0d7d4 Polish class recordings screen`

Status:
- Class recordings screen visually polished.
- Firestore stream, filtering, sorting, and lecture navigation preserved.

### Class Materials

Commit:
- `2fca26b Polish class materials screen`

Status:
- Materials empty/populated states visually polished.
- Upload, delete, preview, Firebase Storage, and Firestore save logic preserved.

### Library

Commit:
- `3eb0a62 Polish library screen`

Status:
- Library visually polished.
- Class grouping, stable IDs, and class navigation preserved.

### Settings

Commit:
- `5e06707 Polish settings screen`

Status:
- Settings visually polished.
- Logout, Google sign-out, Firestore locale save, and Academic Settings navigation preserved.

## Dark Mode Status

Status: resolved for current MVP.

Previous finding:
- Dark mode was not acceptable after the light-mode visual polish because several polished screens used hardcoded light colors.

Resolution:
- Fixed in commit `fc4d8d1 Fix dark mode contrast`.
- The app follows the Android device theme.
- If the device is set to light mode, Study Buddy uses light mode.
- If the device is set to dark mode, Study Buddy uses dark mode.
- Home, Library, Class Recordings, Class Materials, Settings, and bottom navigation were manually checked in dark mode.

Current rule:
- Do not treat dark mode as the next UX task unless new testing shows a specific screen-level regression.
- Continue using theme-aware colors for new UX work.
- Avoid introducing new hardcoded light-only colors during screen polish.
- Test newly polished screens in both light and dark device modes.

## Future Class / Term Study Guide Direction

Future feature:
`Generate Class Study Guide for a full academic term`

Input scope:
`Academic Year → Semester → Class`

Eventually include:
- Class-level lectures/recordings
- Transcripts from those lectures
- Class-level uploaded materials
- Topic-level lectures inside the class
- Topic-level uploaded materials inside the class

Possible outputs:
- Full class summary
- Study guide
- Key concepts
- Exam review
- Practice quiz/questions
- Topic-by-topic breakdown

Do not implement yet.

This requires planning:
- Firestore query scope
- Upload/material metadata
- Transcript readiness
- AI job batching
- Cloud Function contract
- Token/chunking strategy
- Output storage and status tracking

## Completed Analyzer Cleanup

Commit:
- `5add349 Clean up Flutter analyzer warnings`

Summary:
- Resolved the long-standing Flutter analyzer warnings.
- `flutter analyze` now reports no issues.
- Reapplied fixes without broad `dart format` churn so the final diff stayed small and reviewable.

Files changed:
- `lib/main.dart`
- `lib/screens/class_materials_screen.dart`
- `lib/screens/home_shell/pages/recorder_page.dart`
- `lib/screens/lecture_detail_screen.dart`
- `lib/utils/helper.dart`

Manual test results:
- `flutter analyze` passed with no issues.
- Physical Android smoke test passed.
- Changes were pushed to `origin/dev`.

Safety:
- No active recording behavior changed.
- No Firebase Storage upload flow changed.
- No Firestore metadata/session path changed.
- No AI job or Cloud Function contract changed.
- No academic structure changed.

## Runtime Warning Watchlist

### Firestore DNS / App Check Warning

Status: monitor only.

During one physical Android smoke test from a new office/network, logs showed:
- `Unable to resolve host firestore.googleapis.com`
- `Error getting App Check token. Too many attempts.`

Current interpretation:
- Likely caused by the new office network/DNS environment.
- Not treated as an app-code regression.
- Do not change Firebase/App Check configuration unless the warning repeats on normal trusted Wi-Fi or mobile data.

If repeated:
- Test on mobile data.
- Test on known-good Wi-Fi.
- Then inspect Firebase App Check configuration and app initialization.

## Preserved Recorder Stash

A recorder change was previously preserved separately.

Stash label:
`local recorder backend tracking before UX work`

File:
`lib/screens/home_shell/pages/recorder_page.dart`

Apparent purpose:
Tracks recording backend with something like:
`_RecordingBackend { none, nativeService, plugin }`

Decision:
- Do not mix into UX work.
- Handle later as a separate recorder-specific task.
- Requires physical Android recording QA.

## Higher-Risk Screens

Do not broadly patch these yet:

### Academic Settings

Risk: high

Reason:
- Controls Year → Semester → Class → Topic.
- Loads/saves Firestore academic settings.
- Handles add/edit/delete behavior.
- Impacts required academic metadata.

### Lecture Detail / AI Outputs

Risk: high

Reason:
- Handles transcript request.
- Creates AI jobs.
- Calls Cloud Functions.
- Loads transcript/summary/notes/quiz.
- Has async status/output behavior.

### Recorder

Risk: very high

Reason:
- Controls live recording.
- Android foreground service behavior.
- Locked-screen recording.
- Wakelock.
- File creation.
- Upload.
- Cleanup.
- Timer/start/pause/resume/stop states.

### Upload Flow / Destination Behavior

Risk: medium-high

Reason:
- Controls file picker/image picker.
- Firebase Storage upload.
- Firestore material document save.
- File type detection.
- Class/topic destination metadata.

## Current Safe Checkpoint

- Latest `dev` has been pushed to `origin/dev`.
- Low-risk light-mode visual polish is pushed.
- Dark mode fix was completed in `fc4d8d1 Fix dark mode contrast`.
- App follows the device theme and dark mode is acceptable for the current MVP.
- Flutter analyzer cleanup was completed in `5add349 Clean up Flutter analyzer warnings`.
- `flutter analyze` currently reports no issues.
- Physical Android smoke test passed after analyzer cleanup.
- Next action: continue UX implementation one screen at a time from a current `dev` source-of-truth check.

## Completed Dark Mode Fix

Commit:
- `fc4d8d1 Fix dark mode contrast`

Summary:
- Added a stronger dark theme foundation in `lib/main.dart`.
- Converted polished screens from hardcoded light colors to theme-aware colors.
- Fixed dark-mode bottom navigation visibility.
- Preserved the light-mode polished UX.

Files changed:
- `lib/main.dart`
- `lib/screens/home_shell/pages/dashboard_page.dart`
- `lib/screens/home_shell/pages/library_page.dart`
- `lib/screens/class_lectures_screen.dart`
- `lib/screens/class_materials_screen.dart`
- `lib/screens/home_shell/pages/settings_page.dart`

Manual test results:
- Home dark mode looks good.
- Library dark mode looks good.
- Class Recordings dark mode looks good.
- Class Materials dark mode looks good.
- Settings dark mode looks good.
- Bottom navigation is visible in dark mode.
- `flutter analyze` remained at the known existing 21 issues.
- No new analyzer issues were introduced.

Safety:
- No recorder files touched.
- No Firebase/Auth logic touched.
- No Firestore query/write logic intentionally changed.
- No upload/storage-path logic touched.
- No AI job or Cloud Function logic touched.

## Completed Topic Metadata Foundation

Commit:
- `e0c9e73 Add topic metadata for future study guides`

Summary:
- Added additive topic metadata to new recording session documents.
- Added class-scope metadata defaults to new class material documents.
- Preserved existing `topic` field for backward compatibility.
- Did not add topic-level upload UI yet.
- Did not change Firestore paths or Firebase Storage paths.

Recording session metadata added:
- `topicId`
- `topicName`

Class material metadata added:
- `materialScope: class`
- `topicId: null`
- `topicName: null`

Files changed:
- `lib/screens/home_shell/pages/recorder_page.dart`
- `lib/screens/class_materials_screen.dart`

Manual test results:
- App opened successfully.
- App functioned correctly after the metadata patch.
- `flutter analyze` remained at the known existing 21 issues.
- No new analyzer issues were introduced.

Safety:
- Existing recording field `topic` preserved.
- Existing `className` and `classId` fields preserved.
- No recorder start/pause/resume/stop/timer logic changed.
- No upload destination behavior changed.
- No Firestore path changed.
- No Firebase Storage path changed.
- No UI changed.
- No AI job or Cloud Function logic touched.

Future use:
- Supports future topic-level organization.
- Supports future Topic Study Guide planning.
- Supports future Class / Term Study Guide aggregation.
- Provides a metadata distinction between class-level and future topic-level materials.

## Corrected Topic Grouping Metadata

Commit:
- `1469c87 Add topic grouping metadata`

Summary:
- Corrected the topic metadata approach after Firebase testing.
- New recording sessions now save a normalized `topicKey` instead of a premature `topicId`.
- `topicId` is reserved for future real Topic documents under the class hierarchy.
- Existing session field `topic` remains preserved for backward compatibility.
- `topicName` is added as the readable display name.

Final session metadata model for new recordings:
- `topic`
- `topicName`
- `topicKey`

Final class material metadata model for new class-level materials:
- `materialScope: class`
- `topicId: null`
- `topicName: null`

Reasoning:
- A Firebase-generated `topicId` should only be used once real topic documents exist.
- Generating a random topic ID per recording would make grouping lectures by topic unreliable.
- `topicKey` is a temporary normalized grouping key based on the topic text.
- Future topic documents can later provide true stable IDs.

Firebase verification:
- A new test recording was created and uploaded.
- The newest session document showed:
  - `topic`
  - `topicName`
  - `topicKey`
- No premature `topicId` was saved on the session.

Safety:
- No UI changes.
- No Firestore path changes.
- No Firebase Storage path changes.
- No recorder controls/timer behavior changed.
- No upload destination behavior changed.
- `flutter analyze` remained at the known existing 21 issues.

## Class Management and Library Source-of-Truth Decision

Decision:
- Keep Academic Settings focused on academic year / semester defaults.
- Do not turn Settings into a full class/topic manager right now.
- Library should become the future class management surface.
- Class Detail remains the place for recordings, materials, and later topics/study guides.

Current Library behavior:
- Reads `users/{uid}/sessions`.
- Groups sessions by class metadata.
- Shows classes discovered from recordings.

Why this is acceptable now:
- It preserves existing behavior.
- It keeps legacy sessions visible.
- It avoids a risky Library rewrite during the current UX/data-model pass.

Why this is not ideal at scale:
- It requires reading many session documents just to discover classes.
- It may become slower and more expensive as recordings grow.
- Classes with no recordings may not appear.
- Classes with only uploaded materials may not appear.
- It is not the best foundation for topic-level organization.

Future scalable model:
- Library should primarily read class documents from:
  `users/{uid}/academicYears/{yearId}/semesters/{semesterId}/classes/{classId}`

Future class document fields may include:
- `classId`
- `className`
- `academicYearId`
- `semesterId`
- `recordingCount`
- `materialCount`
- `topicCount`
- `lastActivityAt`
- `updatedAt`

Safe migration path:
1. Keep current session-derived Library behavior.
2. Add class documents as the primary Library source later.
3. Merge class docs with session-derived class rollups.
4. De-duplicate by `academicYearId + semesterId + classId`.
5. Keep session-derived fallback for legacy records.
6. Later add counters/lastActivity fields to class docs.

Do not implement this migration until reviewed separately.

## Completed Class Activity Timestamp Foundation

Commit:
- `27b8720 Track class activity timestamps`

Summary:
- Added class-level activity timestamps to support future scalable Library behavior.
- Recording uploads now update the parent class document with `lastActivityAt`, `lastRecordingAt`, and `updatedAt`.
- Material uploads now update the parent class document with `lastActivityAt`, `lastMaterialAt`, and `updatedAt` after the material document is saved.
- No counters were added yet to avoid inflated counts from retries or duplicate writes.

Files changed:
- `lib/screens/home_shell/pages/recorder_page.dart`
- `lib/screens/class_materials_screen.dart`

Future use:
- Enables future Library sorting by recent class activity.
- Helps prepare class documents to become the scalable Library source of truth.
- Supports the future hybrid migration where class docs are primary and session-derived class rollups remain a legacy fallback.

Safety:
- No Library query changed.
- No UI changed.
- No Firebase Storage path changed.
- No upload destination behavior changed.
- No recorder controls/timer behavior changed.
- No counters added.
- App smoke test passed.
- `flutter analyze` remained at the known existing issue baseline.

## Completed Class Display Metadata Foundation

Commit:
- `91b51a2 Add class document display metadata`

Summary:
- Added overwrite-safe class document display metadata to support the future scalable Library migration.
- Recording uploads now update the parent class document with `latestSessionId`, `latestTopicName`, and `hasRecordings`.
- Material uploads now update the parent class document with `hasMaterials`.

Files changed:
- `lib/screens/home_shell/pages/recorder_page.dart`
- `lib/screens/class_materials_screen.dart`

Future use:
- Helps class documents become more useful Library row sources later.
- Allows future UI to know whether a class has recordings or uploaded materials without relying on unsafe counters.
- Preserves `topicId` for future real topic documents only.

Safety:
- No Library query changed.
- No UI changed.
- No counters added.
- No `topicId` added.
- No Firebase Storage path changed.
- No session document shape changed.
- `flutter analyze` remained at the known existing issue baseline.

## Future Library Class-Doc Migration Plan

Status:
- Planning only. No Library query change has been made yet.

Current Library behavior:
- `library_page.dart` still reads `users/{uid}/sessions`.
- Sessions are grouped client-side into class rows.
- Lecture counts are derived from actual session documents.
- Legacy sessions without stable academic IDs still use slug-derived fallback IDs.
- `ClassLecturesScreen` remains session-backed.

Current class document foundation:
- Class docs now contain safe activity/display metadata:
  - `lastActivityAt`
  - `lastRecordingAt`
  - `lastMaterialAt`
  - `updatedAt`
  - `latestSessionId`
  - `latestTopicName`
  - `hasRecordings`
  - `hasMaterials`

Migration direction:
- Do not switch the Library to class-doc primary yet.
- Keep session-derived Library behavior until class-doc reads are verified.
- Future migration should preserve session-derived fallback for legacy users.
- Avoid `lectureCount` or `materialCount` counters until there is a safe server-side/backfill strategy.
- Avoid `topicId` until real topic documents exist.

Future implementation notes:
- A future class-doc loader may query nested class documents, likely with a `collectionGroup("classes")` query filtered by `userId`.
- Collection-group rules and index requirements must be tested before shipping.
- The first implementation should avoid visible UI behavior changes unless deliberately approved.
- Material-only classes may appear in class docs, so Library empty-state and row labels must be reconsidered before changing the rendered source.

Safety:
- No current Library query change.
- No UI change.
- No recorder/upload/Storage/session/AI behavior change.
- No counters.
- No `topicId`.

## Future Class Study Guide v1 Architecture Plan

Status:
- Planning only. No class-level AI code has been added yet.

Current AI behavior:
- Existing AI jobs are session-based.
- `onAiJobCreated` currently watches `aiJobs/{jobId}`.
- Existing jobs require `uid` plus `sessionId` or `recordingId`.
- Existing supported job types are `transcript`, `summary`, `notes`, and `quiz`.
- Existing `getAiJobOutput` retrieval is session-based.
- Firestore rules currently allow client-created `/aiJobs` only for `transcript`, `summary`, `notes`, and `quiz`, and require `recordingId`.

Class Study Guide v1 scope:
- Recordings only.
- Same class only.
- Include sessions where:
  - `userId` matches the authenticated user.
  - `academicYearId` matches the class.
  - `semesterId` matches the class.
  - `classId` matches the class.
  - `transcriptStatus == "done"`.
  - `transcriptText` exists and is non-empty.
- Ignore uploaded materials for v1.
- Ignore topic-level study guides for v1.
- Do not change existing per-session transcript, summary, notes, or quiz behavior.
- Do not change Library query behavior.

Recommended architecture:
- Flutter should not directly create a `classStudyGuide` `/aiJobs` document.
- Add a backend callable function such as `requestClassStudyGuide`.
- The callable should validate auth, class ownership, class IDs, and eligible sessions.
- The backend should create the `/aiJobs/{jobId}` processing document.
- Extend the AI worker to support `type: "classStudyGuide"` without requiring a session ID.
- Generate the guide from eligible completed transcript text.

Recommended output location:
- Durable result should be saved under the class document:
  `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/studyGuides/{guideId}`

Recommended class doc status fields:
- `classStudyGuideStatus`
- `latestStudyGuideId`
- `classStudyGuideUpdatedAt`
- `classStudyGuideErrorCode`
- `classStudyGuideErrorMessage`

Likely future files touched:
- `functions/src/index.js`
- `firestore.rules`
- `lib/screens/class_lectures_screen.dart`
- possibly a new Flutter class study guide detail/view screen

Safety:
- No recorder/upload/Firebase Storage/session save behavior should change.
- No material extraction should be added in v1.
- No topic-level guide generation should be added in v1.
- No counters should be added.
- No `topicId` should be added until real topic documents exist.
- No Google Drive logic.

## Completed Class Study Guide Validation Callable

Commit:
- `944cbe2 Add class study guide validation callable`

Summary:
- Added backend callable `requestClassStudyGuide` as the first backend-only slice for Class Study Guide v1.
- This callable validates the authenticated user, class path, and eligible completed transcripts.
- It returns an eligible transcript/session count but does not create an AI job yet.

Behavior:
- Requires Firebase Auth.
- Accepts `academicYearId`, `semesterId`, and `classId`.
- Confirms the class document exists at:
  `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}`
- Queries `users/{uid}/sessions` for matching class sessions where `transcriptStatus == "done"`.
- Counts only sessions with non-empty `transcriptText`.
- Returns `ok`, `eligibleSessionCount`, `className`, `academicYearId`, `semesterId`, and `classId`.

Safety:
- Backend-only validation/count slice.
- No `/aiJobs` document is created yet.
- No OpenAI call is made.
- Existing `onAiJobCreated` behavior is unchanged.
- Existing transcript, summary, notes, and quiz jobs are unchanged.
- No Flutter UI change.
- No Firestore rules change.
- No Firestore index change.
- `node --check functions/src/index.js` passed.
- `npm run lint` was unavailable because no lint script exists; no package/tooling changes were made.

Next future slice:
- Add a small Flutter/internal test call or backend emulator/callable test to verify the callable returns the expected eligible count for a real class.
- After validation is proven, a later slice can create a backend-owned `classStudyGuide` AI job.

## Completed requestClassStudyGuide Deployment Smoke Test

Commit deployed:
- `944cbe2 Add class study guide validation callable`

Deployment:
- Deployed only `functions:requestClassStudyGuide` to Firebase project `study-buddy-dev-25a7a`.
- Function was created successfully in `us-central1`.

Smoke test result:
- Direct HTTPS `curl` request reached the deployed callable.
- Callable returned the expected unauthenticated response:
  `UNAUTHENTICATED: Authentication is required.`
- This confirms the callable is live and the auth guard is working.

Notes:
- `firebase functions:shell` loaded the callable, but the shell call format produced `Request body is missing data` for the v2 callable.
- The Firebase CLI warned that `firebase-functions` can be upgraded, but deployment succeeded.
- No dependency/tooling upgrades were made.
- No app code changed during this deployment/test.

Next future slice:
- Add a temporary authenticated Flutter/internal test call or another safe authenticated test path to confirm the callable returns `eligibleSessionCount` for a real class.

## Completed Authenticated Class Study Guide Callable Test

Status:
- Temporary Flutter test UI was added, tested, and removed.
- No temporary test code remains in the app.

Test summary:
- Added a temporary internal science-icon button on `ClassLecturesScreen`.
- The button called the deployed `requestClassStudyGuide` callable as the logged-in Firebase user.
- Tested against class:
  `prepa → 4to-semestre → June 13th`
- Callable returned successfully with:
  `eligibleSessionCount: 4`
- The count matched the expected number of completed transcript sessions for that class.

Validated path:
- Flutter authenticated user
- Cloud Functions callable: `requestClassStudyGuide`
- Class document validation
- Session query for matching class transcripts
- Completed/non-empty transcript count returned to app

Cleanup:
- Temporary Cloud Functions import was removed from `class_lectures_screen.dart`.
- Temporary helper method was removed.
- Temporary science-icon button was removed.
- `flutter analyze` returned to the known existing issue baseline: 21 issues.
- `git diff` confirmed no app code changes remained after cleanup.

Safety:
- No real Flutter UI change was committed.
- No `/aiJobs` document was created.
- No OpenAI call was made.
- Existing transcript, summary, notes, and quiz behavior remained unchanged.
- Recorder, upload, Storage, Library, and session save behavior were not changed.

Next future slice:
- Backend can now safely move from validation/count-only to creating a backend-owned `classStudyGuide` job in a later step.

## Completed Class Study Guide Request Idempotency Test

Commit:
- `7dde7fe Prevent duplicate class study guide requests`

Deployment:
- Deployed only `functions:requestClassStudyGuide` after adding transaction-backed idempotency.

Test result:
- Temporary Flutter science-icon test UI was added and removed after testing.
- First authenticated tap created a new class study guide request.
- Repeated taps returned the same `requestId` with `reused: true`.
- Verified request reuse for unchanged recording content.
- Verified no duplicate request documents were created for repeated taps.
- `flutter analyze` returned to the known existing issue baseline: 21 issues.
- Temporary Flutter test code was removed and `class_lectures_screen.dart` was restored cleanly.

Request collection rationale:
- `classStudyGuideRequests/{requestId}` is a backend request/history collection.
- It is separate from `/aiJobs` because the current `/aiJobs` worker is session-based and expects `sessionId` or `recordingId`.
- It is separate from final user-facing study guide output.
- Future generated class study guides should be saved under the class document, likely:
  `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/studyGuides/{guideId}`
- The class document remains the fast UI/status pointer via fields such as `classStudyGuideStatus`, `latestStudyGuideRequestId`, `classStudyGuideUpdatedAt`, and `classStudyGuideContentSnapshot`.

Scalability and cost control:
- The class doc acts as the idempotency lock and current state pointer.
- Request docs preserve backend history/debuggability.
- Repeated requests for unchanged recording content reuse the existing request.
- A new request is allowed when recording content changes.
- `lastMaterialAt` is preserved in `classStudyGuideContentSnapshot` for future uploaded-material support.
- For v1, only `lastRecordingAt` controls regeneration because materials are not included in Class Study Guide v1 yet.

Safety:
- No `/aiJobs` document is created yet.
- No OpenAI call is made yet.
- Existing transcript, summary, notes, and quiz jobs remain untouched.
- No Flutter UI change remains.
- No Firestore rules or index changes were made.
- No Google Drive logic.

---

## Completed Class Study Guide Request Action and Backend Generation Test

Date: 2026-06-13

### Summary

Completed and tested the first end-to-end Class Study Guide request flow.

This slice added a permanent class-level Study Guide action in the Flutter UI and connected it to the deployed backend class guide generation flow.

### Source-of-truth checkpoint

- Branch: `dev`
- Latest pushed commit after this slice:
  - `611307a Add class study guide request action`
- Prior backend generation commit:
  - `68f792b Generate class study guides from request records`
- Working tree after push: clean
- GitHub `origin/dev`: current with local `dev`

### Flutter UI change

File changed:

- `lib/screens/class_lectures_screen.dart`

Added:

- Permanent AppBar action:
  - tooltip: `Generate class study guide`
  - icon: `Icons.auto_awesome_outlined`
- Calls callable:
  - `requestClassStudyGuide`
- Sends:
  - `academicYearId`
  - `semesterId`
  - `classId`
- Shows SnackBars for:
  - requesting
  - already requested/reused
  - errors

Existing Materials button was preserved.

### Backend changes

File changed:

- `functions/src/index.js`

Completed behavior:

- `requestClassStudyGuide` creates or reuses class study guide request records.
- Completed `done` requests are now reused when recording content has not changed.
- Reused `validated` requests are kicked with:
  - `generationKickAt`
  - `updatedAt`
- Class guide generation uses the write-based trigger:
  - `onClassStudyGuideRequestWritten`
- Old created-only trigger was deleted from Firebase:
  - `onClassStudyGuideRequestCreated`
- Backend controls source summary counts for future generated guides:
  - `output.sourceSummary.sessionCount`
  - `output.sourceSummary.includedSessionCount`
  - `output.sourceSummary.omittedSessionCount`

### Firebase test results

Tested on physical Samsung device.

Class tested:

- Academic year: `prepa`
- Semester: `4to-semestre`
- Class: `june-13th`
- Class name: `June 13th`

Request tested:

- Existing request:
  - `classStudyGuideRequests/JEblK7A5fvcTH58qRQga`
- Existing reused request was kicked successfully:
  - `generationKickAt`
  - `startedAt`
  - `completedAt`
  - `status: done`
- Generated guide:
  - `studyGuides/lfCdW5dEWfX3xQ5jXU9R`

A later duplicate-generation bug was found because completed `done` requests were not included in the reusable status list. This caused an extra guide to be generated:

- Extra request:
  - `7rLEePC5CqhnsS5wuHaf`
- Extra guide:
  - `426lAYxqhvJ6pPH3MStS`

Fix applied:

- Added `"done"` to reusable request statuses.
- Deleted the old created-only deployed function.
- Retested the Study Guide button.
- Confirmed no new request or guide was created after the final tap.

Final expected behavior confirmed:

- Existing completed guide is reused when recording content has not changed.
- No duplicate generation occurs on repeated taps.
- New generation should only occur after relevant recording content changes.

### Manual Firestore cleanup

The extra test guide generated before the backend-controlled count fix had:

- `includedSessionCount: 4`
- `sourceSessions`: 4 items
- `output.sourceSummary.sessionCount`: originally `5`

Manually corrected test guide:

- `studyGuides/426lAYxqhvJ6pPH3MStS`
- Set:
  - `output.sourceSummary.sessionCount: 4`

Top-level fields already matched:

- `includedSessionCount: 4`
- `omittedSessionCount: 0`
- `sourceSessions`: 4 items

Future generated guides should receive backend-controlled source summary counts automatically.

### Validation

Commands/checks completed:

- `node --check functions/src/index.js`
- `git diff --check -- functions/src/index.js`
- `flutter analyze`
  - stayed at known baseline: 21 issues
- `firebase deploy --only functions:requestClassStudyGuide,functions:onClassStudyGuideRequestWritten`
- `firebase functions:delete onClassStudyGuideRequestCreated --region us-central1`
- Physical Samsung test

### Safety statement

Touched:

- Class Study Guide callable/trigger flow
- Class screen AppBar action

Did not touch:

- Recording flow
- Upload flow
- Firebase Storage upload
- Firestore session save
- Existing `/aiJobs` flow
- Existing transcript/summary/notes/quiz generation
- Library loading
- Academic settings loading
- Google Drive logic
- Firestore rules
- Firestore indexes

Existing session AI pipeline remains separate from class guide generation.

### Remaining future work

- Add UI to view the generated Class Study Guide in-app.
- Add readable status display for:
  - running
  - done
  - error
- Add Firestore rules for reading `studyGuides` from Flutter when the viewer UI is built.
- Later support uploaded materials in class-level guides.
- Later support topic-level study guides.



---

## Completed Class Study Guide Viewer

Date: 2026-06-13

### Summary

Completed and tested the first read-only in-app viewer for generated Class Study Guides.

The class Study Guide action now checks the parent class document first:

- If `classStudyGuideStatus == "done"` and `latestStudyGuideId` exists, it opens the viewer.
- If no completed guide exists yet, it falls back to requesting/generating a guide through `requestClassStudyGuide`.

### Source-of-truth checkpoint

- Branch: `dev`
- Latest pushed commit after this slice:
  - `ba41791 Add class study guide viewer`
- Firestore rules read-access commit:
  - `e32d08d Allow users to read class study guides`
- Working tree after push: clean
- GitHub `origin/dev`: current with local `dev`

### Flutter files changed

Changed:

- `lib/screens/class_lectures_screen.dart`

Added:

- `lib/screens/class_study_guide_screen.dart`

### Viewer behavior

Added `ClassStudyGuideScreen`, a read-only viewer for generated guides stored at:

`users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/studyGuides/{guideId}`

The screen reads the guide document and displays:

- title
- overview
- key topics
- study sections
- review questions

It handles:

- not signed in
- loading state
- read error
- missing guide document

### Class screen behavior

The class Study Guide AppBar action now:

1. Reads the parent class document.
2. Checks `classStudyGuideStatus` and `latestStudyGuideId`.
3. If the guide is ready, opens `ClassStudyGuideScreen`.
4. Otherwise, calls `requestClassStudyGuide` as before.

Existing Materials button remains unchanged.

### Firebase/security dependency

This viewer depends on the previously deployed Firestore rule that allows owner read/list access for class `studyGuides`.

Client users can read/list their own generated guides.

Client users cannot create, update, or delete guide docs.

Backend Admin SDK remains responsible for writing generated guide documents.

### Manual test results

Tested on physical Samsung device.

Result:

- App opened successfully.
- Class Study Guide button opened the generated guide.
- The generated content displayed in-app.
- Content was readable and useful for the recordings available.
- No permission-denied error occurred.
- No new duplicate study guide was generated during this viewer test.
- `flutter analyze` stayed at the known baseline: 21 issues.

### Safety statement

Touched:

- Class screen navigation/action behavior
- New read-only Class Study Guide viewer screen

Did not touch:

- Recording flow
- Upload flow
- Firebase Storage upload
- Firestore session save
- Class guide backend generation
- Existing `/aiJobs` flow
- Existing transcript/summary/notes/quiz generation
- Library loading
- Academic settings loading
- Google Drive logic
- Firestore rules in this viewer commit

### Current status

Class Study Guide v1 now supports:

- request from class screen
- backend generation from completed transcripts
- duplicate-generation prevention
- read-only in-app viewing

### Remaining future work

- Improve the viewer UI toward the Figma design system.
- Add clearer status UI for generating/error states.
- Add copy/export/share actions.
- Add refresh/regenerate behavior when recording content changes.
- Add topic-level guide viewer later.
- Add uploaded materials into class guide generation later.
