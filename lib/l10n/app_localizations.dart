import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Buddy Note'**
  String get appTitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School / University'**
  String get school;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @freemium.
  ///
  /// In en, this message translates to:
  /// **'Freemium'**
  String get freemium;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @academicSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Settings'**
  String get academicSettingsTitle;

  /// No description provided for @academicLevelYear.
  ///
  /// In en, this message translates to:
  /// **'Academic level / year'**
  String get academicLevelYear;

  /// No description provided for @academicLevelYearHint.
  ///
  /// In en, this message translates to:
  /// **'Examples: Senior, Prepa, Primaria, Year 2'**
  String get academicLevelYearHint;

  /// No description provided for @academicLevelYearHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the level or year exactly how it makes sense in your school system.'**
  String get academicLevelYearHelp;

  /// No description provided for @currentSemesterTerm.
  ///
  /// In en, this message translates to:
  /// **'Current semester / term'**
  String get currentSemesterTerm;

  /// No description provided for @currentSemesterTermHint.
  ///
  /// In en, this message translates to:
  /// **'Examples: Fall 2026, 5to semestre, Term 1'**
  String get currentSemesterTermHint;

  /// No description provided for @currentSemesterTermHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the semester, trimester, term, or period you are currently in.'**
  String get currentSemesterTermHelp;

  /// No description provided for @academicSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load academic settings.'**
  String get academicSettingsLoadFailed;

  /// No description provided for @academicSettingsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter both academic level and semester.'**
  String get academicSettingsRequired;

  /// No description provided for @academicSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Academic settings saved successfully.'**
  String get academicSettingsSaved;

  /// No description provided for @academicSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save academic settings.'**
  String get academicSettingsSaveFailed;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get chooseAppLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @currentAcademicPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current Academic Period'**
  String get currentAcademicPeriod;

  /// No description provided for @academicYear.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get academicYear;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @manageAcademicSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage Academic Settings'**
  String get manageAcademicSettings;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link. Please try again.'**
  String get linkOpenFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountIntro.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your Study Buddy account and all associated data, including:'**
  String get deleteAccountIntro;

  /// No description provided for @deleteAccountAcademicData.
  ///
  /// In en, this message translates to:
  /// **'• Academic years, semesters, classes, and topics'**
  String get deleteAccountAcademicData;

  /// No description provided for @deleteAccountFiles.
  ///
  /// In en, this message translates to:
  /// **'• Recordings and uploaded files'**
  String get deleteAccountFiles;

  /// No description provided for @deleteAccountAiData.
  ///
  /// In en, this message translates to:
  /// **'• Transcripts, summaries, notes, quizzes, and study guides'**
  String get deleteAccountAiData;

  /// No description provided for @deleteAccountProfileData.
  ///
  /// In en, this message translates to:
  /// **'• Account and profile information'**
  String get deleteAccountProfileData;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountTypeToken.
  ///
  /// In en, this message translates to:
  /// **'To continue, type {token} below:'**
  String deleteAccountTypeToken(String token);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account Permanently'**
  String get deleteAccountPermanently;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account and data…'**
  String get deletingAccount;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not delete your account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Record and organize your classes.'**
  String get loginTagline;

  /// No description provided for @unableToOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this page. Please try again.'**
  String get unableToOpenPage;

  /// No description provided for @signInCanceled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in canceled.'**
  String get signInCanceled;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in. Please try again.'**
  String get signInFailed;

  /// No description provided for @legalAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get legalAgreementPrefix;

  /// No description provided for @legalAgreementMiddle.
  ///
  /// In en, this message translates to:
  /// **' and acknowledge our '**
  String get legalAgreementMiddle;

  /// No description provided for @openClassOrTopicBeforeUpload.
  ///
  /// In en, this message translates to:
  /// **'Open a class or topic before uploading study material.'**
  String get openClassOrTopicBeforeUpload;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your study workspace, organized by class and topic.'**
  String get dashboardSubtitle;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @startNewRecordingDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new classroom recording.'**
  String get startNewRecordingDescription;

  /// No description provided for @uploadStudyMaterial.
  ///
  /// In en, this message translates to:
  /// **'Upload Study Material'**
  String get uploadStudyMaterial;

  /// No description provided for @chooseClassOrTopicBeforeUpload.
  ///
  /// In en, this message translates to:
  /// **'Choose a class or topic before uploading.'**
  String get chooseClassOrTopicBeforeUpload;

  /// No description provided for @recentClasses.
  ///
  /// In en, this message translates to:
  /// **'Recent Classes'**
  String get recentClasses;

  /// No description provided for @academicContext.
  ///
  /// In en, this message translates to:
  /// **'Academic context'**
  String get academicContext;

  /// No description provided for @academicStructure.
  ///
  /// In en, this message translates to:
  /// **'Year → Semester → Class → Topic'**
  String get academicStructure;

  /// No description provided for @recentClassesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent classes'**
  String get recentClassesLoadFailed;

  /// No description provided for @checkConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionTryAgain;

  /// No description provided for @loadingRecentClasses.
  ///
  /// In en, this message translates to:
  /// **'Loading recent classes'**
  String get loadingRecentClasses;

  /// No description provided for @checkingLatestStudyActivity.
  ///
  /// In en, this message translates to:
  /// **'Checking your latest study activity...'**
  String get checkingLatestStudyActivity;

  /// No description provided for @recentClassesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent classes will appear here'**
  String get recentClassesEmptyTitle;

  /// No description provided for @recentClassesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record a class session to see your most recent study activity here.'**
  String get recentClassesEmptyMessage;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record a lecture from the Recorder tab to build your Library.'**
  String get libraryEmptyMessage;

  /// No description provided for @librarySearchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different class name or clear the search.'**
  String get librarySearchEmptyMessage;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @latestDate.
  ///
  /// In en, this message translates to:
  /// **'Latest: {date}'**
  String latestDate(String date);

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @lectureCountGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No lectures} =1{1 lecture} other{{count} lectures}}'**
  String lectureCountGenerated(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @libraryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your Library. Please try again.'**
  String get libraryLoadFailed;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get notSignedIn;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select a class'**
  String get selectClass;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @noRecordingsYet.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordingsYet;

  /// No description provided for @noClassesMatch.
  ///
  /// In en, this message translates to:
  /// **'No classes match your search'**
  String get noClassesMatch;

  /// No description provided for @loadingAcademicSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading academic settings...'**
  String get loadingAcademicSettings;

  /// No description provided for @saveDestination.
  ///
  /// In en, this message translates to:
  /// **'Save destination'**
  String get saveDestination;

  /// No description provided for @academicYearLevelValue.
  ///
  /// In en, this message translates to:
  /// **'Academic year / level: {value}'**
  String academicYearLevelValue(String value);

  /// No description provided for @semesterValue.
  ///
  /// In en, this message translates to:
  /// **'Semester: {value}'**
  String semesterValue(String value);

  /// No description provided for @newClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Or enter a new class'**
  String get newClassLabel;

  /// No description provided for @newClassHelper.
  ///
  /// In en, this message translates to:
  /// **'Use this if the class is not listed yet.'**
  String get newClassHelper;

  /// No description provided for @topicLectureName.
  ///
  /// In en, this message translates to:
  /// **'Topic / lecture name'**
  String get topicLectureName;

  /// No description provided for @topicLectureExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Exam review or Chapter 4 notes.'**
  String get topicLectureExample;

  /// No description provided for @recordingSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Recording saved locally. Upload it to Study Buddy, or discard this local copy.'**
  String get recordingSavedLocally;

  /// No description provided for @recordingComplete.
  ///
  /// In en, this message translates to:
  /// **'Recording complete'**
  String get recordingComplete;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @readyToRecord.
  ///
  /// In en, this message translates to:
  /// **'Ready to record'**
  String get readyToRecord;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @chooseUploadOrDiscard.
  ///
  /// In en, this message translates to:
  /// **'Choose Upload or Discard'**
  String get chooseUploadOrDiscard;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @uploadingTo.
  ///
  /// In en, this message translates to:
  /// **'Uploading to {destination}'**
  String uploadingTo(String destination);

  /// No description provided for @recordingStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. Please try again.'**
  String get recordingStartFailed;

  /// No description provided for @recordingDidNotStart.
  ///
  /// In en, this message translates to:
  /// **'Recording did not start.'**
  String get recordingDidNotStart;

  /// No description provided for @pauseResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pause or resume recording. Please try again.'**
  String get pauseResumeFailed;

  /// No description provided for @recordingBackendUnknown.
  ///
  /// In en, this message translates to:
  /// **'Recording controls are unavailable because the recording state could not be confirmed.'**
  String get recordingBackendUnknown;

  /// No description provided for @recordingStopUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm that recording stopped. Please try again before leaving this screen.'**
  String get recordingStopUnconfirmed;

  /// No description provided for @uploadCompleteReady.
  ///
  /// In en, this message translates to:
  /// **'Upload complete. Ready for your next lecture!'**
  String get uploadCompleteReady;

  /// No description provided for @uploadFailedSafe.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get uploadFailedSafe;

  /// No description provided for @recordingCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The recording appears empty or corrupt. Please record again.'**
  String get recordingCorrupt;

  /// No description provided for @academicSettingsRequiredBeforeRecording.
  ///
  /// In en, this message translates to:
  /// **'Save your academic level and semester in Academic Settings before recording.'**
  String get academicSettingsRequiredBeforeRecording;

  /// No description provided for @recordingRecoveredPartial.
  ///
  /// In en, this message translates to:
  /// **'Recording appears to have stopped. Recovered audio may be partial.'**
  String get recordingRecoveredPartial;

  /// No description provided for @recoveredRecordingSmall.
  ///
  /// In en, this message translates to:
  /// **'A pending recording was recovered, but it appears unusually small. You can try uploading it or discard it.'**
  String get recoveredRecordingSmall;

  /// No description provided for @recordingRecoveryMissing.
  ///
  /// In en, this message translates to:
  /// **'Recording appears to have stopped, but no recoverable audio file was found.'**
  String get recordingRecoveryMissing;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get microphonePermissionDenied;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'The recording file is missing.'**
  String get fileMissing;

  /// No description provided for @classTopicRequiredBeforeUpload.
  ///
  /// In en, this message translates to:
  /// **'Enter a class and topic before uploading.'**
  String get classTopicRequiredBeforeUpload;

  /// No description provided for @chooseExistingClass.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing class'**
  String get chooseExistingClass;

  /// No description provided for @recordingsOrganizedByClass.
  ///
  /// In en, this message translates to:
  /// **'Recordings are organized by class.'**
  String get recordingsOrganizedByClass;

  /// No description provided for @chooseClassAndTopicToRecord.
  ///
  /// In en, this message translates to:
  /// **'Choose a class and enter a topic to start recording.'**
  String get chooseClassAndTopicToRecord;

  /// No description provided for @recordingPausedHelp.
  ///
  /// In en, this message translates to:
  /// **'Recording paused. Tap Resume to continue. Your recording is still saved.'**
  String get recordingPausedHelp;

  /// No description provided for @recordingContinuesWhenLocked.
  ///
  /// In en, this message translates to:
  /// **'Recording continues if your screen locks.'**
  String get recordingContinuesWhenLocked;

  /// No description provided for @transcriptReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get transcriptReady;

  /// No description provided for @transcriptProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get transcriptProcessing;

  /// No description provided for @transcriptQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get transcriptQueued;

  /// No description provided for @transcriptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transcriptFailed;

  /// No description provided for @noTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript'**
  String get noTranscript;

  /// No description provided for @aiProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI: Processing'**
  String get aiProcessing;

  /// No description provided for @aiOutputsReady.
  ///
  /// In en, this message translates to:
  /// **'AI: {count, plural, =1{1 output ready} other{{count} outputs ready}}'**
  String aiOutputsReady(int count);

  /// No description provided for @aiSummaryReady.
  ///
  /// In en, this message translates to:
  /// **'AI: Summary ready'**
  String get aiSummaryReady;

  /// No description provided for @aiNotesReady.
  ///
  /// In en, this message translates to:
  /// **'AI: Notes ready'**
  String get aiNotesReady;

  /// No description provided for @aiQuizReady.
  ///
  /// In en, this message translates to:
  /// **'AI: Quiz ready'**
  String get aiQuizReady;

  /// No description provided for @aiFailed.
  ///
  /// In en, this message translates to:
  /// **'AI: Failed'**
  String get aiFailed;

  /// No description provided for @aiNotStarted.
  ///
  /// In en, this message translates to:
  /// **'AI: Not started'**
  String get aiNotStarted;

  /// No description provided for @generateStudyGuideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate study guide from recordings'**
  String get generateStudyGuideTooltip;

  /// No description provided for @materialsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsTooltip;

  /// No description provided for @studyGuideRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request the study guide. Please try again.'**
  String get studyGuideRequestFailed;

  /// No description provided for @studyGuideRequested.
  ///
  /// In en, this message translates to:
  /// **'Study guide requested.'**
  String get studyGuideRequested;

  /// No description provided for @studyGuideReused.
  ///
  /// In en, this message translates to:
  /// **'Existing study guide opened.'**
  String get studyGuideReused;

  /// No description provided for @studyGuideOpened.
  ///
  /// In en, this message translates to:
  /// **'Study guide opened.'**
  String get studyGuideOpened;

  /// No description provided for @studyGuideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Study guide is not available yet.'**
  String get studyGuideUnavailable;

  /// No description provided for @classLecturesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load class recordings. Please try again.'**
  String get classLecturesLoadFailed;

  /// No description provided for @lectureTopic.
  ///
  /// In en, this message translates to:
  /// **'Lecture topic'**
  String get lectureTopic;

  /// No description provided for @noLecturesYet.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noLecturesYet;

  /// No description provided for @durationValue.
  ///
  /// In en, this message translates to:
  /// **'Duration: {value}'**
  String durationValue(String value);

  /// No description provided for @studyGuideOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the study guide.'**
  String get studyGuideOpenFailed;

  /// No description provided for @studyGuideRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting a study guide from completed transcripts...'**
  String get studyGuideRequesting;

  /// No description provided for @studyGuideAlreadyRequested.
  ///
  /// In en, this message translates to:
  /// **'A study guide has already been requested from the completed transcripts.'**
  String get studyGuideAlreadyRequested;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
