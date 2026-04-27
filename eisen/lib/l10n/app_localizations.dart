import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Eisenhower Matrix'**
  String get appTitle;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search or filter by tag…'**
  String get searchHint;

  /// No description provided for @axisUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get axisUrgent;

  /// No description provided for @axisNotUrgent.
  ///
  /// In en, this message translates to:
  /// **'Not urgent'**
  String get axisNotUrgent;

  /// No description provided for @axisImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get axisImportant;

  /// No description provided for @axisNotImportant.
  ///
  /// In en, this message translates to:
  /// **'Not important'**
  String get axisNotImportant;

  /// No description provided for @minimapDo.
  ///
  /// In en, this message translates to:
  /// **'Do'**
  String get minimapDo;

  /// No description provided for @minimapDecide.
  ///
  /// In en, this message translates to:
  /// **'Decide'**
  String get minimapDecide;

  /// No description provided for @minimapDelegate.
  ///
  /// In en, this message translates to:
  /// **'Delegate'**
  String get minimapDelegate;

  /// No description provided for @minimapDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get minimapDelete;

  /// No description provided for @settingsShowAxisLegends.
  ///
  /// In en, this message translates to:
  /// **'Show axis legends'**
  String get settingsShowAxisLegends;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get settingsTheme;

  /// No description provided for @settingsDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact density'**
  String get settingsDensityCompact;

  /// No description provided for @settingsDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable density'**
  String get settingsDensityComfortable;

  /// No description provided for @settingsMinimalMode.
  ///
  /// In en, this message translates to:
  /// **'Minimal mode'**
  String get settingsMinimalMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsResetDemo.
  ///
  /// In en, this message translates to:
  /// **'Restore demo tasks'**
  String get settingsResetDemo;

  /// No description provided for @settingsResetDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all tasks with a rich sample dataset'**
  String get settingsResetDemoSubtitle;

  /// No description provided for @settingsResetDemoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore demo tasks?'**
  String get settingsResetDemoDialogTitle;

  /// No description provided for @settingsResetDemoDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your current tasks and replace them with 100 example tasks with richer metadata.'**
  String get settingsResetDemoDialogContent;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @focusModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get focusModeTitle;

  /// No description provided for @focusSessionType.
  ///
  /// In en, this message translates to:
  /// **'Session type'**
  String get focusSessionType;

  /// No description provided for @focusDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get focusDuration;

  /// No description provided for @focusDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the block length'**
  String get focusDurationSubtitle;

  /// No description provided for @focusPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get focusPomodoro;

  /// No description provided for @focusDeepWork.
  ///
  /// In en, this message translates to:
  /// **'Deep Work'**
  String get focusDeepWork;

  /// No description provided for @focusSprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get focusSprint;

  /// No description provided for @focusLinkedTask.
  ///
  /// In en, this message translates to:
  /// **'Linked task'**
  String get focusLinkedTask;

  /// No description provided for @focusLinkedTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: assign the session to a task'**
  String get focusLinkedTaskSubtitle;

  /// No description provided for @focusNoTaskLinked.
  ///
  /// In en, this message translates to:
  /// **'No task linked'**
  String get focusNoTaskLinked;

  /// No description provided for @focusSessionsCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Sessions completed today'**
  String get focusSessionsCompletedToday;

  /// No description provided for @workflowPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Workflow plan'**
  String get workflowPlanTitle;

  /// No description provided for @workflowPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline of your tasks'**
  String get workflowPlanSubtitle;

  /// No description provided for @telemetryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Improve Eisen'**
  String get telemetryDialogTitle;

  /// No description provided for @telemetryDialogWhatWeCollect.
  ///
  /// In en, this message translates to:
  /// **'What we collect:'**
  String get telemetryDialogWhatWeCollect;

  /// No description provided for @telemetryDialogWhatWeDontCollect.
  ///
  /// In en, this message translates to:
  /// **'What we DON\'T collect:'**
  String get telemetryDialogWhatWeDontCollect;

  /// No description provided for @telemetryDialogItemPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance metrics'**
  String get telemetryDialogItemPerformance;

  /// No description provided for @telemetryDialogItemFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature usage (anonymized)'**
  String get telemetryDialogItemFeature;

  /// No description provided for @telemetryDialogItemCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get telemetryDialogItemCrash;

  /// No description provided for @telemetryDialogItemNoContent.
  ///
  /// In en, this message translates to:
  /// **'Task content or titles'**
  String get telemetryDialogItemNoContent;

  /// No description provided for @telemetryDialogItemNoPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get telemetryDialogItemNoPersonal;

  /// No description provided for @telemetryDialogItemNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location data'**
  String get telemetryDialogItemNoLocation;

  /// No description provided for @telemetryDialogDecline.
  ///
  /// In en, this message translates to:
  /// **'No Thanks'**
  String get telemetryDialogDecline;

  /// No description provided for @telemetryDialogAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get telemetryDialogAccept;

  /// No description provided for @notificationDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus today'**
  String get notificationDailyReminderTitle;

  /// No description provided for @notificationDailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Remember to plan your day'**
  String get notificationDailyReminderBody;

  /// No description provided for @notificationDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get notificationDailySummaryTitle;

  /// No description provided for @notificationDailySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Review your progress'**
  String get notificationDailySummaryBody;

  /// No description provided for @addTaskQuadrant.
  ///
  /// In en, this message translates to:
  /// **'Quadrant:'**
  String get addTaskQuadrant;

  /// No description provided for @addTaskSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addTaskSave;

  /// No description provided for @addTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get addTaskAdded;

  /// No description provided for @settingsAppearanceThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceThemeTitle;

  /// No description provided for @settingsAppearanceThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light / Dark / System'**
  String get settingsAppearanceThemeSubtitle;

  /// No description provided for @settingsAppearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsAppearanceLight;

  /// No description provided for @settingsAppearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsAppearanceDark;

  /// No description provided for @settingsAppearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsAppearanceSystem;

  /// No description provided for @settingsAppearanceDensityTitle.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsAppearanceDensityTitle;

  /// No description provided for @settingsAppearanceDensitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfy / Compact / Ultra / Auto'**
  String get settingsAppearanceDensitySubtitle;

  /// No description provided for @settingsAppearanceDensityComfy.
  ///
  /// In en, this message translates to:
  /// **'Comfy'**
  String get settingsAppearanceDensityComfy;

  /// No description provided for @settingsAppearanceDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsAppearanceDensityCompact;

  /// No description provided for @settingsAppearanceDensityUltra.
  ///
  /// In en, this message translates to:
  /// **'Ultra'**
  String get settingsAppearanceDensityUltra;

  /// No description provided for @settingsAppearanceDensityAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsAppearanceDensityAuto;

  /// No description provided for @settingsPreviewNotActive.
  ///
  /// In en, this message translates to:
  /// **'Preview not active'**
  String get settingsPreviewNotActive;

  /// No description provided for @settingsPreviewEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Preview changes\" in Layout to see live effects.'**
  String get settingsPreviewEnable;

  /// No description provided for @settingsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsPreviewTitle;

  /// No description provided for @filtersAddEdit.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit filters'**
  String get filtersAddEdit;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters (categories)'**
  String get filtersTitle;

  /// No description provided for @filtersClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get filtersClose;

  /// No description provided for @settingsGeneralLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get settingsGeneralLanguageTitle;

  /// No description provided for @settingsGeneralLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, region and date/time formats'**
  String get settingsGeneralLanguageSubtitle;

  /// No description provided for @settingsGeneralTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Text & Readability'**
  String get settingsGeneralTextTitle;

  /// No description provided for @settingsGeneralTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text scale and readability'**
  String get settingsGeneralTextSubtitle;

  /// No description provided for @settingsGeneralNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsGeneralNotificationsTitle;

  /// No description provided for @settingsGeneralNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders and alerts'**
  String get settingsGeneralNotificationsSubtitle;

  /// No description provided for @settingsGeneralWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get settingsGeneralWorkflowTitle;

  /// No description provided for @settingsGeneralWorkflowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable work plan mode'**
  String get settingsGeneralWorkflowSubtitle;

  /// No description provided for @settingsGeneral24HourTitle.
  ///
  /// In en, this message translates to:
  /// **'24-hour time'**
  String get settingsGeneral24HourTitle;

  /// No description provided for @settingsGeneral24HourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use 24h format for time'**
  String get settingsGeneral24HourSubtitle;

  /// No description provided for @settingsGeneralTextScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsGeneralTextScaleTitle;

  /// No description provided for @settingsGeneralTextScaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust text scale throughout the app (1–5).'**
  String get settingsGeneralTextScaleSubtitle;

  /// No description provided for @settingsGeneralDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsGeneralDailyReminderTitle;

  /// No description provided for @settingsGeneralDailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to plan your focus in the morning'**
  String get settingsGeneralDailyReminderSubtitle;

  /// No description provided for @settingsGeneralEndOfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'End of day summary'**
  String get settingsGeneralEndOfDayTitle;

  /// No description provided for @settingsGeneralEndOfDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your daily progress'**
  String get settingsGeneralEndOfDaySubtitle;

  /// No description provided for @importanceDeadlineSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get importanceDeadlineSoon;

  /// No description provided for @importanceFocusTime.
  ///
  /// In en, this message translates to:
  /// **'You\'ve spent time on this'**
  String get importanceFocusTime;

  /// No description provided for @importanceTopThree.
  ///
  /// In en, this message translates to:
  /// **'Chosen in your check-in'**
  String get importanceTopThree;

  /// No description provided for @importanceContextFit.
  ///
  /// In en, this message translates to:
  /// **'Matches your focus schedule'**
  String get importanceContextFit;

  /// No description provided for @importanceWeeklyBalance.
  ///
  /// In en, this message translates to:
  /// **'Suggested for weekly balance'**
  String get importanceWeeklyBalance;

  /// No description provided for @pomodoroPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroPageTitle;

  /// No description provided for @pomodoroPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro timer (coming soon)'**
  String get pomodoroPageSubtitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
