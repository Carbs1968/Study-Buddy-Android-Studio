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

## Completed Home Dashboard Functionality

### Home Dashboard Actions

Commit:
- `ec52b61 Wire home dashboard actions`

Summary:
- Home Record card now opens the existing Record tab.
- Home Upload Study Material card no longer acts like a dead button.
- Upload Study Material now shows guidance that users should open a class or topic before uploading material.
- Removed the always-highlighted Record card styling so the Home quick actions do not look like a selected/active recording state.

Manual test results:
- Record card opens the Record screen.
- Upload Study Material card shows the class/topic guidance message.
- Bottom navigation still works.
- `flutter analyze` passed with no issues.

Safety:
- No recorder internals changed.
- No upload flow changed.
- No Firebase Storage write path changed.
- No Firestore metadata/session path changed.
- No AI job or Cloud Function contract changed.

### Recent Classes on Home

Commit:
- `f475826 Show recent classes on home dashboard`

Summary:
- Replaced the static Home placeholder with an activity-based Recent Classes section.
- Recent Classes reads from `users/{uid}/sessions`.
- Classes are grouped by stable academic context when available:
  - `academicYearId`
  - `semesterId`
  - `classId`
- Legacy session data is still supported with generated stable IDs from class/year/semester names.
- Recent Classes is sorted by latest activity first, with session count as the fallback relevance signal.
- Home shows up to five recent classes.
- Tapping a recent class opens `ClassLecturesScreen`.

Product decision:
- Home is not the full official class directory.
- Home is a launchpad for recent/relevant activity.
- The official academic structure remains:
  - Academic Year → Semester → Class → Topic
- Recorder class-selection logic remains separate for now because Recorder was built early and still contains legacy-compatible class logic.
- Do not copy Recorder’s session-derived class dropdown logic into new academic source-of-truth screens.

Manual test results:
- Recent Classes appears on Home.
- Tapping a recent class opens the correct `ClassLecturesScreen`.
- Record card still opens the Record tab.
- Upload Study Material card still shows class/topic guidance.
- Bottom navigation still works.
- `flutter analyze` passed with no issues.
- Physical Android phone test passed.

Safety:
- Read-only Home dashboard change.
- No recording behavior changed.
- No upload behavior changed.
- No Firebase Storage behavior changed.
- No Firestore write paths changed.
- No AI job or Cloud Function contract changed.
- No academic hierarchy migration was performed.

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

## Recorder UX Review Notes

Source:
- Figma AI recorder UX review after Home dashboard functionality work.

Key review findings:
- The recorder UX direction is strong overall.
- Status badges, reassurance copy, filename preview, upload checklist, and warning copy should be preserved.
- The Figma/prototype review identified several recorder UX priorities:
  - paused state clarity
  - discard safety
  - pause/resume/stop hierarchy
  - academic context clarity
  - upload/retry/error-state clarity
  - small Android phone and SafeArea testing

Important Flutter reality:
- The current Flutter recorder already has working production-sensitive behavior:
  - class selection
  - topic entry
  - start / pause / resume / stop
  - timer
  - wakelock while recording
  - Android foreground / locked-screen recording behavior
  - recording continuity across tab navigation
  - recording continuity when returning to the Record tab
  - local temporary audio file
  - Firebase Storage upload
  - Firestore session metadata save
  - local cleanup after upload/discard
  - file naming format: `ClassName - Topic - yyyy-mm-dd_hh-mm.m4a`

Product decision:
- Do not hide or disable the bottom navigation during active recording solely because the Figma review suggested it.
- In the current Flutter app, bottom navigation during recording is intentional and has been tested.
- Users can navigate away from Record and return to the active recording state.
- This behavior supports the app’s recording-resilience goal and should be preserved unless a specific regression appears.

Future UX improvement:
- If users need more reassurance while navigating away from Record, add a persistent recording-status indicator instead of disabling navigation.
- Preferred future pattern:
  - a mini recording banner above the bottom nav
  - example: `Recording Biology • 00:18:42`
  - tap banner to return to Recorder
- This should be a separate, deliberate patch because it requires sharing recorder state with `HomeShell`.

Recorder implementation guidance:
- Do not rewrite `recorder_page.dart` from Figma in one pass.
- Use the Figma review as a priority guide, not as a direct replacement spec.
- Make recorder changes in small, isolated patches.
- Preserve all recording, upload, Firestore, Firebase Storage, wakelock, foreground service, local cleanup, and filename behavior.

Recommended recorder patch order:
1. Audit current Flutter recorder states against Figma states.
2. Improve paused-state clarity if current UI is unclear.
3. Improve discard safety and confirmation.
4. Improve pause/resume/stop visual hierarchy.
5. Improve academic context display.
6. Improve upload/retry/error-state messaging.
7. Consider persistent recording banner across tabs only after recorder state-sharing design is reviewed.

Safety rule:
- Do not combine recorder UI polish with academic hierarchy migration.
- Do not combine recorder UI polish with upload logic changes.
- Do not combine recorder UI polish with Firestore/session schema changes.
- Do not change bottom navigation behavior during recording without explicit review and physical Android testing.

## Completed Recorder UX Pass 1

Commit:
- `62886d9 Clarify recorder status messages`

Summary:
- Updated recorder helper/status copy during live recording and paused states.
- Recording state now reassures the student that recording continues if the screen locks.
- Paused state now tells the student that the recording is still saved and can be resumed.
- Removed unnecessary extra instruction text after user review.

Final live recording helper:
- `Recording continues if your screen locks.`

Paused helper:
- `Recording paused. Tap Resume to continue. Your recording is still saved.`

Manual Android test results:
- Recording started successfully through the Android foreground service.
- Foreground service start was verified.
- Pause worked.
- Resume worked.
- Pause/resume worked repeatedly.
- Stop worked.
- Discard removed the local recording file.
- No recorder crash observed.

Safety:
- Copy-only recorder UX change.
- No recording engine behavior changed.
- No pause/resume logic changed.
- No stop logic changed.
- No upload logic changed.
- No Firebase Storage path changed.
- No Firestore session metadata changed.
- No local cleanup behavior changed.
- No filename format changed.
- No bottom navigation behavior changed.
- No academic/class selection logic changed.

Recorder UX status:
- This was a deliberately small first recorder patch.
- Continue recorder work slowly and one issue at a time.
- Next likely recorder UX candidates:
  - paused-state visual clarity
  - pause/resume/stop hierarchy
  - post-recording upload/retry messaging
  - academic context display clarity
  - future optional recording-status banner across tabs

## Completed Material Text Extraction Pass 1B — Deployment Fixes and Validation

Commits:
- `881d483 Fix material extraction FieldValue usage`
- `91092b2 Fix material extraction storage download`

Deployment:
- Deployed Firebase Function:
  - `onMaterialExtractionRequested`
- Firebase confirmed active function:
  - v2
  - `google.cloud.firestore.document.v1.written`
  - `us-central1`
  - `nodejs22`

Problems found during deployment/testing:
- First deployed trigger fired but crashed because the new code referenced:
  - `admin.firestore.FieldValue`
- The project already imports and uses:
  - `FieldValue`
- After fixing FieldValue usage, TXT extraction still failed because the new code referenced:
  - `admin.storage().bucket()`
- The project already initializes Firebase Storage with:
  - `getStorage()`
  - `storage.bucket()`

Fixes:
- Replaced invalid FieldValue references:
  - `admin.firestore.FieldValue.serverTimestamp()`
  - became `FieldValue.serverTimestamp()`
  - `admin.firestore.FieldValue.delete()`
  - became `FieldValue.delete()`
- Replaced invalid Storage download reference:
  - `admin.storage().bucket().file(storagePath).download()`
  - became `storage.bucket().file(storagePath).download()`

Validation results:
- TXT upload:
  - extraction completed successfully
  - `extractionStatus: done`
  - `extractedText` present
  - `extractedTextCharCount` populated
  - `extractionSource: storage`
- CSV upload:
  - extraction completed successfully
  - `extractionStatus: done`
  - `extractedText` present
  - `extractedTextCharCount` populated
  - `extractionSource: storage`
- XLSX upload:
  - correctly marked unsupported
  - `extractionStatus: unsupported`
  - `extractedTextCharCount: 0`
- PPTX upload:
  - correctly marked unsupported
  - `extractionStatus: unsupported`
  - `extractedTextCharCount: 0`

Result:
- Material Text Extraction v1 is deployed and validated end-to-end.
- TXT and CSV materials can now produce extracted text.
- XLSX and PPTX are safely marked unsupported in this first pass.
- Study Guide generation has not been changed yet.
- Flutter UI has not been changed for this extraction pass.

Safety:
- These were backend-only fixes to the new extraction trigger.
- They did not change material upload behavior.
- They did not change Firebase Storage upload paths.
- They did not change Firestore rules.
- They did not change Firestore collection names.
- They did not change Study Guide generation.
- They did not change AI job creation.
- They did not change transcript generation.
- They did not change recording behavior.
- They did not change auth/login/logout behavior.
- They did not change navigation.
- They did not change academic structure requirements.

Current extraction behavior:
- TXT / CSV:
  - `not_started` → `processing` → `done`
  - stores `extractedText`
  - stores `extractedTextCharCount`
  - stores `extractionSource: storage`
- Unsupported files:
  - `not_started` → `processing` → `unsupported`
  - stores `extractedTextCharCount: 0`
- Failed extraction:
  - `not_started` → `processing` → `error`
  - stores student-safe/admin-safe `extractionError`

Near-term follow-up:
- Update class Study Guide generation to include extracted material text.
- Only include material docs where:
  - `extractionStatus: done`
  - `extractedText` is non-empty
- Keep completed transcripts as the primary source of truth.
- Use uploaded materials as supplemental context only when relevant.
- Ignore or down-rank unrelated, duplicate, sparse, corrupted, or conflicting uploads.
- Do not infer facts from filenames alone.
- Update Study Guide UI copy only after materials are truly included in generation.

## Completed Material Text Extraction Pass 1 — TXT and CSV Extraction Trigger

Commit:
- `b632f89 Add material text extraction trigger`

Problem:
- Uploaded class materials were saved with metadata only.
- Material documents included:
  - `storagePath`
  - `downloadUrl`
  - `materialType`
  - `mimeType`
  - `sizeBytes`
  - `extractionStatus: not_started`
- No extracted material text was being saved.
- Because of that, class Study Guide generation could not safely include uploaded materials yet.
- Study Guide generation currently remains transcript/recording-only.

Change:
- Updated `functions/src/index.js`.
- Added Material Text Extraction v1 Cloud Function:
  - `onMaterialExtractionRequested`
- Added constants:
  - `MATERIAL_TEXT_CHAR_LIMIT`
  - `MATERIAL_EXTRACTION_DOC`
- Added helper logic to identify text-extractable materials.
- Added helper logic to normalize extracted text.

Extraction behavior:
- Watches material docs at:
  - `users/{uid}/academicYears/{academicYearId}/semesters/{semesterId}/classes/{classId}/materials/{materialId}`
- Processes only docs with:
  - `extractionStatus: not_started`
- Claims work safely with a transaction:
  - `not_started` → `processing`
- TXT and CSV files:
  - downloads from Firebase Storage using `storagePath`
  - normalizes text
  - stores `extractedText`
  - stores `extractedTextCharCount`
  - sets `extractionSource: storage`
  - sets `extractionStatus: done`
- Unsupported files:
  - sets `extractionStatus: unsupported`
  - clears `extractedText`
  - sets `extractedTextCharCount: 0`
- Failed extraction:
  - sets `extractionStatus: error`
  - stores student-safe/admin-safe `extractionError`

Result:
- Material extraction pipeline has a safe first backend pass.
- TXT and CSV can now become usable source text after Firebase Functions deployment.
- PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, and images are intentionally not parsed in this first pass.
- Study Guide generation was not changed yet.
- Flutter UI was not changed.
- `node -c functions/src/index.js` passed.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a backend-only extraction foundation.
- It did not change Study Guide generation.
- It did not change Cloud Function request/response contracts used by Flutter.
- It did not change Firestore rules.
- It did not change Firestore collection names.
- It did not change existing material upload behavior.
- It did not change Firebase Storage upload paths.
- It did not change recording behavior.
- It did not change transcript generation.
- It did not change AI job creation.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.
- It has not been deployed yet.

Deployment note:
- This commit is pushed to GitHub `dev`.
- Firebase Functions deployment is still required before the trigger runs in production.
- Do not assume extraction is active until deployment is completed and tested.

Near-term follow-up:
- Deploy only the new extraction function when ready.
- Upload a TXT test material and confirm:
  - `extractionStatus: processing`
  - then `extractionStatus: done`
  - `extractedText` exists
  - `extractedTextCharCount` is populated
- Upload a CSV test material and confirm the same behavior.
- Upload an unsupported material such as XLSX/PPTX and confirm:
  - `extractionStatus: unsupported`
- Only after extraction is tested should Study Guide generation be updated to include relevant extracted material text.

Product/AI quality decision:
- Uploaded materials should not be blindly trusted.
- Students may upload unrelated, duplicate, low-quality, or wrong-class files.
- Future Study Guide generation should keep completed transcripts as the primary source of truth.
- Extracted materials should supplement the guide only when relevant to the selected class context.
- The generation prompt should ignore or down-rank unrelated, corrupted, sparse, duplicate, or conflicting uploads.
- The model should not infer facts from filenames alone.

## Completed Study Guide UX Pass 1 — Transcript Source Clarity

Commits:
- `a3f54a6 Clarify class study guide source`
- `c09a4f1 Clarify study guide transcript source`

Problem:
- The class Study Guide request UI used broad wording that could imply uploaded materials were included.
- The Study Guide viewer did not explain what source content was used.
- Current backend generation uses completed class transcripts/recordings only:
  - `includedRecordings: true`
  - `includedMaterials: false`
  - `source: recordings`
- Uploaded materials should be included in Study Guide generation later, but that is a separate feature pass.

Changes:
- Updated `lib/screens/class_lectures_screen.dart`.
- Updated `lib/screens/class_study_guide_screen.dart`.
- Clarified class Study Guide request copy to say it uses completed transcripts.
- Clarified the Study Guide viewer source near the top of the screen.

Display behavior:
- Requesting copy:
  - `Requesting class study guide...`
  - became `Requesting study guide from completed transcripts...`
- Success copy:
  - `Study guide requested.`
  - became `Study guide requested from completed transcripts.`
- Existing-request copy:
  - `Study guide already requested ($status).`
  - became `Study guide already requested from completed transcripts ($status).`
- Tooltip:
  - `Generate class study guide`
  - became `Generate study guide from recordings`
- Study Guide viewer now shows:
  - `Generated from completed class transcripts.`

Result:
- The Study Guide UI now honestly matches current backend behavior.
- Students are less likely to assume uploaded materials are included before that feature is implemented.
- `flutter analyze` passed.
- Changes were committed and pushed to `origin/dev`.

Safety:
- These were display-only Study Guide UX changes.
- They did not change Study Guide generation logic.
- They did not change Cloud Function contracts.
- They did not change AI job creation.
- They did not change Firestore queries.
- They did not change Firestore writes.
- They did not add, remove, or rename Firestore fields.
- They did not change material upload behavior.
- They did not change recording behavior.
- They did not change transcript generation.
- They did not change auth/login/logout behavior.
- They did not change navigation.
- They did not change academic structure requirements.

Near-term follow-up:
- Add uploaded materials to Study Guide generation as a separate feature pass.
- That future pass should inspect and update:
  - material text extraction behavior
  - class/topic source selection
  - Firestore source metadata
  - Cloud Function generation contract
  - UI copy after materials are truly included

UX decision:
- Current UI should not overpromise materials-based generation.
- Transcript-source clarity is preferable until the backend includes uploaded materials.
- Uploaded materials are important to include soon, but that should be handled as a dedicated implementation pass, not a copy-only patch.

## Completed Lecture Detail / AI UX Pass 1 — AI Output Guidance and Status Simplification

Commits:
- `9835235 Clarify transcription request failure`
- `1ccbff4 Explain transcript requirement for AI outputs`
- `386f172 Simplify lecture detail status card`

Problems:
- A failed transcription request could show raw exception text to the student.
- AI output buttons were disabled when the transcript was not ready, but the screen did not clearly explain why.
- The lecture detail card showed technical/redundant status lines:
  - `Session status`
  - `Audio status`
- These backend statuses were useful for development but cluttered the student-facing detail screen.

Changes:
- Updated `lib/screens/lecture_detail_screen.dart`.
- Replaced raw transcription request failure feedback with student-facing retry copy.
- Added helper text under AI Outputs when the transcript is not ready.
- Removed `Session status` and `Audio status` from the student-facing lecture detail card.
- Removed unused formatter helpers and unused local variables after simplifying the status card.

Display behavior:
- Transcription request failure:
  - `Failed: <raw exception>`
  - became `Could not request transcription. Please try again.`
- AI Outputs helper when transcript is not ready:
  - `Transcription must be ready before generating summary, notes, or practice test.`
- Lecture detail card now keeps the useful student-facing transcript line:
  - `Transcript status: No transcript`
  - `Transcript status: Transcript ready`
  - `Transcript status: Processing`
  - `Transcript status: Queued`
  - `Transcript status: Failed`
- Lecture detail card no longer shows:
  - `Session status`
  - `Audio status`

Result:
- Lecture detail screen is clearer for students.
- AI output generation requirements are explained before the student can request Summary, Notes, or Practice Test.
- Redundant backend-oriented status labels were removed from the student UI.
- `flutter analyze` passed.
- Phone check passed on the physical Android device.
- Changes were committed and pushed to `origin/dev`.

Safety:
- These were display-only Lecture Detail / AI UX changes.
- They did not change transcription request logic.
- They did not change transcript generation.
- They did not change AI job creation.
- They did not change Cloud Function contracts.
- They did not change Firestore queries.
- They did not change Firestore writes.
- They did not add, remove, or rename Firestore fields.
- They did not change Firebase Storage upload.
- They did not change recording behavior.
- They did not change Android foreground or locked-screen recording behavior.
- They did not change wakelock behavior.
- They did not change file opening or playback behavior.
- They did not change auth/login/logout behavior.
- They did not change navigation.
- They did not change academic structure requirements.

UX decision:
- The lecture detail screen should show statuses that help the student understand what they can do next.
- Transcript readiness is important because it gates Summary, Notes, and Practice Test generation.
- `sessionStatus` and `audioStatus` remain useful backend/debug fields, but they should not clutter the student-facing detail card.
- Raw exception text should not appear in primary student feedback.

## Completed Materials UX Pass 3 — Upload Feedback Copy

Commit:
- `3c786a7 Clarify material upload feedback`

Problem:
- Materials upload/delete feedback was technically accurate but not ideal for students.
- Success feedback was generic:
  - `Material uploaded.`
- Failure feedback exposed raw exception text:
  - `Upload failed: $error`
  - `Delete failed: $error`

Change:
- Updated `lib/screens/class_materials_screen.dart`.
- Clarified the upload success SnackBar.
- Replaced raw exception-based failure SnackBars with student-facing retry guidance.

Display behavior:
- Upload success:
  - `Material uploaded.`
  - became `Material uploaded to this class.`
- Upload failure:
  - `Upload failed: $error`
  - became `Upload failed. Please try again.`
- Delete failure:
  - `Delete failed: $error`
  - became `Delete failed. Please try again.`

Result:
- Materials feedback is clearer and less technical.
- Raw exception text is no longer shown to students in these SnackBars.
- `flutter analyze` passed.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Materials UX copy change.
- It did not change upload logic.
- It did not change delete logic.
- It did not change Firebase Storage paths.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change file opening logic.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change recording behavior.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.

UX decision:
- Student-facing SnackBars should be short, actionable, and non-technical.
- Raw exception details are useful for logs/debugging, not for the primary student UI.
- The upload success message should reinforce that the material was saved to the current class.

## Completed Materials UX Pass 2 — Material Fallback Details

Commit:
- `4902191 Clarify material fallback details`

Problem:
- The material fallback/details screen for files without in-app preview showed technical or stale information.
- Example issues:
  - Raw material type labels such as `spreadsheet`.
  - MIME type shown to students.
  - Raw Firebase download URL shown to students.
  - Stale copy mentioning future file preview and AI text extraction.

Change:
- Updated `lib/screens/class_materials_screen.dart`.
- Added display-only formatting for fallback material type labels.
- Removed MIME type from the student-facing fallback/details screen.
- Removed the raw Firebase download URL from the student-facing fallback/details screen.
- Replaced stale preview/AI extraction copy with clear preview-unavailable copy.

Display behavior:
- `spreadsheet` now displays as `Spreadsheet`.
- Other fallback type labels use student-facing names:
  - `image` → `Image`
  - `pdf` → `PDF`
  - `spreadsheet` → `Spreadsheet`
  - `presentation` → `Presentation`
  - `document` → `Document`
  - `text` → `Text`
  - unknown/other → `File`

Result:
- Fallback/details screen now shows clean student-facing information, for example:
  - `Type: Spreadsheet`
  - `Size: 29.7 KB`
  - `This file is saved as class material. Preview is not available for this file type yet.`
- Raw MIME type and Firebase URL are no longer shown to students.
- `flutter analyze` passed.
- Phone check passed on the physical Android device with an uploaded `.xlsx`.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Materials UX change.
- It did not change upload behavior.
- It did not change delete behavior.
- It did not change Firebase Storage paths.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change file opening logic.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change recording behavior.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.

UX decision:
- Unsupported-preview material details should reassure the student that the file is saved.
- Technical debugging details like MIME type and Firebase URL should not be shown in the student UI.
- Preview availability should be explained clearly without overpromising AI behavior.

## Completed Materials UX Pass 1 — Material Card Metadata

Commit:
- `299a71d Format material card metadata`

Problem:
- Class material cards showed technical metadata.
- Examples:
  - `pdf`
  - `image`
  - `2026-07-04`
- This was accurate but not polished for a student-facing Materials screen.

Change:
- Updated `lib/screens/class_materials_screen.dart`.
- Added display-only formatter helpers for:
  - Material type labels.
  - Material added date.
- Replaced raw material type/date subtitle parts with student-facing labels.

Display behavior:
- Material type labels:
  - `image` → `Image`
  - `pdf` → `PDF`
  - `spreadsheet` → `Spreadsheet`
  - `presentation` → `Presentation`
  - `document` → `Document`
  - `text` → `Text`
  - unknown/other → `File`
- Material date:
  - `2026-07-04` → `Added Jul 4, 2026`

Result:
- Material cards now show clean metadata, for example:
  - `PDF • Added Jul 4, 2026`
  - `Image • Added Jul 4, 2026`
- `flutter analyze` passed.
- Phone check passed on the physical Android device.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Materials UX change.
- It did not change upload behavior.
- It did not change delete behavior.
- It did not change Firebase Storage paths.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change file opening or playback behavior.
- It did not change recording behavior.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.

UX decision:
- The Materials screen should present files as study resources, not raw backend objects.
- Material type and added date are useful card metadata.
- Exact upload time is not needed on this screen.

## Completed Library UX Pass 6 — Search Empty State Copy

Commit:
- `1a33cf6 Clarify library search empty state`

Problem:
- The main Library page search no-results state only showed a short message:
  - `No classes match`
- It did not guide the student toward the next useful action.

Change:
- Updated `lib/screens/home_shell/pages/library_page.dart`.
- Reused the existing optional helper copy support in `_LibraryEmptyState`.
- Added helper copy only for the search no-results state.

Result:
- Search no-results state now shows:
  - `No classes match`
  - `Try a different class name or clear the search.`
- `flutter analyze` passed.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Library UX change.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change session metadata.
- It did not change Firebase Storage upload.
- It did not change recording behavior.
- It did not change Android foreground or locked-screen recording behavior.
- It did not change wakelock behavior.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change transcript generation.
- It did not change playback.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.
- It did not affect the true empty Library state behavior.

UX decision:
- Search-empty states should be concise but actionable.
- Since the user has already entered a query, the next useful actions are to try another class name or clear the search.

## Completed Library UX Pass 5 — Empty Library State Copy

Commit:
- `dfc8414 Clarify empty library state`

Problem:
- The main Library page empty state only showed a generic message:
  - `No recordings yet`
- For a new student, that did not explain what action to take next.

Change:
- Updated `lib/screens/home_shell/pages/library_page.dart`.
- Added optional helper copy support to `_LibraryEmptyState`.
- Used the helper copy only for the true empty Library state.
- Left the search-empty state unchanged.

Result:
- Empty Library state now shows:
  - `No recordings yet`
  - `Record a lecture from the Recorder tab to build your Library.`
- `flutter analyze` passed.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Library UX change.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change session metadata.
- It did not change Firebase Storage upload.
- It did not change recording behavior.
- It did not change Android foreground or locked-screen recording behavior.
- It did not change wakelock behavior.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change transcript generation.
- It did not change playback.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.
- It did not affect the no-search-results empty state.

UX decision:
- A true empty state should help the student understand the next useful action.
- The Library should guide new users toward recording their first lecture.
- Search-empty states should remain concise because the user already has Library content.

## Completed Library UX Pass 4 — Main Library Class Latest Date

Commit:
- `34f0274 Format library class latest dates`

Problem:
- The main Library page class cards still showed raw Dart timestamp output.
- Example:
  - `2026-06-27 20:20:20.366`
- That was too technical for the class-selection screen.

Change:
- Updated `lib/screens/home_shell/pages/library_page.dart`.
- Replaced the raw latest lecture timestamp with a date-only student-facing label.
- Kept exact lecture time out of the main Library page because this page is for class selection, not lecture-level detail.

Result:
- Library class cards now show:
  - `Latest: Jun 27, 2026`
  - followed by the existing lecture count, such as `Lectures: 21`.
- Phone check passed on the physical Android device.
- `flutter analyze` passed.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only Library UX change.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not add, remove, or rename Firestore fields.
- It did not change session metadata.
- It did not change Firebase Storage upload.
- It did not change recording behavior.
- It did not change Android foreground or locked-screen recording behavior.
- It did not change wakelock behavior.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change transcript generation.
- It did not change playback.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.

UX decision:
- The main Library page should help students choose a class quickly.
- Date-only latest activity is enough at this level.
- Exact lecture date/time remains better suited for the class lecture list.

## Completed Library UX Pass 3 — Lecture Detail Status Labels

Commit:
- `b352db8 Format lecture detail status labels`

Problem:
- The lecture detail screen was still showing raw backend status values to students.
- Examples included:
  - `Session status: ready`
  - `Audio status: uploaded`
  - `Transcript status: done`
  - `Status: done` in the AI Outputs section.

Changes:
- Updated `lib/screens/lecture_detail_screen.dart`.
- Added display-only formatter helpers for:
  - Session status.
  - Audio status.
  - Transcript status.
  - AI output status.
- Converted raw backend values into student-facing labels.

Status display behavior:
- Session:
  - `ready` → `Ready`
  - `processing` → `Processing`
  - `error` → `Needs attention`
  - `unknown` / empty → `Unknown`
- Audio:
  - `uploaded` → `Uploaded`
  - `uploading` → `Uploading`
  - `error` → `Upload failed`
  - `unknown` / empty → `Unknown`
- Transcript:
  - `done` → `Transcript ready`
  - `processing` → `Processing`
  - `pending` → `Queued`
  - `error` → `Failed`
  - `none` / empty → `No transcript`
- AI Outputs:
  - `done` → `Ready`
  - `processing` → `Processing`
  - `pending` → `Queued`
  - `error` → `Failed`
  - `none` / empty → `Not started`

Result:
- Lecture detail screen now presents status values in student-facing language.
- The top detail card now reads cleanly, for example:
  - `Session status: Ready`
  - `Audio status: Uploaded`
  - `Transcript status: Transcript ready`
- The AI Outputs section now reads cleanly, for example:
  - `Status: Ready`
- `flutter analyze` passed.
- Phone check passed on the physical Android device.
- Change was committed and pushed to `origin/dev`.

Safety:
- This was a display-only UX change.
- It did not change backend status values.
- It did not add, remove, or rename Firestore fields.
- It did not change Firestore queries.
- It did not change Firestore writes.
- It did not change Firebase Storage upload.
- It did not change recording behavior.
- It did not change Android foreground or locked-screen recording behavior.
- It did not change wakelock behavior.
- It did not change AI job creation.
- It did not change Cloud Function contracts.
- It did not change transcript generation.
- It did not change playback.
- It did not change auth/login/logout behavior.
- It did not change navigation.
- It did not change academic structure requirements.

UX decision:
- The lecture detail screen can show more status detail than the lecture list, but it should not expose raw backend terminology.
- Backend values remain useful for code and debugging.
- Student-facing labels should describe what the user can understand or act on.

## Completed Library UX Pass 2 — Class Lecture Card Metadata

Commits:
- `e344d89 Improve class lecture card metadata`
- `80037e0 Add compact AI status to lecture cards`

Problem:
- Class lecture cards were technically correct but hard to scan.
- Academic context, date, duration, and transcript status were compressed into one long subtitle.
- Transcript status values were still too close to backend terminology.
- The lecture list did not show whether AI outputs existed without opening each lecture detail page.

Changes:
- Updated `lib/screens/class_lectures_screen.dart`.
- Split lecture card metadata into intentional lines:
  - Academic context and lecture date.
  - Duration and transcript availability.
  - Compact AI output status.
- Changed raw transcript display language into student-facing card labels:
  - `done` → `Ready`
  - `processing` → `Processing`
  - `pending` → `Queued`
  - `error` → `Failed`
  - `none` / empty → `No transcript`
- Added compact AI status display based on existing session fields:
  - `summaryStatus`
  - `notesStatus`
  - `quizStatus`

AI card display behavior:
- No outputs requested:
  - `AI: Not started`
- One or more outputs pending/processing:
  - `AI: Processing`
- One output ready:
  - `AI: Summary ready`
  - `AI: Notes ready`
  - `AI: Quiz ready`
- Two outputs ready:
  - `AI: 2 outputs ready`
- All three outputs ready:
  - `AI: 3 outputs ready`
- One or more errors with nothing processing:
  - `AI: Failed`

Result:
- Lecture cards are easier to scan in the Library flow.
- Students can see transcript and AI readiness without opening every lecture.
- The page avoids showing separate diagnostic lines for Summary, Notes, and Quiz.
- `flutter analyze` passed.
- Phone check passed on the physical Android device.
- Changes were committed and pushed to `origin/dev`.

Safety:
- These were display-only Library UX changes.
- They only read existing session fields.
- They did not add, remove, or rename Firestore fields.
- They did not change Firestore queries.
- They did not change Firestore writes.
- They did not change Firebase Storage upload.
- They did not change recording behavior.
- They did not change Android foreground or locked-screen recording behavior.
- They did not change wakelock behavior.
- They did not change AI job creation.
- They did not change Cloud Function contracts.
- They did not change transcript generation.
- They did not change playback.
- They did not change auth/login/logout behavior.
- They did not change academic structure requirements.

UX decision:
- The lecture list should be a scanning surface, not a diagnostic screen.
- Transcript status belongs on the card because it gates AI usefulness.
- AI readiness belongs on the card as one compact summary line.
- Detailed Summary / Notes / Quiz status remains better suited for the lecture detail screen.

## Completed Library UX Pass 1 — Class Lecture Date Formatting

Commit:
- `a43b7aa Format class lecture dates`

Problem:
- The class lecture list displayed raw Dart `DateTime.toString()` output.
- That produced developer-style timestamps that were not student-friendly.

Change:
- Added `intl` date formatting to `lib/screens/class_lectures_screen.dart`.
- Added `_formatLectureDate(DateTime dt)`.
- Changed lecture subtitles to show a clean local date/time format:
  - `MMM d, yyyy • h:mm a`

Result:
- Lecture dates now display in a readable format such as:
  - `Jul 4, 2026 • 10:30 AM`
- `flutter analyze` passed.
- Patch was small and targeted:
  - `lib/screens/class_lectures_screen.dart`
  - 6 insertions, 1 deletion.
- Change was committed and pushed to `origin/dev`.

Safety:
- This changed display formatting only.
- This did not change Firestore queries.
- This did not change session metadata.
- This did not change recording behavior.
- This did not change Firebase Storage upload.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change academic structure requirements.
- This did not change auth/login behavior.
- This did not change navigation.

UX decision:
- Student-facing library/session lists should avoid raw technical timestamps.
- Date/time should be readable at a glance while preserving useful lecture context.

## Completed Auth Stability Pass 1 — Provider-Neutral Email Lookup Index

Commits:
- `d0996f4 Add user email lookup index`
- `6ed1481 Prevent email lookup failure from blocking login`

Problem:
- Google login already saved `email` and `emailLower` on `users/{uid}`, but troubleshooting by email still required querying the `users` collection.
- There was no direct support/admin lookup from email to Firebase Auth UID.
- Future auth providers are expected, including Apple login and email/password login, so the lookup must not be Google-specific.
- The first lookup write test failed with `PERMISSION_DENIED` until Firestore rules were deployed.
- The lookup write should not be allowed to block login because it is support metadata, not the primary auth/profile write.

Change:
- Added provider-neutral lookup documents at:
  - `userEmailLookup/{encodedEmailLower}`
- Added lookup fields:
  - `uid`
  - `email`
  - `emailLower`
  - `displayName`
  - `providers`
  - `updatedAt`
- Kept `users/{uid}` as the primary user profile document.
- Added `providers: FieldValue.arrayUnion(['google'])` to the primary user profile write.
- Added Firestore rules for `userEmailLookup`.
- Deployed Firestore rules with:
  - `firebase deploy --only firestore:rules`
- Hardened the login flow so `userEmailLookup` write failures are logged with `debugPrint` but do not block login.
- Kept the primary `users/{uid}` profile write required.

Result:
- Firestore rules deployed successfully.
- Google login completed successfully.
- `userEmailLookup/carbs1968mx%40gmail.com` was created and verified in Firestore.
- The lookup document correctly mapped email to UID.
- The lookup provides the troubleshooting bridge:
  - email → UID → `users/{uid}` → sessions/library/recordings/AI jobs.
- `flutter analyze` passed before commits.
- Working tree returned to clean state.
- Changes were pushed to `origin/dev`.

Safety:
- This did not change Google credential sign-in behavior.
- This did not change Firebase Auth UID as the primary identity.
- This did not rename existing collections or fields.
- This did not change existing `users/{uid}` document loading.
- This did not change recorder behavior.
- This did not change Firebase Storage upload.
- This did not change Firestore session metadata writes.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change academic structure requirements.
- This did not change login UI.
- This did not add Apple login yet.
- This did not add email/password login yet.

Future auth direction:
- Keep `users/{uid}` as the source of truth.
- Keep `userEmailLookup/{encodedEmailLower}` as support/admin lookup metadata.
- Keep provider naming neutral for future providers:
  - `google`
  - `apple`
  - `password`
- Apple login may provide a private relay email, so the lookup should be understood as “email known to Firebase Auth,” not always the user’s personal email.
- Future support tooling can use:
  - email → lookup doc → UID → user profile/sessions/recordings/AI jobs.

Runtime notes:
- App Check / Google Play Services warnings still appeared in Android logs.
- Those warnings did not block Google sign-in after this hardening pass.
- Continue monitoring App Check separately; do not mix App Check remediation into auth lookup or login UI work unless it starts blocking core flows.

## Completed Login UX Pass 1 — Clean Google Sign-In Screen

Commits:
- `d055652 Refresh login screen design`
- `427913b Remove unused login import`

Problem:
- The original login screen was very plain and did not match the newer Study Buddy UX direction.
- The first Figma-inspired attempt had too much marketing copy and too many stacked visual elements.
- The microphone illustration felt crowded and unnecessary.
- The wrong logo/icon asset was briefly tested and rejected.
- Terms / Privacy copy needed cleaner placement near the bottom of the login screen.

Change:
- Refreshed `lib/screens/login_screen.dart` with a cleaner, modern login layout.
- Kept the real Study Buddy logo visible on the login screen.
- Reduced copy to a minimal purpose line:
  - “Record and organize your classes.”
- Kept one clear primary action:
  - Google sign-in.
- Removed extra marketing paragraph and security reassurance line.
- Moved Terms / Privacy wording toward the bottom using responsive layout.
- Added `assets/icons/study_buddy_logo.png` as a Flutter asset.
- Added the logo asset to `pubspec.yaml`.
- Removed the now-unused constants import after the UI no longer referenced `kBrandPrimary`.

Result:
- Login screen rendered correctly after fixing the scroll/Spacer layout issue.
- Real logo appeared on the login screen.
- Text amount now feels cleaner and less marketing-heavy.
- Google sign-in button remained visible and primary.
- `flutter analyze` passed after cleanup.
- Working tree returned to clean state.
- Changes were committed and pushed to `origin/dev`.

Safety:
- This was a login presentation refresh only.
- This did not change `GoogleSignIn` logic.
- This did not change `FirebaseAuth.signInWithCredential`.
- This did not change the `users/{uid}` primary user document structure.
- This did not change email/emailLower metadata saving.
- This did not change Firestore rules.
- This did not add the future provider-neutral email lookup/index yet.
- This did not add Apple login or email/password login.
- This did not touch recorder, upload, Firestore session metadata, Firebase Storage, AI flow, academic structure, bottom navigation, or logout logic.

Future auth direction:
- Keep UID as the primary user document ID.
- Continue saving email and emailLower on `users/{uid}`.
- Add a provider-neutral `userEmailLookup/{encodedEmailLower}` index later for troubleshooting by email.
- Design that lookup to support future Google, Apple, and email/password providers.
- Do not use Google-specific collection names for provider-neutral user lookup.
- Apple login may use private relay emails, so future lookup should be treated as “email known to Firebase Auth,” not always a personal email.

Notes:
- App Check / Google Play Services warnings are still separate monitor-only items unless they begin blocking login, upload, or metadata saves.
- Package update warnings remain informational and should not be mixed into login UX work.

## Completed Recorder UX Pass 6 — Compact Start Button and Top-Aligned Layout

Commit:
- `6ff63db Use compact recorder start button`

Problem:
- The ready-state Record button was still too large after earlier size reductions.
- On a Samsung S24 Ultra, the circular Record button still crowded the screen and could require scrolling.
- The recorder content also had wasted vertical space under the app header because the page body was vertically centered.
- A form-heavy recorder screen needs a compact primary action that fits without fighting the bottom navigation.

Change:
- Replaced the giant circular ready-state Record button with a compact full-width rounded pill button.
- Kept Record visually primary with the same purple enabled color.
- Kept the disabled state grey when class/topic are incomplete.
- Top-aligned the recorder content instead of vertically centering it.
- Reduced the top spacer so the content starts closer to the app header.
- Removed now-unused circular button sizing code.

Result:
- Physical Android visual test passed.
- The oval/pill Record button looked better and fit the screen more naturally.
- Record button worked and started recording through the Android foreground service.
- Stop worked.
- Upload/session metadata save worked.
- Local file cleanup worked.
- `flutter analyze` passed before commit.
- Patch was targeted to `lib/screens/home_shell/pages/recorder_page.dart`.

Safety:
- This changed only ready-state layout and Record button presentation.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change app-restart recording restore behavior.
- This did not change Firebase Storage upload logic.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.
- This preserved the class-name future cache fix from `c65c0b6`.
- This preserved the Pause/Stop hierarchy update from `22e7eca`.
- This preserved the post-recording Upload/Discard update from `c25df02`.
- This preserved the context-lock update from `420c27d`.
- This preserved the app-restart context restore fix from `9d31452`.

UX decision:
- The ready-state Record action should be prominent, but not oversized.
- A full-width pill button better fits the required academic context fields than a large circular button.
- The ready screen should not require scrolling just to reach the Record action on large Android phones.

Runtime notes:
- Physical Android test logs still showed App Check placeholder-token warnings.
- Those warnings did not block recording, Storage upload, Firestore metadata verification, or local cleanup.
- Continue monitoring App Check separately; do not mix App Check work into recorder UX patches.

## Completed Recorder Stability Fix — Restore Context After App Restart

Commit:
- `9d31452 Restore recorder context after app restart`

Problem:
- If the app was fully closed during an active native-service recording, reopening restored the active recording file/state.
- However, class/topic fields were not restored in the Flutter UI.
- After stopping the restored recording, Upload could be blocked with “Please enter a class” because the UI fields were blank.
- Locking the screen did not reproduce this; the issue happened after full app close/reopen.

Cause:
- Native recording restore already restored `_filePath`, recording state, elapsed time, and backend state.
- It did not restore `_classCtl.text` or `_topicCtl.text`.
- Pending-file recovery already had filename-based class/topic restore, but active native recording restore did not.
- Restored native-service filenames can include seconds, for example:
  - `Summer - 12 - 2026-06-27_17-41-07.m4a`
- The filename parser only accepted the older minute-only pattern:
  - `Class - Topic - yyyy-mm-dd_hh-mm.m4a`

Change:
- Called `_restoreClassAndTopicFromFilename(restoredPath)` during active native recording restore.
- Updated the filename parser to accept both:
  - `Class - Topic - yyyy-mm-dd_hh-mm.m4a`
  - `Class - Topic - yyyy-mm-dd_hh-mm-ss.m4a`

Result:
- Physical Android test passed.
- Started recording with class/topic.
- Fully closed the app during recording.
- Reopened the app.
- Restored recording state appeared.
- Class/topic were restored from the filename.
- Stop worked.
- Upload worked without asking for class/topic again.
- Firestore session metadata saved the correct class/topic.
- Local file cleanup completed.
- `flutter analyze` passed before commit.
- Patch was targeted to `lib/screens/home_shell/pages/recorder_page.dart`, 3 insertions and 1 deletion.

Safety:
- This changed only restore/parsing behavior for recovered recorder state.
- This did not change filename creation.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen recording behavior.
- This did not change Firebase Storage upload logic.
- This did not change Firestore session metadata writes.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.

UX decision:
- If a recording is recoverable after app restart, its academic context should also be recoverable.
- The restored recording should be uploadable without forcing the student to re-enter class/topic metadata.

## Completed Recorder UX Pass 5 — Ready-State Guidance and Context Lock

Commit:
- `420c27d Clarify recorder ready state and lock context`

Problems:
- The Record screen did not clearly explain why Record was disabled before class/topic were complete.
- Field-level helper text stayed visible even after it was no longer useful, adding clutter.
- The topic helper example used “Photosynthesis”, which was too subject-specific.
- The existing class dropdown stayed accessible during recording, even though the recording context should be locked once recording starts.
- After stopping a recording, the context should remain locked until the user uploads or discards the local recording.

Change:
- Added ready-state helper text:
  - Missing class/topic: choose a class and enter a topic to start recording.
  - Ready: confirms the lecture will be saved to the selected class and topic.
- Simplified the topic helper example to “Exam review or Chapter 4 notes.”
- Hid class/topic helper text once it was no longer useful.
- Added a shared context-editing gate for the class dropdown area:
  - editable only when not recording, not uploading, and not in post-recording complete state.
- Disabled the class dropdown during recording/upload/post-recording state.
- Kept new-class and topic fields disabled during recording/upload/post-recording state.

Result:
- Physical Android test passed.
- Before recording, class/topic fields were editable and guidance appeared correctly.
- Once class/topic were complete, helper clutter disappeared and ready guidance appeared.
- During recording, the class dropdown was no longer accessible.
- During recording, topic/new-class fields remained locked.
- Pause, resume, and stop still worked.
- After stop, context stayed locked while Upload/Discard were visible.
- After Upload or Discard reset, context became editable again.
- `flutter analyze` passed before commit.
- Patch was targeted to `lib/screens/home_shell/pages/recorder_page.dart`.

Safety:
- This changed only recorder ready-state copy, helper visibility, and context-field enabled/disabled behavior.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change Firebase Storage upload logic.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.
- This preserved the class-name future cache fix from `c65c0b6`.
- This preserved the Pause/Stop hierarchy update from `22e7eca`.
- This preserved the post-recording Upload/Discard update from `c25df02`.

UX decision:
- The recording destination/context should be editable only before recording starts.
- Once recording starts, the selected class and topic become locked for that local recording.
- A new recording should not start, and the context should not change, until the previous recording is uploaded or discarded.

## Completed Recorder UX Pass 4 — Post-Recording Upload / Discard Clarity

Commit:
- `c25df02 Clarify recorder upload discard actions`

Problem:
- After stopping a recording, Upload and Discard were shown as equal side-by-side actions.
- This made Discard too visually equal to Upload.
- The screen also briefly exposed the Record button at the same time as Upload / Discard after the first layout change, which was not correct.
- In post-recording state, the user should choose Upload or Discard before starting another recording.

Change:
- Added explanatory post-recording copy:
  - Recording is saved locally.
  - Upload sends it to Study Buddy.
  - Discard deletes the local copy.
- Changed Upload to a full-width primary action.
- Changed Discard to a full-width outlined secondary/destructive action.
- Updated the Record button visibility condition so Record is hidden while `_recordingComplete` is true.
- Record returns only after Upload or Discard resets the recorder state.

Result:
- Physical Android test passed.
- Record worked.
- Stop worked.
- Post-recording message/buttons displayed correctly.
- Record button stayed hidden while Upload / Discard were visible.
- Upload worked and reset the screen to ready state.
- Discard worked and reset the screen to ready state.
- `flutter analyze` passed before commit.
- Patch was targeted to `lib/screens/home_shell/pages/recorder_page.dart`.

Safety:
- This only changed post-recording control layout and Record button visibility in post-recording state.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change Firebase Storage upload logic.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.
- This preserved the class-name future cache fix from `c65c0b6`.
- This preserved the Pause/Stop hierarchy update from `22e7eca`.
- This preserved the academic context label update from `3aa389d`.

UX decision:
- Upload is the primary post-recording action.
- Discard remains available but is visually secondary and destructive.
- A new recording should not begin until the previous local recording has either been uploaded or discarded.

Runtime notes:
- App Check / Google Play Services warnings may still appear in Android logs.
- These warnings did not block the tested recording, upload/session save, reset, or discard flows.
- Continue monitoring those warnings separately from recorder UX work.

## Completed Recorder UX Pass 3 — Academic Context Label Clarity

Commit:
- `3aa389d Clarify recorder academic context labels`

Problem:
- The recorder screen worked technically, but the academic context section was not as clear as it should be.
- “Current academic defaults” did not clearly tell the user where the recording would be saved.
- Class and topic labels did not clearly explain what the student needed to complete before recording.

Change:
- Renamed “Current academic defaults” to “Save destination”.
- Renamed “Level” to “Academic year / level”.
- Renamed “Select class” to “Choose an existing class”.
- Added helper text explaining that recordings are organized by class.
- Renamed “Enter new class” to “Or enter a new class”.
- Added helper text for when the class is not listed yet.
- Renamed “Topic” to “Topic / lecture name”.
- Added topic example helper text.

Result:
- `flutter analyze` passed.
- Patch was small and targeted: `lib/screens/home_shell/pages/recorder_page.dart`, 8 insertions and 5 deletions.
- Physical Android recording flow was tested afterward.
- Recording started successfully.
- Stop worked.
- Upload/session metadata save worked.
- Local file cleanup worked.
- Upload success returned the screen to the ready recording state.

Safety:
- This was copy/helper text only.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change Firebase Storage upload.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.

Runtime notes from physical Android test:
- Upload completed and verified session metadata.
- Local file deletion completed.
- App Check warnings still appeared, including placeholder-token and attestation warnings.
- Those warnings did not block Storage upload, Firestore metadata verification, or local cleanup in this test.
- Continue monitoring App Check warnings separately; do not mix App Check work into recorder UX patches.

## Completed Recorder UX Pass 2 — Pause/Stop Control Hierarchy

Commit:
- `22e7eca Improve recorder pause stop control hierarchy`

Problem:
- During active recording, the largest control on the screen was a red Stop button.
- This made the destructive/end-recording action too visually dominant.
- Figma UX review also flagged the Stop/Pause hierarchy as a concern.

Change:
- Kept the large circular Record button for the ready state.
- Removed the large red Stop circle from the active recording state.
- Made Pause/Resume the primary full-width action while recording or paused.
- Moved Stop to a smaller secondary outlined button below Pause/Resume.

Result:
- Physical Android test passed.
- No recorder flashing occurred after the class-name future cache fix.
- Start recording worked.
- Pause worked.
- Resume worked.
- Stop worked.
- Upload/session save worked.
- Upload success reset was retested with two additional recordings and returned to the ready state.
- Discard reset worked.
- Local cleanup still worked.
- `flutter analyze` passed.
- Patch was targeted to `lib/screens/home_shell/pages/recorder_page.dart`.

Safety:
- This only changed recorder control layout.
- This did not change recording start/pause/resume/stop service logic.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change Firebase Storage upload.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.
- This preserved the class-name future cache fix from `c65c0b6`.

UX decision:
- Pause/Resume is now the main action during live recording.
- Stop remains available but is visually secondary.
- This better matches safe recorder UX: continue/temporarily pause is primary; ending the session is deliberate.

Future hardening note:
- Current successful-upload flow resets the recorder UI after `_safeDeleteLocal(fileOnDisk)`.
- Normal testing shows this works, including two additional successful upload/reset tests.
- However, this is mildly fragile because a future local cleanup hang or throw could theoretically delay or block the UI reset after verified upload/session save.
- Future hardening idea: after Storage upload and Firestore session verification succeed, reset the recorder UI before local cleanup, or guard local cleanup so cleanup failure cannot prevent returning to the ready recording state.
- Do not change this immediately unless the issue becomes reproducible.

## Completed Recorder Stability Fix — Class Names Future Cache

Commit:
- `c65c0b6 Cache recorder class names future`

Problem:
- The recorder timer updates state every second during active recording.
- `recorder_page.dart` had a `FutureBuilder` that called `_fetchClassNames()` directly inside `build()`.
- That meant every timer tick recreated the class-name future and could trigger repeated Firestore reads.
- On physical Android, this showed up as visible flashing around the academic defaults / class selector area during recording.

Change:
- Added a cached `late Future<List<String>> _classNamesFuture`.
- Initialized it once in `initState()`.
- Updated the class-name `FutureBuilder` to use `_classNamesFuture`.
- Updated pull-to-refresh to intentionally refresh `_classNamesFuture`.

Result:
- Physical Android test confirmed the every-second flashing is gone.
- `flutter analyze` passed.
- Patch was small and targeted: `lib/screens/home_shell/pages/recorder_page.dart`, 8 insertions and 2 deletions.

Safety:
- This did not change recording start/pause/resume/stop behavior.
- This did not change Android foreground service behavior.
- This did not change wakelock behavior.
- This did not change locked-screen/background recording behavior.
- This did not change Firebase Storage upload.
- This did not change Firestore session metadata writes.
- This did not change filename format.
- This did not change AI transcript/summary/notes/quiz flow.
- This did not change bottom navigation behavior.
- This did not change academic structure requirements.

Future guidance:
- The root page still rebuilds every second for the timer.
- That is acceptable for now after caching the Firestore-backed class-name future.
- A future optimization could isolate timer rebuilds to the timer/status widget only.
- Reattempting the Stop/Pause hierarchy redesign is now safer than before, but still requires physical Android recording QA.

## Recorder UX Pass 2 Attempt — Reverted

Status:
- Not committed.
- Reverted with `git restore lib/screens/home_shell/pages/recorder_page.dart`.

Attempted change:
- Tested a visual control-hierarchy change in `recorder_page.dart`.
- Goal was to remove the huge red Stop button during active recording.
- Proposed layout:
  - Ready state: keep large Record button.
  - Recording/paused state: make Pause/Resume primary.
  - Move Stop Recording to a smaller secondary outlined button.

Result:
- Physical Android test found a visible UI flashing regression during active recording.
- The flash occurred every second around the academic defaults / class selector area, likely tied to the timer-driven rebuild.
- Recording engine still worked, but the visual regression was unacceptable for the recorder screen.

Decision:
- Do not commit this implementation.
- Do not repeat the same control-block replacement without a deeper layout/rebuild audit.
- Keep the current stable recorder controls for now.
- Preserve the already-committed recorder status-message improvement from `62886d9 Clarify recorder status messages`.

Safety outcome:
- Reverted before commit.
- `flutter analyze` passed after revert.
- Working tree returned to clean state.
- No recorder behavior, upload flow, Firestore metadata, filename format, wakelock behavior, foreground service behavior, bottom navigation, or class-selection logic was changed.

Future guidance:
- The Stop button hierarchy issue is still a UX concern, but it needs a safer implementation path.
- Before changing the recorder control layout again, inspect why the timer rebuild causes visual flashing.
- Prefer smaller visual adjustments that do not restructure the live recording control block.
- Test any recorder UI change on a physical Android phone while actively recording for at least 20–30 seconds.

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
- Home dashboard functionality was completed in:
  - `ec52b61 Wire home dashboard actions`
  - `f475826 Show recent classes on home dashboard`
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


---

## Completed Material-Aware Class Study Guides

Date: 2026-07-05

### Summary

Completed and verified the next Class Study Guide backend/UI pass: generated class Study Guides can now include extracted class-level uploaded materials in addition to completed class transcripts.

Completed transcripts remain the primary source. Extracted materials are supplemental and are only included when usable extracted text exists.

### Source-of-truth checkpoint

- Branch: `dev`
- Backend material-aware Study Guide commit:
  - `3dcebcc Include extracted materials in class study guides`
- UI source-copy commit:
  - `72261d6 Clarify study guide material sources`
- Working tree after push: clean
- GitHub `origin/dev`: current with local `dev`

### Backend behavior

Updated class Study Guide generation so the backend now:

- keeps completed class transcripts as the primary Study Guide source
- queries class-level materials with `extractionStatus == "done"`
- includes non-empty `extractedText` as supplemental Study Guide context
- limits supplemental material text passed to the model
- saves `sourceMaterials`
- saves `includedMaterialCount`
- saves `contentSnapshot.includedMaterials`
- sets final `source` dynamically:
  - `recordings_and_materials` when extracted materials were included
  - `recordings` when no usable extracted materials were included

Queued/request metadata uses:

- `recordings_with_materials_if_available`

Final generated guide metadata uses the actual resolved source.

### Firebase deployment

Deployed only the touched Study Guide functions:

- `requestClassStudyGuide`
- `onClassStudyGuideRequestWritten`

No broad Firebase deployment was performed.

### Firestore validation

Validated a generated class Study Guide for:

- Academic year: `prepa`
- Semester: `4to-semestre`
- Class: `summer`

Verified final guide fields:

- `source: recordings_and_materials`
- `includedMaterialCount: 1`
- `contentSnapshot.includedMaterials: true`
- `output.sourceSummary.includedMaterialCount: 1`
- `sourceMaterials[0].originalFileName: Candu intros and demo - March 20.txt`
- `sourceMaterials[0].materialType: text`

This confirms class-level extracted material was included in Study Guide generation.

### UI behavior

Updated the Class Study Guide viewer source description.

When extracted materials were included, the viewer now displays:

`Generated from completed class transcripts and extracted class materials.`

When no extracted materials were included, the viewer keeps the previous copy:

`Generated from completed class transcripts.`

### Manual test results

Tested on physical Android phone.

Result:

- App opened successfully.
- Existing generated Study Guide opened in-app.
- Firestore confirmed the guide included extracted material.
- UI displayed the corrected source description.
- No recording, upload, transcript, AI job, or library behavior regressed during this pass.
- `flutter analyze` passed with no issues for the UI copy change.

### Safety statement

Touched:

- `functions/src/index.js`
- `lib/screens/class_study_guide_screen.dart`

Did not touch:

- Recording flow
- Upload flow
- Firebase Storage upload
- Firestore session save
- Material upload UI
- Material extraction trigger
- Existing `/aiJobs` transcript/summary/notes/quiz flow
- Firebase Auth
- Academic settings loading
- Library/session loading
- Firestore rules
- Firestore indexes
- Google Drive logic

### Current status

Class Study Guide v1 now supports:

- request from class screen
- backend generation from completed transcripts
- supplemental inclusion of extracted class-level materials
- duplicate-generation/content snapshot awareness for recordings and materials
- read-only in-app viewing
- accurate UI source description

### Remaining future work

- Improve the Study Guide output format for stronger student value.
- Consider showing source material names in the Study Guide viewer.
- Add clearer generating/error status UI.
- Add refresh/regenerate UX when recordings or materials change.
- Add copy/export/share actions.
- Add topic-level Study Guides later.
- Later evaluate support for more material types beyond TXT/CSV extraction.


---

## Completed V1 Release-Readiness Codex Review Fixes

Date: 2026-07-05

### Summary

Completed the release-readiness fixes identified by the focused Codex review of current `origin/dev`.

Codex was used for review only. All code changes were inspected, patched, tested, committed, and pushed manually through the normal Study Buddy workflow.

### Source-of-truth checkpoint

- Branch: `dev`
- GitHub source of truth: latest `origin/dev`
- Working tree after final push: clean
- Review target commit before fixes:
  - `e69d7f0 Improve class study guide prompt quality`

### Completed fixes

#### Critical #1 — Native recorder fallback cleanup

Commit:

- `756c7a7 Clean up native recorder fallback`

Files changed:

- `android/app/src/main/kotlin/com/carbs/studybuddy/study_buddy/RecorderService.kt`
- `lib/screens/home_shell/pages/recorder_page.dart`

Fixed risk:

- Native recorder fallback could leave the Android foreground service and wakelock alive if native recording failed or verification failed before plugin fallback.

Result:

- Flutter now stops the native recorder service before plugin fallback when native verification fails.
- Android `RecorderService` now tears down foreground service/wakelock state if native `MediaRecorder` start fails.

Validation:

- `flutter analyze` passed.
- `flutter build apk --debug` passed.
- Physical Android phone recording test passed:
  - start worked
  - pause/resume worked
  - stop worked
  - upload completed
  - Firestore session metadata saved
  - local file deleted
  - no stuck recording notification observed

#### Critical #2 — Release signing safety

Commit:

- `363d713 Prevent debug signing for release builds`

File changed:

- `android/app/build.gradle.kts`

Fixed risk:

- Release builds could silently fall back to debug signing if `android/key.properties` was missing.

Result:

- Debug builds still work without `android/key.properties`.
- Release tasks now fail clearly if release signing config is missing.

Validation:

- `flutter analyze` passed.
- `flutter build apk --debug` passed.

#### High #3 — Orphaned material upload cleanup

Commit:

- `a504348 Clean up orphaned material uploads`

File changed:

- `lib/screens/class_materials_screen.dart`

Fixed risk:

- Material file upload could succeed in Firebase Storage but fail before Firestore material metadata was saved, leaving a private orphaned Storage file with no visible app delete path.

Result:

- Upload flow now tracks the uploaded Storage path.
- If material metadata is not saved, the app attempts to delete the uploaded Storage object.
- If material metadata is saved but class summary metadata update fails, the material remains visible/deletable and the class metadata error is logged.

Validation:

- `flutter analyze` passed.
- `flutter build apk --debug` passed.
- Physical Android phone test passed:
  - material upload worked
  - material appeared in app
  - delete worked
  - Firestore material document was deleted

#### High #4 — User email lookup rule hardening

Commit:

- `cbf0534 Harden user email lookup rules`

Files changed:

- `firestore.rules`
- `lib/screens/login_screen.dart`

Fixed risk:

- Any signed-in user could write `userEmailLookup` metadata for another email address while using their own UID.

Result:

- App now writes the lookup document using the normalized email as the document ID.
- Firestore rules now require:
  - lookup document key matches authenticated email
  - `emailLower` matches authenticated email
  - `email` matches authenticated email
  - `uid` matches authenticated UID

Validation:

- `flutter analyze` passed.
- `flutter build apk --debug` passed.
- Firestore rules deployed.
- Physical Android phone Google logout/login test passed.
- New plain-email lookup document confirmed in Firestore.

#### High #5 — V1 material extraction expectation clarity

Commit:

- `590920b Clarify material extraction support`

File changed:

- `lib/screens/class_materials_screen.dart`

Fixed risk:

- The app accepts PDF, Word, PowerPoint, Excel, TXT, and CSV uploads, but v1 AI extraction/Study Guide inclusion currently supports TXT/CSV-like text extraction. Users could assume all uploaded files contribute to Study Guides.

Result:

- Add-file bottom sheet now clearly says:
  - `PDF, Word, PowerPoint, Excel, TXT, or CSV. TXT/CSV can be extracted for Study Guides in v1.`

Validation:

- `flutter analyze` passed.
- Physical Android phone UI check passed.
- Copy wrapped cleanly and remained readable.

#### Medium #7 — Audio cleanup Firestore index

Commit:

- `e823bd5 Add audio cleanup Firestore index`

File changed:

- `firestore.indexes.json`

Fixed risk:

- Scheduled audio cleanup uses a `collectionGroup("sessions")` query with equality filters and a range filter. Without the composite collection-group index, cleanup could fail and audio could be retained longer than intended.

Result:

- Added collection-group index for `sessions`:
  - `transcriptStatus ASCENDING`
  - `audioDeletionStatus ASCENDING`
  - `audioDeleteAfter ASCENDING`

Validation:

- Firestore indexes deployed successfully with:
  - `firebase deploy --only firestore:indexes`

#### Medium #6 — Recording class summary update order

Commit:

- `3c37ccb Update class recording summary after session save`

File changed:

- `lib/screens/home_shell/pages/recorder_page.dart`

Fixed risk:

- Class recording summary fields were written before Storage upload and session metadata verification. A failed upload/session save could leave class metadata pointing to a nonexistent latest recording.

Result:

- Basic academic hierarchy writes remain early:
  - Academic Year
  - Semester
  - Class identity
- Recording-specific class summary fields now update only after session metadata is saved and verified:
  - `lastRecordingAt`
  - `latestSessionId`
  - `latestTopicName`
  - `hasRecordings`

Validation:

- `flutter analyze` passed.
- `flutter build apk --debug` passed.
- Physical Android phone recording test passed:
  - native foreground service started
  - stop worked
  - audio finalized
  - Storage upload completed
  - session metadata verified
  - local file deleted
  - Firestore session exists

### Completed release-readiness review list

- Critical #1: complete
- Critical #2: complete
- High #3: complete
- High #4: complete
- High #5: complete
- Medium #7: complete
- Medium #6: complete

### Safety statement

These fixes did not reintroduce Google Drive logic.

Academic structure remains:

`Academic Year → Semester → Class → Topic`

No intentional changes were made to:

- Firebase Auth baseline behavior
- Firebase Storage upload contracts
- Firestore session document structure
- transcript request flow
- summary/notes/quiz AI job flow
- class Study Guide document contract
- material extraction backend behavior
- library/session loading
- recording UI layout

### Current status

The focused Codex release-readiness review has been fully addressed.

Next recommended work:

- Run a full v1 physical Android regression checklist.
- Prepare Play Store release/build signing assets.
- Prepare Play Store listing, screenshots, privacy policy, and Data Safety answers.
- Run serious QA on Study Guide prompt quality before broader launch.


---

## Completed Settings Legal Links and Account Deletion Planning

Date: 2026-07-10

### Summary

Completed a v1 Settings and account-deletion readiness pass.

This pass focused on improving the Settings screen for the current single academic period model, adding required legal/account links, and documenting the Study Buddy account deletion process for Play Store readiness.

### Source-of-truth checkpoint

- Branch: `dev`
- GitHub source of truth: latest `origin/dev`
- Working tree after final push: clean

Completed commits:

- `80cd337 Improve settings academic period card`
- `309ae32 Polish settings language card`
- `23290e1 Add settings legal account links`
- `297ac50 Document account deletion process`

### Settings UI updates

Updated the Settings screen while keeping the current v1 single academic period model.

Completed:

- Removed inactive/nonfunctional Settings switches.
- Added a Current Academic Period card.
- Current Academic Period reads from:
  - `users/{uid}/academicSettings/current`
- Displays saved academic year and semester.
- Keeps the existing Manage Academic Settings route unchanged.
- Polished the Language card layout.
- Preserved existing language behavior:
  - updates `appLocale.value`
  - saves `users/{uid}.locale`
- Verified the Settings screen on a physical Android phone.

Not implemented in this pass:

- Multiple academic periods.
- Switch academic period flow.
- Add/delete academic period flow.
- Any change to recorder/upload/study-guide routing based on academic periods.

Multiple academic periods remain a future dedicated data-model and UX pass.

### Legal and account links

Added a Legal & Account section to Settings with links to the published Study Buddy website pages:

- Privacy Policy:
  - `https://studybuddynote.com/privacy`
- Terms and Conditions:
  - `https://studybuddynote.com/terms`
- Request Account Deletion:
  - `https://studybuddynote.com/delete-account`

Implemented with `url_launcher`.

Validation:

- Ran `flutter analyze`.
- Tested all three links on a physical Android phone.
- Confirmed each link opened successfully.
- Confirmed returning to the app did not crash.

### Account deletion process documentation

Created:

- `docs/account_deletion_process.md`

The document covers:

- in-app deletion verification expectations
- website/manual deletion request verification
- already-deleted account handling
- user-owned Firestore paths to delete
- user-owned Firebase Storage prefixes to delete
- top-level `aiJobs` cleanup
- Firebase Auth user deletion
- minimal internal deletion log
- manual deletion checklist
- planned authenticated in-app deletion flow
- website delete-account page copy requirements

### Account deletion v1 direction

Current v1 state:

- The app links to the public account deletion request page.
- Website/manual deletion requires verification through the user's Google sign-in email.
- Account deletion implementation is documented but not yet automated inside the app.

Recommended next implementation steps:

1. Create a trusted admin/manual deletion script.
2. Test deletion only on a test account.
3. Build authenticated in-app deletion later if it can be implemented and tested safely before public launch.

### Safety statement

Touched:

- `lib/screens/home_shell/pages/settings_page.dart`
- `docs/account_deletion_process.md`

Did not touch:

- Firebase Auth login/logout behavior
- recorder controls
- Android foreground recording service
- wakelock behavior
- Firebase Storage upload logic
- Firestore session save logic
- material extraction backend
- transcript/summary/notes/quiz AI flow
- class Study Guide generation
- academic settings save logic
- academic routing/data model
- Google Drive logic

### Current status

Settings is now closer to the Figma v1 direction while staying within the current single academic period model.

Legal/account links are available in-app and tested.

The account deletion process is documented and ready for either manual/admin tooling or a future authenticated in-app deletion flow.

## 2026-07-11 — Manual Account Deletion Script Tested

Summary:
- Tested the manual account deletion script end-to-end on disposable burner account `studybuddynote.1@gmail.com`.
- Added explicit Firebase Storage bucket support to the script because local Firebase Admin SDK did not auto-detect the bucket.
- Confirmed dry-run mode listed only the burner account data before destructive deletion.
- Confirmed delete mode removed the burner account from Firebase Auth, Firestore, email lookup metadata, and Firebase Storage.

Verification:
- `users/0tP5l2ltqxULwwjPqqpXUQEMqgr1` no longer exists.
- `userEmailLookup/studybuddynote.1@gmail.com` no longer exists.
- `recordings/0tP5l2ltqxULwwjPqqpXUQEMqgr1/` file count is `0`.
- Firebase Auth lookup returns `auth/user-not-found`.
- Firestore console visual check also confirmed the user and lookup documents are gone.

Safety:
- Tested on disposable burner account only.
- Required UID/email match before deletion.
- Required explicit `--confirm-delete` for destructive mode.
- No production/student account deletion was performed.

## 2026-07-12 — In-App Account Deletion and Localization Foundation

### In-app account deletion

Summary:
- Added and deployed the authenticated callable Cloud Function `deleteMyAccount`.
- Wired the Settings screen to call the backend deletion flow.
- Preserved the fixed destructive confirmation token `DELETE`.
- Added deletion progress, failure handling, forced sign-out, and return-to-login behavior.
- Tested the full deletion flow from the physical Android app using a disposable burner account.

Deletion scope verified:
- Firebase Auth user deleted.
- `users/{uid}` recursively deleted.
- `userEmailLookup/{email}` deleted.
- Firebase Storage files deleted under:
  - `recordings/{uid}/`
  - `classMaterials/{uid}/`
  - `user_photos/{uid}/`
- Top-level `aiJobs` for the UID deleted when present.
- `accountDeletionRequests` status log retained.
- Firestore console visual verification confirmed account data was removed.

Safety:
- Backend uses the authenticated UID and email rather than accepting another user’s UID.
- Email lookup and Firebase Auth identity are verified before deletion.
- No recording, upload, academic structure, library, or AI-generation behavior was changed.

Commits:
- `9633f83 Add in-app account deletion`

### Settings interface cleanup

Summary:
- Removed redundant explanations from self-explanatory Settings actions.
- Combined Manage Academic Settings, Privacy Policy, Terms and Conditions, and Delete Account into one consistent grouped action card.
- Preserved all navigation, deletion, logout, and academic settings behavior.

Commits:
- `0e9acc6 Unify settings action card layout`

### Localization architecture audit

Summary:
- Completed a review-only Codex audit against the latest `origin/dev`.
- Confirmed the app had three overlapping localization systems:
  - active custom `SBStrings`
  - inactive ARB/generated localization trees
  - unused `LocaleProvider`
- Confirmed most active user-facing text was still hardcoded in English.
- Selected Flutter `gen_l10n` and generated `AppLocalizations` as the long-term localization source of truth.
- English and Spanish remain the currently supported languages.
- Future languages will be added through ARB translation resources rather than editing every screen.

### Generated localization foundation

Summary:
- Added `l10n.yaml`.
- Configured `app_en.arb` as the template language.
- Completed the initial English/Spanish ARB key parity.
- Generated typed `AppLocalizations` accessors.
- Removed the unused Flutter Intl generator configuration and `intl_utils`.
- Removed duplicate inactive generated localization trees.
- Registered `AppLocalizations` alongside `SBStrings` during the staged migration.
- Preserved the existing `appLocale` notifier and Firestore locale persistence.

Validation:
- `flutter gen-l10n` completed successfully.
- `flutter analyze` reported no issues.

Commits:
- `249ac17 Establish generated localization foundation`
- `da9c453 Register generated app localizations`

### Academic Settings localization

Summary:
- Migrated Academic Settings from partial `SBStrings` usage and hardcoded English to generated `AppLocalizations`.
- Localized:
  - page title
  - academic level/year label
  - examples and helper text
  - semester/term label
  - validation
  - loading, save-success, and save-failure messages
  - save button and saving state
- Preserved Firestore loading and save behavior.

Validation:
- Tested on a physical Android phone in Spanish.
- Longer Spanish strings rendered without overflow.
- `flutter analyze` reported no issues.

Commit:
- `11c187a Localize academic settings screen`

### Settings localization

Summary:
- Migrated the main Settings screen to generated `AppLocalizations`.
- Localized:
  - page title and profile fallback
  - language selector and language names
  - academic-period labels
  - academic-settings action
  - Privacy Policy and Terms and Conditions
  - Delete Account row
  - full account-deletion confirmation dialog
  - cancellation, deletion progress, and safe failure messages
- Kept the destructive confirmation token `DELETE` fixed in every language.
- Replaced raw callable error display with a safe localized deletion failure message.

Validation:
- Tested the Settings screen and deletion dialog on a physical Android phone in Spanish.
- Ran a complete string-literal scan of `settings_page.dart`.
- The only remaining visible hardcoded text is the intentional fixed token `DELETE`.
- `flutter analyze` reported no issues.

Commit:
- `25eaf06 Localize settings screen`

### Remaining localization work

Planned staged migration:
1. Login and Home navigation.
2. Dashboard and Library.
3. Recorder.
4. Class lectures and Lecture detail.
5. Class materials and Class study guide.
6. Locale-aware dates, times, durations, numbers, file sizes, and pluralization.
7. Remove `SBStrings`, unused `LocaleProvider`, and remaining stale localization artifacts after all active screens use `AppLocalizations`.
8. Add English/Spanish widget tests, ARB key-parity checks, and hardcoded user-facing string checks.

## 2026-07-12 — English/Spanish Localization Migration Complete

### Summary

The active Flutter application has completed its staged migration to Flutter's generated localization system.

Current localization source of truth:
- Flutter `gen_l10n`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- generated `AppLocalizations` classes
- English and Spanish currently supported

The legacy custom `SBStrings` implementation and `lib/l10n/strings.dart` were removed after all active application screens migrated successfully.

User-authored data and AI-generated content continue to display exactly as stored. The application localizes its own labels, controls, statuses, validation, helper text, dialogs, and safe error messages without rewriting academic content.

### Screens and flows localized

Completed localization coverage includes:
- Login and authentication interface
- Home navigation
- Dashboard
- Library and session lists
- Academic Settings
- Main Settings
- Account deletion dialogs and progress states
- Recorder
- Locked-screen recording helper text
- Class Lectures
- Lecture Detail
- Transcript statuses
- AI job statuses
- AI summary, notes, and practice-test interface labels
- Class Materials and upload flows
- Material image, PDF, DOCX, and generic file-detail views
- Material deletion dialogs and status messages
- Class Study Guide interface
- Study-guide source descriptions and section headings

Locale-aware formatting was added where relevant for:
- dates
- times
- durations
- material-added dates
- AI output counts and pluralization

### Error-safety cleanup

User-facing raw Firebase, Firestore, callable-function, upload, transcript, AI-output, and academic-settings exceptions were replaced with safe localized messages where identified.

Technical exception details remain available through application logging for troubleshooting.

The Academic Settings load/save flow was specifically corrected so:
- users see localized failure messages;
- raw exception details are logged through `appLogger`;
- Firestore loading and saving behavior remains unchanged.

### Validation

Validation completed during the migration:
- `flutter gen-l10n` completed successfully after ARB changes.
- `flutter analyze` reported no issues at completion.
- Hardcoded user-facing string audits were run across active Flutter screens.
- No active Dart files reference `SBStrings`, `SBLocale`, or `lib/l10n/strings.dart`.
- Physical Android testing was completed throughout the migration.
- English/Spanish language switching and persistence were tested.
- Spanish layouts were checked for overflow and system-bar obstruction.
- Recording controls, timer, foreground recording, upload, Firestore metadata, local cleanup, materials upload, preview, deletion, and study-guide display remained operational in the tested flows.

### Safety statement

Baseline behavior preserved:
- Firebase Auth login/logout
- Firebase Storage recording and material uploads
- Firestore session and academic metadata
- UID-based user structure and email lookup support
- Academic hierarchy: Academic Year → Semester → Class → Topic
- Recording start, pause, resume, stop, and timer
- Android foreground and locked-screen recording behavior
- Wakelock behavior
- Recording filename format
- Local file cleanup safeguards
- Library and session loading
- Transcript, summary, notes, quiz, and study-guide flows
- Responsive layout behavior
- Material upload, preview, and deletion behavior

No Google Drive functionality was reintroduced.

Backend status identifiers, Firestore field names, collection names, storage paths, MIME types, and Cloud Function contracts were not renamed as part of localization.

### Commits

Localization implementation:
- `3bd3b9e Localize login and home navigation`
- `e06132c Localize dashboard and library`
- `1749241 Localize recorder screen`
- `02038aa Localize locked-screen recording helper`
- `945c3f6 Localize class lectures screen`
- `71667ee Localize lecture detail screen`
- `d00fb08 Localize class materials screen`
- `7282219 Localize class study guide screen`
- `18b5ff8 Complete generated localization migration`

Final error-safety cleanup:
- `d81c21b Hide raw academic settings errors`
- `b5fd1c0 Import academic settings logger`

Earlier localization foundation:
- `249ac17 Establish generated localization foundation`
- `da9c453 Register generated app localizations`
- `11c187a Localize academic settings screen`
- `25eaf06 Localize settings screen`

### Android-native localization and verification

Completed follow-up work:
- Localized the Android app label in default and Spanish native resources.
- Localized the foreground recording notification title and body in English and Spanish.
- Localized the Android recording notification channel name in English and Spanish.
- Preserved the existing notification channel ID, notification ID, service actions, intents, recorder state, wakelock, and foreground-service behavior.
- Added `tool/check_localization.sh` to:
  - run `flutter gen-l10n`
  - validate the untranslated-message report
  - run `flutter analyze`
  - detect uncommitted generated localization changes
- Completed physical Android validation of the localized recorder helper and native recording notification behavior.

Commits:
- `1efa614 Localize recorder ready helper`
- `6de0387 Localize Android recording notification`
- `7cb31f7 Add localization verification script`

### Remaining localization follow-up

The active Flutter and Android-native localization work is complete.

Separate follow-up work:
1. Review Google Play listing text, screenshots, release notes, privacy text, and Spanish store metadata.
2. Add automated English/Spanish widget tests.
3. Add an automated hardcoded user-facing string check.
4. Continue verifying that backend and SDK errors are converted into safe localized UI messages.
5. Decide whether future AI generation should explicitly request the user's selected language; existing AI output remains displayed as generated.

