// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Study Buddy';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get profile => 'Perfil';

  @override
  String get save => 'Guardar';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get language => 'Idioma';

  @override
  String get school => 'Escuela / Universidad';

  @override
  String get accountType => 'Tipo de cuenta';

  @override
  String get freemium => 'Freemium';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get loading => 'Cargando...';

  @override
  String get academicSettingsTitle => 'Configuración académica';

  @override
  String get academicLevelYear => 'Nivel académico / año';

  @override
  String get academicLevelYearHint =>
      'Ejemplos: Preparatoria, Primaria, Secundaria, Año 2';

  @override
  String get academicLevelYearHelp =>
      'Ingresa el nivel o año tal como se usa en tu sistema escolar.';

  @override
  String get currentSemesterTerm => 'Semestre / periodo actual';

  @override
  String get currentSemesterTermHint =>
      'Ejemplos: Otoño 2026, 5.º semestre, Periodo 1';

  @override
  String get currentSemesterTermHelp =>
      'Ingresa el semestre, trimestre, periodo o ciclo que cursas actualmente.';

  @override
  String get academicSettingsLoadFailed =>
      'No se pudo cargar la configuración académica.';

  @override
  String get academicSettingsRequired =>
      'Ingresa el nivel académico y el semestre.';

  @override
  String get academicSettingsSaved =>
      'La configuración académica se guardó correctamente.';

  @override
  String get academicSettingsSaveFailed =>
      'No se pudo guardar la configuración académica.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get saving => 'Guardando...';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get chooseAppLanguage => 'Elige el idioma de la aplicación.';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get notSet => 'No configurado';

  @override
  String get currentAcademicPeriod => 'Periodo académico actual';

  @override
  String get academicYear => 'Año académico';

  @override
  String get semester => 'Semestre';

  @override
  String get manageAcademicSettings => 'Administrar configuración académica';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsAndConditions => 'Términos y condiciones';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get linkOpenFailed =>
      'No se pudo abrir el enlace. Inténtalo de nuevo.';

  @override
  String get deleteAccountTitle => '¿Eliminar tu cuenta permanentemente?';

  @override
  String get deleteAccountIntro =>
      'Esto eliminará permanentemente tu cuenta de Study Buddy y todos los datos asociados, incluidos:';

  @override
  String get deleteAccountAcademicData =>
      '• Años académicos, semestres, clases y temas';

  @override
  String get deleteAccountFiles => '• Grabaciones y archivos subidos';

  @override
  String get deleteAccountAiData =>
      '• Transcripciones, resúmenes, notas, cuestionarios y guías de estudio';

  @override
  String get deleteAccountProfileData =>
      '• Información de la cuenta y del perfil';

  @override
  String get deleteAccountWarning => 'Esta acción no se puede deshacer.';

  @override
  String deleteAccountTypeToken(String token) {
    return 'Para continuar, escribe $token a continuación:';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get deleteAccountPermanently => 'Eliminar mi cuenta permanentemente';

  @override
  String get deletingAccount => 'Eliminando tu cuenta y tus datos…';

  @override
  String get deleteAccountFailed =>
      'No pudimos eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String get unknownUser => 'Usuario desconocido';

  @override
  String get loginTagline => 'Graba y organiza tus clases.';

  @override
  String get unableToOpenPage =>
      'No se pudo abrir esta página. Inténtalo de nuevo.';

  @override
  String get signInCanceled => 'Se canceló el inicio de sesión.';

  @override
  String get signInFailed => 'No pudimos iniciar sesión. Inténtalo de nuevo.';

  @override
  String get legalAgreementPrefix => 'Al continuar, aceptas nuestros ';

  @override
  String get legalAgreementMiddle => ' y reconoces nuestra ';

  @override
  String get openClassOrTopicBeforeUpload =>
      'Abre una clase o un tema antes de subir material de estudio.';

  @override
  String get dashboard => 'Inicio';

  @override
  String get record => 'Grabar';

  @override
  String get library => 'Biblioteca';

  @override
  String get settings => 'Configuración';

  @override
  String get dashboardSubtitle =>
      'Tu espacio de estudio, organizado por clase y tema.';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get startNewRecordingDescription =>
      'Inicia una nueva grabación de clase.';

  @override
  String get uploadStudyMaterial => 'Subir material de estudio';

  @override
  String get chooseClassOrTopicBeforeUpload =>
      'Elige una clase o un tema antes de subir archivos.';

  @override
  String get recentClasses => 'Clases recientes';

  @override
  String get academicContext => 'Contexto académico';

  @override
  String get academicStructure => 'Año → Semestre → Clase → Tema';

  @override
  String get recentClassesLoadFailed =>
      'No se pudieron cargar las clases recientes';

  @override
  String get checkConnectionTryAgain =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get loadingRecentClasses => 'Cargando clases recientes';

  @override
  String get checkingLatestStudyActivity =>
      'Buscando tu actividad de estudio más reciente...';

  @override
  String get recentClassesEmptyTitle => 'Tus clases recientes aparecerán aquí';

  @override
  String get recentClassesEmptyMessage =>
      'Graba una sesión de clase para ver aquí tu actividad de estudio más reciente.';

  @override
  String get libraryEmptyMessage =>
      'Graba una clase desde la pestaña Grabar para crear tu Biblioteca.';

  @override
  String get librarySearchEmptyMessage =>
      'Prueba con otro nombre de clase o borra la búsqueda.';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String latestDate(String date) {
    return 'Más reciente: $date';
  }

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
      zero: 'Sin sesiones',
    );
    return '$_temp0';
  }

  @override
  String lectureCountGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clases grabadas',
      one: '1 clase grabada',
      zero: 'Sin clases grabadas',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get libraryLoadFailed =>
      'No se pudo cargar tu Biblioteca. Inténtalo de nuevo.';

  @override
  String get notSignedIn => 'No has iniciado sesión.';

  @override
  String get selectClass => 'Selecciona una clase';

  @override
  String get errorLoading => 'Error al cargar';

  @override
  String get noRecordingsYet => 'Aún no hay grabaciones';

  @override
  String get noClassesMatch => 'Ninguna clase coincide con tu búsqueda';

  @override
  String get loadingAcademicSettings =>
      'Cargando la configuración académica...';

  @override
  String get saveDestination => 'Destino de guardado';

  @override
  String academicYearLevelValue(String value) {
    return 'Año académico / nivel: $value';
  }

  @override
  String semesterValue(String value) {
    return 'Semestre: $value';
  }

  @override
  String get newClassLabel => 'O ingresa una clase nueva';

  @override
  String get newClassHelper => 'Usa esta opción si la clase aún no aparece.';

  @override
  String get topicLectureName => 'Nombre del tema / clase';

  @override
  String get topicLectureExample =>
      'Ejemplo: Repaso para examen o notas del capítulo 4.';

  @override
  String get recordingSavedLocally =>
      'La grabación se guardó localmente. Súbela a Study Buddy o descarta esta copia local.';

  @override
  String get recordingComplete => 'Grabación completada';

  @override
  String get recording => 'Grabando';

  @override
  String get readyToRecord => 'Listo para grabar';

  @override
  String get uploading => 'Subiendo...';

  @override
  String get chooseUploadOrDiscard => 'Elige subir o descartar';

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Detener';

  @override
  String get upload => 'Subir';

  @override
  String get discard => 'Descartar';

  @override
  String uploadingTo(String destination) {
    return 'Subiendo a $destination';
  }

  @override
  String get recordingStartFailed =>
      'No se pudo iniciar la grabación. Inténtalo de nuevo.';

  @override
  String get recordingDidNotStart => 'La grabación no se inició.';

  @override
  String get pauseResumeFailed =>
      'No se pudo pausar o reanudar la grabación. Inténtalo de nuevo.';

  @override
  String get recordingBackendUnknown =>
      'Los controles de grabación no están disponibles porque no se pudo confirmar el estado de la grabación.';

  @override
  String get recordingStopUnconfirmed =>
      'No se pudo confirmar que la grabación se detuvo. Inténtalo de nuevo antes de salir de esta pantalla.';

  @override
  String get uploadCompleteReady =>
      'La carga se completó. ¡Todo listo para tu próxima clase!';

  @override
  String get uploadFailedSafe =>
      'No se pudo subir la grabación. Inténtalo de nuevo.';

  @override
  String get recordingCorrupt =>
      'La grabación parece estar vacía o dañada. Graba de nuevo.';

  @override
  String get academicSettingsRequiredBeforeRecording =>
      'Guarda tu nivel académico y semestre en Configuración académica antes de grabar.';

  @override
  String get recordingRecoveredPartial =>
      'Parece que la grabación se detuvo. El audio recuperado puede estar incompleto.';

  @override
  String get recoveredRecordingSmall =>
      'Se recuperó una grabación pendiente, pero parece ser inusualmente pequeña. Puedes intentar subirla o descartarla.';

  @override
  String get recordingRecoveryMissing =>
      'Parece que la grabación se detuvo, pero no se encontró ningún archivo de audio recuperable.';

  @override
  String get microphonePermissionDenied =>
      'Se denegó el permiso del micrófono.';

  @override
  String get fileMissing => 'Falta el archivo de la grabación.';

  @override
  String get classTopicRequiredBeforeUpload =>
      'Ingresa una clase y un tema antes de subir la grabación.';

  @override
  String get chooseExistingClass => 'Elige una clase existente';

  @override
  String get recordingsOrganizedByClass =>
      'Las grabaciones se organizan por clase.';

  @override
  String get chooseClassAndTopicToRecord =>
      'Elige una clase e ingresa un tema para comenzar a grabar.';

  @override
  String get recordingPausedHelp =>
      'Grabación pausada. Toca Reanudar para continuar. Tu grabación sigue guardada.';
}
