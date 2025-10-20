// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Eisenhower Matrix';

  @override
  String get newTask => 'New task';

  @override
  String get searchHint => 'Search or filter by tag…';

  @override
  String get axisUrgent => 'Urgent';

  @override
  String get axisNotUrgent => 'Not urgent';

  @override
  String get axisImportant => 'Important';

  @override
  String get axisNotImportant => 'Not important';

  @override
  String get minimapDo => 'Do';

  @override
  String get minimapDecide => 'Decide';

  @override
  String get minimapDelegate => 'Delegate';

  @override
  String get minimapDelete => 'Delete';

  @override
  String get settingsShowAxisLegends => 'Show axis legends';
}
