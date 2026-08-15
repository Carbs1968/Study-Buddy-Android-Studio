// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Study Buddy Note';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get welcome => 'Welcome';

  @override
  String get profile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get school => 'School / University';

  @override
  String get accountType => 'Account Type';

  @override
  String get freemium => 'Freemium';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get signOut => 'Sign Out';

  @override
  String get loading => 'Loading...';

  @override
  String get academicSettingsTitle => 'Academic Settings';

  @override
  String get academicLevelYear => 'Academic level / year';

  @override
  String get academicLevelYearHint =>
      'Examples: Senior, Prepa, Primaria, Year 2';

  @override
  String get academicLevelYearHelp =>
      'Enter the level or year exactly how it makes sense in your school system.';

  @override
  String get currentSemesterTerm => 'Current semester / term';

  @override
  String get currentSemesterTermHint =>
      'Examples: Fall 2026, 5to semestre, Term 1';

  @override
  String get currentSemesterTermHelp =>
      'Enter the semester, trimester, term, or period you are currently in.';

  @override
  String get academicSettingsLoadFailed => 'Failed to load academic settings.';

  @override
  String get academicSettingsRequired =>
      'Please enter both academic level and semester.';

  @override
  String get academicSettingsSaved => 'Academic settings saved successfully.';

  @override
  String get academicSettingsSaveFailed => 'Failed to save academic settings.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get saving => 'Saving...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get chooseAppLanguage => 'Choose the app language.';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get notSet => 'Not set';

  @override
  String get currentAcademicPeriod => 'Current Academic Period';

  @override
  String get academicYear => 'Academic year';

  @override
  String get semester => 'Semester';

  @override
  String get manageAcademicSettings => 'Manage Academic Settings';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get linkOpenFailed => 'Could not open link. Please try again.';

  @override
  String get deleteAccountTitle => 'Permanently delete your account?';

  @override
  String get deleteAccountIntro =>
      'This will permanently delete your Study Buddy account and all associated data, including:';

  @override
  String get deleteAccountAcademicData =>
      '• Academic years, semesters, classes, and topics';

  @override
  String get deleteAccountFiles => '• Recordings and uploaded files';

  @override
  String get deleteAccountAiData =>
      '• Transcripts, summaries, notes, quizzes, and study guides';

  @override
  String get deleteAccountProfileData => '• Account and profile information';

  @override
  String get deleteAccountWarning => 'This action cannot be undone.';

  @override
  String deleteAccountTypeToken(String token) {
    return 'To continue, type $token below:';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAccountPermanently => 'Delete My Account Permanently';

  @override
  String get deletingAccount => 'Deleting your account and data…';

  @override
  String get deleteAccountFailed =>
      'We could not delete your account. Please try again.';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get loginTagline => 'Record and organize your classes.';

  @override
  String get unableToOpenPage => 'Unable to open this page. Please try again.';

  @override
  String get signInCanceled => 'Sign-in canceled.';

  @override
  String get signInFailed => 'We could not sign you in. Please try again.';

  @override
  String get legalAgreementPrefix => 'By continuing, you agree to our ';

  @override
  String get legalAgreementMiddle => ' and acknowledge our ';

  @override
  String get openClassOrTopicBeforeUpload =>
      'Open a class or topic before uploading study material.';

  @override
  String get dashboard => 'Home';

  @override
  String get record => 'Record';

  @override
  String get library => 'Library';

  @override
  String get settings => 'Settings';

  @override
  String get dashboardSubtitle =>
      'Your study workspace, organized by class and topic.';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get startNewRecordingDescription => 'Start a new classroom recording.';

  @override
  String get uploadStudyMaterial => 'Upload Study Material';

  @override
  String get chooseClassOrTopicBeforeUpload =>
      'Choose a class or topic before uploading.';

  @override
  String get recentClasses => 'Recent Classes';

  @override
  String get academicContext => 'Academic context';

  @override
  String get academicStructure => 'Year → Semester → Class → Topic';

  @override
  String get recentClassesLoadFailed => 'Could not load recent classes';

  @override
  String get checkConnectionTryAgain => 'Check your connection and try again.';

  @override
  String get loadingRecentClasses => 'Loading recent classes';

  @override
  String get checkingLatestStudyActivity =>
      'Checking your latest study activity...';

  @override
  String get recentClassesEmptyTitle => 'Recent classes will appear here';

  @override
  String get recentClassesEmptyMessage =>
      'Record a class session to see your most recent study activity here.';

  @override
  String get libraryEmptyMessage =>
      'Record a lecture from the Recorder tab to build your Library.';

  @override
  String get librarySearchEmptyMessage =>
      'Try a different class name or clear the search.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String latestDate(String date) {
    return 'Latest: $date';
  }

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String lectureCountGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lectures',
      one: '1 lecture',
      zero: 'No lectures',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get libraryLoadFailed =>
      'Could not load your Library. Please try again.';

  @override
  String get notSignedIn => 'Not signed in.';

  @override
  String get selectClass => 'Select a class';

  @override
  String get errorLoading => 'Error loading';

  @override
  String get noRecordingsYet => 'No recordings yet';

  @override
  String get noClassesMatch => 'No classes match your search';

  @override
  String get loadingAcademicSettings => 'Loading academic settings...';

  @override
  String get saveDestination => 'Save destination';

  @override
  String academicYearLevelValue(String value) {
    return 'Academic year / level: $value';
  }

  @override
  String semesterValue(String value) {
    return 'Semester: $value';
  }

  @override
  String get newClassLabel => 'Or enter a new class';

  @override
  String get newClassHelper => 'Use this if the class is not listed yet.';

  @override
  String get topicLectureName => 'Topic / lecture name';

  @override
  String get topicLectureExample => 'Example: Exam review or Chapter 4 notes.';

  @override
  String get recordingSavedLocally =>
      'Recording saved locally. Upload it to Study Buddy, or discard this local copy.';

  @override
  String get recordingComplete => 'Recording complete';

  @override
  String get recording => 'Recording';

  @override
  String get readyToRecord => 'Ready to record';

  @override
  String get uploading => 'Uploading...';

  @override
  String get chooseUploadOrDiscard => 'Choose Upload or Discard';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get upload => 'Upload';

  @override
  String get discard => 'Discard';

  @override
  String uploadingTo(String destination) {
    return 'Uploading to $destination';
  }

  @override
  String get recordingStartFailed =>
      'Could not start recording. Please try again.';

  @override
  String get recordingDidNotStart => 'Recording did not start.';

  @override
  String get pauseResumeFailed =>
      'Could not pause or resume recording. Please try again.';

  @override
  String get recordingBackendUnknown =>
      'Recording controls are unavailable because the recording state could not be confirmed.';

  @override
  String get recordingStopUnconfirmed =>
      'Could not confirm that recording stopped. Please try again before leaving this screen.';

  @override
  String get uploadCompleteReady =>
      'Upload complete. Ready for your next lecture!';

  @override
  String get uploadFailedSafe => 'Upload failed. Please try again.';

  @override
  String get recordingCorrupt =>
      'The recording appears empty or corrupt. Please record again.';

  @override
  String get academicSettingsRequiredBeforeRecording =>
      'Save your academic level and semester in Academic Settings before recording.';

  @override
  String get recordingRecoveredPartial =>
      'Recording appears to have stopped. Recovered audio may be partial.';

  @override
  String get recoveredRecordingSmall =>
      'A pending recording was recovered, but it appears unusually small. You can try uploading it or discard it.';

  @override
  String get recordingRecoveryMissing =>
      'Recording appears to have stopped, but no recoverable audio file was found.';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied.';

  @override
  String get fileMissing => 'The recording file is missing.';

  @override
  String get classTopicRequiredBeforeUpload =>
      'Enter a class and topic before uploading.';

  @override
  String get chooseExistingClass => 'Choose an existing class';

  @override
  String get recordingsOrganizedByClass => 'Recordings are organized by class.';

  @override
  String get chooseClassAndTopicToRecord =>
      'Choose a class and enter a topic to start recording.';

  @override
  String get recordingPausedHelp =>
      'Recording paused. Tap Resume to continue. Your recording is still saved.';

  @override
  String get recordingContinuesWhenLocked =>
      'Recording continues if your screen locks.';

  @override
  String get transcriptReady => 'Ready';

  @override
  String get transcriptProcessing => 'Processing';

  @override
  String get transcriptQueued => 'Queued';

  @override
  String get transcriptFailed => 'Failed';

  @override
  String get noTranscript => 'No transcript';

  @override
  String get aiProcessing => 'AI: Processing';

  @override
  String aiOutputsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outputs ready',
      one: '1 output ready',
    );
    return 'AI: $_temp0';
  }

  @override
  String get aiSummaryReady => 'AI: Summary ready';

  @override
  String get aiNotesReady => 'AI: Notes ready';

  @override
  String get aiQuizReady => 'AI: Quiz ready';

  @override
  String get aiFailed => 'AI: Failed';

  @override
  String get aiNotStarted => 'AI: Not started';

  @override
  String get generateStudyGuideTooltip =>
      'Generate study guide from recordings';

  @override
  String get materialsTooltip => 'Materials';

  @override
  String get studyGuideRequestFailed =>
      'Could not request the study guide. Please try again.';

  @override
  String get studyGuideRequested => 'Study guide requested.';

  @override
  String get studyGuideReused => 'Existing study guide opened.';

  @override
  String get studyGuideOpened => 'Study guide opened.';

  @override
  String get studyGuideUnavailable => 'Study guide is not available yet.';

  @override
  String get classLecturesLoadFailed =>
      'Could not load class recordings. Please try again.';

  @override
  String get lectureTopic => 'Lecture topic';

  @override
  String get noLecturesYet => 'No recordings yet';

  @override
  String durationValue(String value) {
    return 'Duration: $value';
  }

  @override
  String get studyGuideOpenFailed => 'Could not open the study guide.';

  @override
  String get studyGuideRequesting =>
      'Requesting a study guide from completed transcripts...';

  @override
  String get studyGuideAlreadyRequested =>
      'A study guide has already been requested from the completed transcripts.';

  @override
  String get close => 'Close';

  @override
  String get transcript => 'Transcript';

  @override
  String get playback => 'Playback';

  @override
  String get couldNotOpenLink => 'Could not open link.';

  @override
  String get openFromFirebaseStorage => 'Open from Firebase Storage';

  @override
  String get noPlaybackLinkAvailable => 'No playback link available.';

  @override
  String get viewTranscript => 'View transcript';

  @override
  String get transcriptIsEmpty => 'The transcript is empty.';

  @override
  String get transcriptError => 'Transcript error';

  @override
  String get ok => 'OK';

  @override
  String get requestTranscription => 'Request transcription';

  @override
  String get transcriptionRequested => 'Transcription requested.';

  @override
  String get aiOutputs => 'AI outputs';

  @override
  String get generateSummary => 'Generate summary';

  @override
  String get generateNotes => 'Generate notes';

  @override
  String get generatePracticeTest => 'Generate practice test';

  @override
  String get status => 'Status';

  @override
  String get view => 'View';

  @override
  String get request => 'Request';

  @override
  String levelValue(String value) {
    return 'Level: $value';
  }

  @override
  String fileValue(String value) {
    return 'File: $value';
  }

  @override
  String transcriptStatusValue(String value) {
    return 'Transcript status: $value';
  }

  @override
  String statusValue(String value) {
    return 'Status: $value';
  }

  @override
  String get transcriptionRequiredForAi =>
      'Transcription must be ready before generating a summary, notes, or practice test.';

  @override
  String get requestTranscriptionFailed =>
      'Could not request transcription. Please try again.';

  @override
  String get lectureDetailLoadFailed => 'Could not load this lecture.';

  @override
  String get aiReady => 'Ready';

  @override
  String get aiQueued => 'Queued';

  @override
  String get aiNotStartedLabel => 'Not started';

  @override
  String get noAiOutputTitle => 'No output yet';

  @override
  String get noAiOutputMessage => 'The AI output is empty or missing.';

  @override
  String get copiedJsonToClipboard => 'Copied JSON to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get aiOutputError => 'AI output error';

  @override
  String get aiOutputLoadFailed => 'Could not load the AI output.';

  @override
  String get keyPoints => 'Key Points';

  @override
  String get terms => 'Terms';

  @override
  String get equations => 'Equations';

  @override
  String get references => 'References';

  @override
  String answerValue(String value) {
    return 'Answer: $value';
  }

  @override
  String whyValue(String value) {
    return 'Why: $value';
  }

  @override
  String get transcriptLoadFailed => 'Could not load the transcript.';

  @override
  String materialsTitle(String className) {
    return '$className Materials';
  }

  @override
  String get materialTypeImage => 'Image';

  @override
  String get materialTypePdf => 'PDF';

  @override
  String get materialTypeSpreadsheet => 'Spreadsheet';

  @override
  String get materialTypePresentation => 'Presentation';

  @override
  String get materialTypeDocument => 'Document';

  @override
  String get materialTypeText => 'Text';

  @override
  String get materialTypeFile => 'File';

  @override
  String materialAddedDate(String date) {
    return 'Added $date';
  }

  @override
  String get materialUploaded => 'Material uploaded to this class.';

  @override
  String get materialUploadFailed => 'Upload failed. Please try again.';

  @override
  String get selectedFileUnavailable => 'Could not access the selected file.';

  @override
  String get addImage => 'Add image';

  @override
  String get addImageDescription =>
      'Upload a photo or image from your gallery.';

  @override
  String get addFile => 'Add file';

  @override
  String get addFileDescription =>
      'PDF, Word, PowerPoint, Excel, TXT, or CSV. TXT and CSV can be extracted for Study Guides.';

  @override
  String get addMaterial => 'Add material';

  @override
  String get couldNotLoadMaterials => 'Could not load class materials.';

  @override
  String get noClassMaterials => 'No class materials yet';

  @override
  String get noClassMaterialsDescription =>
      'Add images of notes, worksheets, PDFs, or documents here.';

  @override
  String get materialFallbackName => 'Material';

  @override
  String get deleteMaterialTitle => 'Delete material?';

  @override
  String get deleteMaterialMessage =>
      'This will remove the material from this class and delete the uploaded file.';

  @override
  String get deleteMaterialTooltip => 'Delete material';

  @override
  String get deleteFailed => 'Delete failed. Please try again.';

  @override
  String get delete => 'Delete';

  @override
  String get imageLoadFailed => 'Could not load the image.';

  @override
  String get docxPreviewFailed => 'Could not preview the DOCX file.';

  @override
  String get docxNoReadableText =>
      'No readable text was found in this DOCX file.';

  @override
  String get unknownSize => 'Unknown size';

  @override
  String materialTypeValue(String value) {
    return 'Type: $value';
  }

  @override
  String materialSizeValue(String value) {
    return 'Size: $value';
  }

  @override
  String get materialPreviewUnavailable =>
      'This file is saved as class material. Preview is not available for this file type yet.';

  @override
  String get materialDeleted => 'Material deleted.';

  @override
  String classStudyGuideTitle(String className) {
    return '$className Study Guide';
  }

  @override
  String get studyGuideLoadFailed => 'Could not load the study guide.';

  @override
  String get studyGuideNotFound => 'Study guide not found.';

  @override
  String get generatedFromTranscriptsAndMaterials =>
      'Generated from completed class transcripts and extracted class materials.';

  @override
  String get generatedFromTranscripts =>
      'Generated from completed class transcripts.';

  @override
  String get classStudyGuideFallbackTitle => 'Class Study Guide';

  @override
  String get keyTopics => 'Key topics';

  @override
  String get studySections => 'Study sections';

  @override
  String get reviewQuestions => 'Review questions';

  @override
  String get aiSummaryTitle => 'AI Summary';

  @override
  String get aiNotesTitle => 'AI Notes';

  @override
  String get aiQuizTitle => 'AI Practice Test';

  @override
  String get readyToRecordDescription =>
      'Ready to record. This lecture will be saved to the selected class and topic.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Study Buddy';

  @override
  String get onboardingWelcomeDescription =>
      'Record your classes, organize your schoolwork, and turn your study material into useful learning tools.';

  @override
  String get onboardingCaptureTitle => 'Capture and learn';

  @override
  String get onboardingCaptureDescription =>
      'Record lectures or upload class material. Study Buddy can create transcripts, summaries, notes, and quizzes from your content.';

  @override
  String get onboardingOrganizeTitle => 'Keep school organized';

  @override
  String get onboardingOrganizeDescription =>
      'Your work stays arranged by academic year, semester, class, and topic, so every recording and file has a clear home.';

  @override
  String get onboardingSetupTitle => 'Set up your workspace';

  @override
  String get onboardingSetupDescription =>
      'Next, choose your current academic year and semester. You can add classes and topics from the app afterward.';

  @override
  String get onboardingSetupButton => 'Set up my workspace';

  @override
  String get onboardingFeaturesTitle => 'Everything in one place';

  @override
  String get onboardingFeaturesDescription =>
      'Capture your classes, keep your materials together, and turn them into useful study tools.';

  @override
  String get onboardingRecordLecturesTitle => 'Record lectures';

  @override
  String get onboardingRecordLecturesDescription =>
      'Capture class audio without leaving Study Buddy.';

  @override
  String get onboardingUploadMaterialsTitle => 'Upload study materials';

  @override
  String get onboardingUploadMaterialsDescription =>
      'Keep class documents and learning resources with your recordings.';

  @override
  String get onboardingAiToolsTitle => 'Study smarter with AI';

  @override
  String get onboardingAiToolsDescription =>
      'Create transcripts, summaries, notes, quizzes, and study guides.';

  @override
  String get onboardingOrganizationTitle => 'Let\'s organize your studies';

  @override
  String get onboardingOrganizationDescription =>
      'Everything you record, upload, and generate with AI is organized into your academic workspace.';

  @override
  String get onboardingAcademicYearLabel => 'Academic Year';

  @override
  String get onboardingSemesterLabel => 'Semester';

  @override
  String get onboardingClassesLabel => 'Classes';

  @override
  String get onboardingTopicsLabel => 'Topics';

  @override
  String get onboardingWorkspaceHierarchyLabel => 'Your workspace hierarchy';

  @override
  String get changeAcademicPeriodTitle => 'Change current academic period?';

  @override
  String get changeAcademicPeriodMessage =>
      'Your existing recordings, materials, and study data will not be deleted. Study Buddy will use the new academic year and semester as your current period.';

  @override
  String get changeAcademicPeriodConfirm => 'Change Period';

  @override
  String get askAi => 'Ask AI';

  @override
  String get lectureChatTitle => 'Ask AI about this lecture';

  @override
  String get lectureChatIntro =>
      'Ask a question about this lecture. Study Buddy will answer from the lecture transcript.';

  @override
  String get lectureChatHint => 'Ask about this lecture...';

  @override
  String get lectureChatError =>
      'Study Buddy could not answer that question. Please try again.';

  @override
  String get send => 'Send';

  @override
  String get lectureChatTemporaryTitle => 'Chat is temporary';

  @override
  String get lectureChatTemporaryBody =>
      'This conversation won\'t be saved. If it improves your study material, you can update it before leaving.';

  @override
  String get lectureChatTemporarySummaryBody =>
      'This conversation won\'t be saved. If it improves your summary, you can update it before leaving.';

  @override
  String get lectureChatTemporaryNotesBody =>
      'This conversation won\'t be saved. If it improves your notes, you can update them before leaving.';

  @override
  String get lectureChatTemporaryQuizBody =>
      'This conversation won\'t be saved. If it improves your practice test, you can update it before leaving.';

  @override
  String get createRevisedSummary => 'Create revised summary';

  @override
  String get createRevisedNotes => 'Create revised notes';

  @override
  String get createRevisedPracticeTest => 'Create revised practice test';

  @override
  String get creatingRevision => 'Creating revised version...';

  @override
  String get revisionGenerationError =>
      'Study Buddy could not create a revised version. Please try again.';

  @override
  String get revisionPreviewTitle => 'Review revised version';

  @override
  String get replaceSummary => 'Replace summary';

  @override
  String get replaceNotes => 'Replace notes';

  @override
  String get replacePracticeTest => 'Replace practice test';

  @override
  String get replaceArtifactConfirmTitle => 'Replace current version?';

  @override
  String get replaceSummaryConfirmBody =>
      'This will replace the current summary for this lecture with the revised version.';

  @override
  String get replaceNotesConfirmBody =>
      'This will replace the current notes for this lecture with the revised version.';

  @override
  String get replacePracticeTestConfirmBody =>
      'This will replace the current practice test for this lecture with the revised version.';

  @override
  String get replaceArtifactError =>
      'Study Buddy could not replace the current version. Please try again.';

  @override
  String get replaceArtifactSuccess => 'Revised version saved.';

  @override
  String get confirm => 'Confirm';
}
