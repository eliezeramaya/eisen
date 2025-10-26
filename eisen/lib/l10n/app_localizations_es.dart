// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Matriz de Eisenhower';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get searchHint => 'Buscar o filtrar por etiqueta…';

  @override
  String get axisUrgent => 'Urgente';

  @override
  String get axisNotUrgent => 'No urgente';

  @override
  String get axisImportant => 'Importante';

  @override
  String get axisNotImportant => 'No importante';

  @override
  String get minimapDo => 'Hacer';

  @override
  String get minimapDecide => 'Decidir';

  @override
  String get minimapDelegate => 'Delegar';

  @override
  String get minimapDelete => 'Borrar';

  @override
  String get settingsShowAxisLegends => 'Mostrar leyendas de ejes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsTheme => 'Cambiar tema';

  @override
  String get settingsDensityCompact => 'Densidad compacta';

  @override
  String get settingsDensityComfortable => 'Densidad cómoda';

  @override
  String get settingsMinimalMode => 'Modo minimalista';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsResetDemo => 'Restaurar tareas demo';

  @override
  String get settingsResetDemoSubtitle =>
      'Reemplazar todas las tareas con ejemplos';

  @override
  String get settingsResetDemoDialogTitle => '¿Restaurar tareas demo?';

  @override
  String get settingsResetDemoDialogContent =>
      'Esto eliminará todas tus tareas actuales y las reemplazará con 20 tareas de ejemplo.';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';
}
