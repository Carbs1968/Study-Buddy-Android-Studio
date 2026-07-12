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
}
