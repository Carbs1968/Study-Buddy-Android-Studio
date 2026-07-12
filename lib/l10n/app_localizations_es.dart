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
}
