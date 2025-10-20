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
}
