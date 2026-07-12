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

  @override
  String get recordingContinuesWhenLocked =>
      'La grabación continúa aunque se bloquee la pantalla.';

  @override
  String get transcriptReady => 'Lista';

  @override
  String get transcriptProcessing => 'Procesando';

  @override
  String get transcriptQueued => 'En cola';

  @override
  String get transcriptFailed => 'Error';

  @override
  String get noTranscript => 'Sin transcripción';

  @override
  String get aiProcessing => 'IA: Procesando';

  @override
  String aiOutputsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados listos',
      one: '1 resultado listo',
    );
    return 'IA: $_temp0';
  }

  @override
  String get aiSummaryReady => 'IA: Resumen listo';

  @override
  String get aiNotesReady => 'IA: Notas listas';

  @override
  String get aiQuizReady => 'IA: Prueba lista';

  @override
  String get aiFailed => 'IA: Error';

  @override
  String get aiNotStarted => 'IA: No iniciada';

  @override
  String get generateStudyGuideTooltip =>
      'Generar guía de estudio a partir de las grabaciones';

  @override
  String get materialsTooltip => 'Materiales';

  @override
  String get studyGuideRequestFailed =>
      'No se pudo solicitar la guía de estudio. Inténtalo de nuevo.';

  @override
  String get studyGuideRequested => 'Se solicitó la guía de estudio.';

  @override
  String get studyGuideReused => 'Se abrió la guía de estudio existente.';

  @override
  String get studyGuideOpened => 'Se abrió la guía de estudio.';

  @override
  String get studyGuideUnavailable =>
      'La guía de estudio aún no está disponible.';

  @override
  String get classLecturesLoadFailed =>
      'No se pudieron cargar las grabaciones de la clase. Inténtalo de nuevo.';

  @override
  String get lectureTopic => 'Tema de la clase';

  @override
  String get noLecturesYet => 'Aún no hay grabaciones';

  @override
  String durationValue(String value) {
    return 'Duración: $value';
  }

  @override
  String get studyGuideOpenFailed => 'No se pudo abrir la guía de estudio.';

  @override
  String get studyGuideRequesting =>
      'Solicitando una guía de estudio a partir de las transcripciones completadas...';

  @override
  String get studyGuideAlreadyRequested =>
      'Ya se solicitó una guía de estudio a partir de las transcripciones completadas.';

  @override
  String get close => 'Cerrar';

  @override
  String get transcript => 'Transcripción';

  @override
  String get playback => 'Reproducción';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get openFromFirebaseStorage => 'Abrir desde Firebase Storage';

  @override
  String get noPlaybackLinkAvailable =>
      'No hay un enlace de reproducción disponible.';

  @override
  String get viewTranscript => 'Ver transcripción';

  @override
  String get transcriptIsEmpty => 'La transcripción está vacía.';

  @override
  String get transcriptError => 'Error de transcripción';

  @override
  String get ok => 'Aceptar';

  @override
  String get requestTranscription => 'Solicitar transcripción';

  @override
  String get transcriptionRequested => 'Transcripción solicitada.';

  @override
  String get aiOutputs => 'Resultados de IA';

  @override
  String get generateSummary => 'Generar resumen';

  @override
  String get generateNotes => 'Generar notas';

  @override
  String get generatePracticeTest => 'Generar prueba práctica';

  @override
  String get status => 'Estado';

  @override
  String get view => 'Ver';

  @override
  String get request => 'Solicitar';

  @override
  String levelValue(String value) {
    return 'Nivel: $value';
  }

  @override
  String fileValue(String value) {
    return 'Archivo: $value';
  }

  @override
  String transcriptStatusValue(String value) {
    return 'Estado de la transcripción: $value';
  }

  @override
  String statusValue(String value) {
    return 'Estado: $value';
  }

  @override
  String get transcriptionRequiredForAi =>
      'La transcripción debe estar lista antes de generar un resumen, notas o una prueba práctica.';

  @override
  String get requestTranscriptionFailed =>
      'No se pudo solicitar la transcripción. Inténtalo de nuevo.';

  @override
  String get lectureDetailLoadFailed => 'No se pudo cargar esta clase.';

  @override
  String get aiReady => 'Listo';

  @override
  String get aiQueued => 'En cola';

  @override
  String get aiNotStartedLabel => 'No iniciado';

  @override
  String get noAiOutputTitle => 'Aún no hay resultados';

  @override
  String get noAiOutputMessage =>
      'El resultado de IA está vacío o no está disponible.';

  @override
  String get copiedJsonToClipboard => 'JSON copiado al portapapeles';

  @override
  String get copy => 'Copiar';

  @override
  String get aiOutputError => 'Error del resultado de IA';

  @override
  String get aiOutputLoadFailed => 'No se pudo cargar el resultado de IA.';

  @override
  String get keyPoints => 'Puntos clave';

  @override
  String get terms => 'Términos';

  @override
  String get equations => 'Ecuaciones';

  @override
  String get references => 'Referencias';

  @override
  String answerValue(String value) {
    return 'Respuesta: $value';
  }

  @override
  String whyValue(String value) {
    return 'Por qué: $value';
  }

  @override
  String get transcriptLoadFailed => 'No se pudo cargar la transcripción.';

  @override
  String materialsTitle(String className) {
    return 'Materiales de $className';
  }

  @override
  String get materialTypeImage => 'Imagen';

  @override
  String get materialTypePdf => 'PDF';

  @override
  String get materialTypeSpreadsheet => 'Hoja de cálculo';

  @override
  String get materialTypePresentation => 'Presentación';

  @override
  String get materialTypeDocument => 'Documento';

  @override
  String get materialTypeText => 'Texto';

  @override
  String get materialTypeFile => 'Archivo';

  @override
  String materialAddedDate(String date) {
    return 'Agregado el $date';
  }

  @override
  String get materialUploaded => 'Material subido a esta clase.';

  @override
  String get materialUploadFailed => 'La carga falló. Inténtalo de nuevo.';

  @override
  String get selectedFileUnavailable =>
      'No se pudo acceder al archivo seleccionado.';

  @override
  String get addImage => 'Agregar imagen';

  @override
  String get addImageDescription => 'Sube una foto o imagen desde tu galería.';

  @override
  String get addFile => 'Agregar archivo';

  @override
  String get addFileDescription =>
      'PDF, Word, PowerPoint, Excel, TXT o CSV. Los archivos TXT y CSV se pueden extraer para las guías de estudio.';

  @override
  String get addMaterial => 'Agregar material';

  @override
  String get couldNotLoadMaterials =>
      'No se pudieron cargar los materiales de la clase.';

  @override
  String get noClassMaterials => 'Aún no hay materiales de clase';

  @override
  String get noClassMaterialsDescription =>
      'Agrega aquí imágenes de apuntes, hojas de trabajo, PDF o documentos.';

  @override
  String get materialFallbackName => 'Material';

  @override
  String get deleteMaterialTitle => '¿Eliminar material?';

  @override
  String get deleteMaterialMessage =>
      'Esto eliminará el material de esta clase y borrará el archivo subido.';

  @override
  String get deleteMaterialTooltip => 'Eliminar material';

  @override
  String get deleteFailed => 'No se pudo eliminar. Inténtalo de nuevo.';

  @override
  String get delete => 'Eliminar';

  @override
  String get imageLoadFailed => 'No se pudo cargar la imagen.';

  @override
  String get docxPreviewFailed =>
      'No se pudo obtener la vista previa del archivo DOCX.';

  @override
  String get docxNoReadableText =>
      'No se encontró texto legible en este archivo DOCX.';

  @override
  String get unknownSize => 'Tamaño desconocido';

  @override
  String materialTypeValue(String value) {
    return 'Tipo: $value';
  }

  @override
  String materialSizeValue(String value) {
    return 'Tamaño: $value';
  }

  @override
  String get materialPreviewUnavailable =>
      'Este archivo está guardado como material de la clase. La vista previa aún no está disponible para este tipo de archivo.';

  @override
  String get materialDeleted => 'Material eliminado.';

  @override
  String classStudyGuideTitle(String className) {
    return 'Guía de estudio de $className';
  }

  @override
  String get studyGuideLoadFailed => 'No se pudo cargar la guía de estudio.';

  @override
  String get studyGuideNotFound => 'No se encontró la guía de estudio.';

  @override
  String get generatedFromTranscriptsAndMaterials =>
      'Generada a partir de transcripciones completadas y materiales extraídos de la clase.';

  @override
  String get generatedFromTranscripts =>
      'Generada a partir de transcripciones completadas de la clase.';

  @override
  String get classStudyGuideFallbackTitle => 'Guía de estudio de la clase';

  @override
  String get keyTopics => 'Temas clave';

  @override
  String get studySections => 'Secciones de estudio';

  @override
  String get reviewQuestions => 'Preguntas de repaso';

  @override
  String get aiSummaryTitle => 'Resumen de IA';

  @override
  String get aiNotesTitle => 'Notas de IA';

  @override
  String get aiQuizTitle => 'Prueba práctica de IA';

  @override
  String get readyToRecordDescription =>
      'Listo para grabar. Esta clase se guardará en la clase y el tema seleccionados.';
}
