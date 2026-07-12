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
}
