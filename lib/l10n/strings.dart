

import 'package:flutter/material.dart';

class SBStrings {
  final Locale locale;
  SBStrings(this.locale);

  /// Retrieves the localization instance for the given [context].
  ///
  /// This method normally looks up the nearest [Localizations] widget and
  /// returns the `SBStrings` instance provided by [SBStrings.delegate]. If no
  /// localization is found (which can happen if the widget tree has not yet
  /// inserted a [Localizations] for `SBStrings`), a default English instance
  /// is returned instead. This prevents crashes due to a null lookup while
  /// keeping the app functional until localization is properly wired. The
  /// fallback locale defaults to `'en'` but can be changed if needed.
  static SBStrings of(BuildContext context) {
    final strings = Localizations.of<SBStrings>(context, SBStrings);
    if (strings != null) {
      return strings;
    }
    // Fallback to English localization if no delegate has been registered yet.
    return SBStrings(const Locale('en'));
  }

  // -------------------------------------------------
  // Static localization info
  // -------------------------------------------------
  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  static const localeNames = {
    'en': 'English',
    'es': 'Español',
  };

  // Added delegate constant to expose the private _SBLocale delegate.
  static const LocalizationsDelegate<SBStrings> delegate = _SBLocale();

  // -------------------------------------------------
  // All localized text
  // -------------------------------------------------
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appTitle': 'Study Buddy Note',
      'library': 'Library',
      'record': 'Record',
      'stop': 'Stop',
      'settings': 'Settings',
      'close': 'Close',
      'signInWithGoogle': 'Sign in with Google',

      // Recording
      'recordingComplete': 'Recording complete',
      'recording': 'Recording...',
      'readyToRecord': 'Ready to record',
      'uploading': 'Uploading...',
      'chooseUploadOrDiscard': 'Choose: upload or discard',
      'recordingPaused': 'Recording paused',
      'tapRedToStop': 'Tap red to stop',
      'enterClassAndTopic': 'Enter class and topic',
      'selectClass': 'Select class',
      'enterNewClass': 'Enter new class',
      'lectureTopic': 'Lecture topic',
      'resume': 'Resume',
      'pause': 'Pause',
      'upload': 'Upload',
      'discard': 'Discard',
      'notSignedIn': 'Not signed in',
      'errorLoading': 'Error loading',
      'noRecordingsYet': 'No recordings yet',
      'noClassesMatch': 'No classes match',
      'noLecturesYet': 'No lectures yet',
      'transcript': 'Transcript',
      'playback': 'Playback',
      'couldNotOpenLink': 'Could not open link',
      'openInGoogleDrive': 'Open in Google Drive',
      'openFromFirebaseStorage': 'Open from Firebase Storage',
      'noPlaybackLinkAvailable': 'No playback link available',
      'transcriptStatus': 'Transcript status',
      'viewTranscript': 'View transcript',
      'transcriptIsEmpty': 'Transcript is empty',
      'transcriptError': 'Transcript error',
      'ok': 'OK',
      'requestTranscription': 'Request transcription',
      'transcriptionRequested': 'Transcription requested',
      'failed': 'Failed',
      'transcriptGoogleDrive': 'Transcript (Google Drive)',
      'fileId': 'File ID',
      'subtitlesGoogleDrive': 'Subtitles (Google Drive)',
      'aiOutputs': 'AI Outputs',
      'generateSummary': 'Generate summary',
      'generateNotes': 'Generate notes',
      'generatePracticeTest': 'Generate practice test',
      'status': 'Status',
      'view': 'View',
      'request': 'Request',
      'unknownUser': 'Unknown user',
      'language': 'Language',
      'autoTranscribeAfterUpload': 'Auto transcribe after upload',
      'autoGenerateNotes': 'Auto-generate notes',
      'logout': 'Logout',

      // Academic settings
      'academicSettingsTitle': 'Academic Settings',
      'selectAcademicLevel': 'Select your academic level',
      'selectTerm': 'Select current term',
      'saving': 'Saving...',
      'saveChanges': 'Save changes',
    },
    'es': {
      'appTitle': 'Study Buddy Note',
      'library': 'Biblioteca',
      'record': 'Grabar',
      'stop': 'Detener',
      'settings': 'Configuración',
      'close': 'Cerrar',
      'signInWithGoogle': 'Inicia sesión con Google',

      'recordingComplete': 'Grabación completada',
      'recording': 'Grabando...',
      'readyToRecord': 'Listo para grabar',
      'uploading': 'Subiendo...',
      'chooseUploadOrDiscard': 'Elige: subir o descartar',
      'recordingPaused': 'Grabación en pausa',
      'tapRedToStop': 'Toca el rojo para detener',
      'enterClassAndTopic': 'Ingresa clase y tema',
      'selectClass': 'Seleccionar clase',
      'enterNewClass': 'Ingresar nueva clase',
      'lectureTopic': 'Tema de la clase',
      'resume': 'Reanudar',
      'pause': 'Pausar',
      'upload': 'Subir',
      'discard': 'Descartar',
      'notSignedIn': 'No has iniciado sesión',
      'errorLoading': 'Error al cargar',
      'noRecordingsYet': 'Aún no hay grabaciones',
      'noClassesMatch': 'No hay clases coincidentes',
      'noLecturesYet': 'Aún no hay clases',
      'transcript': 'Transcripción',
      'playback': 'Reproducción',
      'couldNotOpenLink': 'No se pudo abrir el enlace',
      'openInGoogleDrive': 'Abrir en Google Drive',
      'openFromFirebaseStorage': 'Abrir desde Firebase Storage',
      'noPlaybackLinkAvailable': 'No hay enlace disponible',
      'transcriptStatus': 'Estado de transcripción',
      'viewTranscript': 'Ver transcripción',
      'transcriptIsEmpty': 'La transcripción está vacía',
      'transcriptError': 'Error de transcripción',
      'ok': 'Aceptar',
      'requestTranscription': 'Solicitar transcripción',
      'transcriptionRequested': 'Transcripción solicitada',
      'failed': 'Falló',
      'transcriptGoogleDrive': 'Transcripción (Google Drive)',
      'fileId': 'ID del archivo',
      'subtitlesGoogleDrive': 'Subtítulos (Google Drive)',
      'aiOutputs': 'Resultados de IA',
      'generateSummary': 'Generar resumen',
      'generateNotes': 'Generar notas',
      'generatePracticeTest': 'Generar prueba práctica',
      'status': 'Estado',
      'view': 'Ver',
      'request': 'Solicitar',
      'unknownUser': 'Usuario desconocido',
      'language': 'Idioma',
      'autoTranscribeAfterUpload': 'Transcribir automáticamente',
      'autoGenerateNotes': 'Generar notas automáticamente',
      'logout': 'Cerrar sesión',

      'academicSettingsTitle': 'Configuración Académica',
      'selectAcademicLevel': 'Selecciona tu nivel académico',
      'selectTerm': 'Selecciona el periodo actual',
      'saving': 'Guardando...',
      'saveChanges': 'Guardar cambios',
    },
  };

  String _t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
          _localizedValues['en']![key] ??
          key;

  // --- simple text getters ---
  String get appTitle => _t('appTitle');
  String get library => _t('library');
  String get record => _t('record');
  String get stop => _t('stop');
  String get settings => _t('settings');
  String get close => _t('close');
  String get signInWithGoogle => _t('signInWithGoogle');

  // Everything else:
  String get recordingComplete => _t('recordingComplete');
  String get recording => _t('recording');
  String get readyToRecord => _t('readyToRecord');
  String get uploading => _t('uploading');
  String get chooseUploadOrDiscard => _t('chooseUploadOrDiscard');
  String get recordingPaused => _t('recordingPaused');
  String get tapRedToStop => _t('tapRedToStop');
  String get enterClassAndTopic => _t('enterClassAndTopic');
  String get selectClass => _t('selectClass');
  String get enterNewClass => _t('enterNewClass');
  String get lectureTopic => _t('lectureTopic');
  String get resume => _t('resume');
  String get pause => _t('pause');
  String get upload => _t('upload');
  String get discard => _t('discard');
  String get notSignedIn => _t('notSignedIn');
  String get errorLoading => _t('errorLoading');
  String get noRecordingsYet => _t('noRecordingsYet');
  String get noClassesMatch => _t('noClassesMatch');
  String get noLecturesYet => _t('noLecturesYet');
  String get transcript => _t('transcript');
  String get playback => _t('playback');
  String get couldNotOpenLink => _t('couldNotOpenLink');
  String get openInGoogleDrive => _t('openInGoogleDrive');
  String get openFromFirebaseStorage => _t('openFromFirebaseStorage');
  String get noPlaybackLinkAvailable => _t('noPlaybackLinkAvailable');
  String get transcriptStatus => _t('transcriptStatus');
  String get viewTranscript => _t('viewTranscript');
  String get transcriptIsEmpty => _t('transcriptIsEmpty');
  String get transcriptError => _t('transcriptError');
  String get ok => _t('ok');
  String get requestTranscription => _t('requestTranscription');
  String get transcriptionRequested => _t('transcriptionRequested');
  String get failed => _t('failed');
  String get transcriptGoogleDrive => _t('transcriptGoogleDrive');
  String get fileId => _t('fileId');
  String get subtitlesGoogleDrive => _t('subtitlesGoogleDrive');
  String get aiOutputs => _t('aiOutputs');
  String get generateSummary => _t('generateSummary');
  String get generateNotes => _t('generateNotes');
  String get generatePracticeTest => _t('generatePracticeTest');
  String get status => _t('status');
  String get view => _t('view');
  String get request => _t('request');
  String get unknownUser => _t('unknownUser');
  String get language => _t('language');
  String get autoTranscribeAfterUpload => _t('autoTranscribeAfterUpload');
  String get autoGenerateNotes => _t('autoGenerateNotes');
  String get logout => _t('logout');

  // Academic
  String get academicSettingsTitle => _t('academicSettingsTitle');
  String get selectAcademicLevel => _t('selectAcademicLevel');
  String get selectTerm => _t('selectTerm');
  String get saving => _t('saving');
  String get saveChanges => _t('saveChanges');

  // --- dynamic replacements ---
  String uploadingTo(String phase) => '${_t("uploading")} $phase...';
  String lectureCount(int count) => 'Lectures: $count';
}

// Localization delegate
class _SBLocale extends LocalizationsDelegate<SBStrings> {
  const _SBLocale();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es'].contains(locale.languageCode);

  @override
  Future<SBStrings> load(Locale locale) async => SBStrings(locale);

  @override
  bool shouldReload(_SBLocale old) => false;
}
