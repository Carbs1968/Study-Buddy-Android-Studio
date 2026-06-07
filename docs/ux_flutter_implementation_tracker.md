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

## Dark Mode Finding

Dark mode is currently not acceptable after the light-mode visual polish.

Cause:
- Several screens hardcode light-mode colors:
  - `Color(0xFFF6F8FB)`
  - `Colors.white`
  - `Colors.black54`
- In dark mode, text comes from the dark theme while cards/backgrounds remain light, causing poor contrast.
- Bottom navigation also needs proper dark-theme treatment.

Decision:
- Do not commit partial dark-mode experiments.
- Fix dark mode as a focused theme/UI task.
- Prefer replacing hardcoded light colors with theme-aware values:
  - `Theme.of(context).scaffoldBackgroundColor`
  - `Theme.of(context).cardColor`
  - `Theme.of(context).colorScheme.surface`
  - `Theme.of(context).colorScheme.onSurfaceVariant`
- Add dark `bottomNavigationBarTheme` in `main.dart` if needed.
- Convert and test one screen at a time.

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

- Real working repo is clean before this tracker file.
- Latest local `dev` is up to date with `origin/dev`.
- Low-risk light-mode visual polish is pushed.
- Dark-mode experiment was reverted.
- Next action after committing this tracker: plan a focused dark-mode fix.

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
