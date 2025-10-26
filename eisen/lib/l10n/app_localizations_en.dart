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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Toggle theme';

  @override
  String get settingsDensityCompact => 'Compact density';

  @override
  String get settingsDensityComfortable => 'Comfortable density';

  @override
  String get settingsMinimalMode => 'Minimal mode';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsResetDemo => 'Restore demo tasks';

  @override
  String get settingsResetDemoSubtitle => 'Replace all tasks with examples';

  @override
  String get settingsResetDemoDialogTitle => 'Restore demo tasks?';

  @override
  String get settingsResetDemoDialogContent =>
      'This will delete all your current tasks and replace them with 20 example tasks.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';
}
