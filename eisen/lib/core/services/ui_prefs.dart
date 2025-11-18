import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiPrefsData {
  const UiPrefsData({
    this.themeMode = ThemeMode.system,
    this.compact = false,
    this.showAxisLegends = true,
    this.minimal = false,
    this.topKPerQuadrant = 20,
    this.gamma = 1.0,
    this.minAreaNormalized = 0.00004,
    this.quadrantPadding = 0.012,
    this.languageCode = 'system',
    this.regionCode = 'system',
    this.dateFormat = 'dd/MM/yyyy',
    this.use24h = true,
    this.dailyReminderTime = '',
    this.endOfDaySummary = false,
    this.endOfDayTime = '',
    this.pomodoroAlert = 'sound',
    this.notificationTone = 'default',
    this.workflowPlanEnabled = false,
    this.textScaleLevel = 3,
    this.ganttTimeScale = 'weeks',
    this.ganttShowBadges = true,
    this.ganttCompactLanes = false,
    this.ganttWorkweekOnly = false,
    this.ganttShowTodayLine = true,
    this.densityPreset = 'auto', // 'auto' | 'comfy' | 'compact' | 'ultra'
    this.viewMode = 'treemap', // 'treemap' | 'list'
  });
  final ThemeMode themeMode;
  final bool compact;
  final bool showAxisLegends;
  final bool minimal;
  // Treemap layout settings
  final int topKPerQuadrant; // 5..100
  final double gamma; // 0.70..1.00
  final double minAreaNormalized; // 2e-5 .. 2e-4
  final double quadrantPadding; // 0.0 .. 0.02
  // General · Language & Region
  final String languageCode; // 'system' | 'en' | 'es' | ...
  final String regionCode; // 'system' | 'US' | 'MX' | ...
  final String dateFormat; // 'dd/MM/yyyy' | 'MM/dd/yyyy' | 'yyyy-MM-dd'
  final bool use24h; // true=24h, false=12h
  // General · Notifications
  final String dailyReminderTime; // 'HH:mm' 24h; '' = disabled
  final bool endOfDaySummary; // switch
  final String endOfDayTime; // 'HH:mm' or ''
  // Pomodoro alert channel: 'none' | 'sound' | 'visual'
  // Backwards‑compat note: legacy values 'silent' and 'vibration' are mapped
  // to 'none' and 'visual' respectively in [fromJson].
  final String pomodoroAlert;
  final String notificationTone; // 'default' | 'chime' | 'bell'
  // Workflow plan (show Gantt-like CTA in toolbar)
  final bool workflowPlanEnabled;
  // Typography · User text scale (1..5). 3 = default
  final int textScaleLevel;
  // Calendar/Gantt preferences
  final String ganttTimeScale; // 'days' | 'weeks' | 'months'
  final bool ganttShowBadges;
  final bool ganttCompactLanes;
  final bool ganttWorkweekOnly;
  final bool ganttShowTodayLine;
  // Density preset override for desktop layouts
  final String densityPreset; // 'auto' | 'comfy' | 'compact' | 'ultra'
  // Matrix view mode (desktop): treemap (default) or list (2x2)
  final String viewMode; // 'treemap' | 'list'

  UiPrefsData copyWith({
    ThemeMode? themeMode,
    bool? compact,
    bool? showAxisLegends,
    bool? minimal,
    int? topKPerQuadrant,
    double? gamma,
    double? minAreaNormalized,
    double? quadrantPadding,
    String? languageCode,
    String? regionCode,
    String? dateFormat,
    bool? use24h,
    String? dailyReminderTime,
    bool? endOfDaySummary,
    String? endOfDayTime,
    String? pomodoroAlert,
    String? notificationTone,
    bool? workflowPlanEnabled,
    int? textScaleLevel,
    String? ganttTimeScale,
    bool? ganttShowBadges,
    bool? ganttCompactLanes,
    bool? ganttWorkweekOnly,
    bool? ganttShowTodayLine,
    String? densityPreset,
    String? viewMode,
  }) =>
      UiPrefsData(
        themeMode: themeMode ?? this.themeMode,
        compact: compact ?? this.compact,
        showAxisLegends: showAxisLegends ?? this.showAxisLegends,
        minimal: minimal ?? this.minimal,
        topKPerQuadrant: topKPerQuadrant ?? this.topKPerQuadrant,
        gamma: gamma ?? this.gamma,
        minAreaNormalized: minAreaNormalized ?? this.minAreaNormalized,
        quadrantPadding: quadrantPadding ?? this.quadrantPadding,
        languageCode: languageCode ?? this.languageCode,
        regionCode: regionCode ?? this.regionCode,
        dateFormat: dateFormat ?? this.dateFormat,
        use24h: use24h ?? this.use24h,
        dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
        endOfDaySummary: endOfDaySummary ?? this.endOfDaySummary,
        endOfDayTime: endOfDayTime ?? this.endOfDayTime,
        pomodoroAlert: pomodoroAlert ?? this.pomodoroAlert,
        notificationTone: notificationTone ?? this.notificationTone,
        workflowPlanEnabled: workflowPlanEnabled ?? this.workflowPlanEnabled,
        textScaleLevel: textScaleLevel ?? this.textScaleLevel,
        ganttTimeScale: ganttTimeScale ?? this.ganttTimeScale,
        ganttShowBadges: ganttShowBadges ?? this.ganttShowBadges,
        ganttCompactLanes: ganttCompactLanes ?? this.ganttCompactLanes,
        ganttWorkweekOnly: ganttWorkweekOnly ?? this.ganttWorkweekOnly,
        ganttShowTodayLine: ganttShowTodayLine ?? this.ganttShowTodayLine,
        densityPreset: densityPreset ?? this.densityPreset,
        viewMode: viewMode ?? this.viewMode,
      );

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'compact': compact,
        'showAxisLegends': showAxisLegends,
        'minimal': minimal,
        'topKPerQuadrant': topKPerQuadrant,
        'gamma': gamma,
        'minAreaNormalized': minAreaNormalized,
        'quadrantPadding': quadrantPadding,
        'languageCode': languageCode,
        'regionCode': regionCode,
        'dateFormat': dateFormat,
        'use24h': use24h,
        'dailyReminderTime': dailyReminderTime,
        'endOfDaySummary': endOfDaySummary,
        'endOfDayTime': endOfDayTime,
        'pomodoroAlert': pomodoroAlert,
        'notificationTone': notificationTone,
        'workflowPlanEnabled': workflowPlanEnabled,
        'textScaleLevel': textScaleLevel,
        'ganttTimeScale': ganttTimeScale,
        'ganttShowBadges': ganttShowBadges,
        'ganttCompactLanes': ganttCompactLanes,
        'ganttWorkweekOnly': ganttWorkweekOnly,
        'ganttShowTodayLine': ganttShowTodayLine,
        'densityPreset': densityPreset,
        'viewMode': viewMode,
      };

  static UiPrefsData fromJson(Map<String, Object?> json) {
    final tm = switch (json['themeMode']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
    return UiPrefsData(
      themeMode: tm,
      compact: (json['compact'] as bool?) ?? false,
      showAxisLegends: (json['showAxisLegends'] as bool?) ?? true,
      minimal: (json['minimal'] as bool?) ?? false,
      topKPerQuadrant: (json['topKPerQuadrant'] as int?) ?? 20,
      gamma: (json['gamma'] is num) ? (json['gamma'] as num).toDouble() : 1.0,
      minAreaNormalized: (json['minAreaNormalized'] is num)
          ? (json['minAreaNormalized'] as num).toDouble()
          : 0.00004,
      quadrantPadding: (json['quadrantPadding'] is num)
          ? (json['quadrantPadding'] as num).toDouble()
          : 0.012,
      languageCode: (json['languageCode'] as String?) ?? 'system',
      regionCode: (json['regionCode'] as String?) ?? 'system',
      dateFormat: (json['dateFormat'] as String?) ?? 'dd/MM/yyyy',
      use24h: (json['use24h'] as bool?) ?? true,
      dailyReminderTime: (json['dailyReminderTime'] as String?) ?? '',
      endOfDaySummary: (json['endOfDaySummary'] as bool?) ?? false,
      endOfDayTime: (json['endOfDayTime'] as String?) ?? '',
      pomodoroAlert: (() {
        // Normalize legacy values to the new set: none | sound | visual.
        // Treat missing/null as 'sound' to preserve previous default.
        final raw = (json['pomodoroAlert'] as String?) ?? 'sound';
        switch (raw) {
          case 'none':
          case 'sound':
          case 'visual':
            return raw;
          case 'silent':
            return 'none';
          case 'vibration':
            return 'visual';
          default:
            return 'sound';
        }
      })(),
      notificationTone: (json['notificationTone'] as String?) ?? 'default',
      workflowPlanEnabled: (json['workflowPlanEnabled'] as bool?) ?? false,
      textScaleLevel: (json['textScaleLevel'] as int?) ?? 3,
      ganttTimeScale: (json['ganttTimeScale'] as String?) ?? 'weeks',
      ganttShowBadges: (json['ganttShowBadges'] as bool?) ?? true,
      ganttCompactLanes: (json['ganttCompactLanes'] as bool?) ?? false,
      ganttWorkweekOnly: (json['ganttWorkweekOnly'] as bool?) ?? false,
      ganttShowTodayLine: (json['ganttShowTodayLine'] as bool?) ?? true,
      densityPreset: (json['densityPreset'] as String?) ?? 'auto',
      viewMode: (json['viewMode'] as String?) ?? 'treemap',
    );
  }
}

class UiPrefs {
  static const _key = 'eisen.ui.v1';

  Future<UiPrefsData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const UiPrefsData();
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return UiPrefsData.fromJson(map);
      }
    } catch (_) {}
    return const UiPrefsData();
  }

  Future<void> save(UiPrefsData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}

// Riverpod controller + providers for UI prefs (layout sliders use this)
// Note: kept local to avoid creating a new file; integrates with existing storage.

class UiPrefsController extends Notifier<UiPrefsData> {
  late final UiPrefs _repo;

  @override
  UiPrefsData build() {
    _repo = UiPrefs();
    // load async and publish
    _init();
    return const UiPrefsData();
  }

  Future<void> _init() async {
    try {
      final loaded = await _repo.load();
      state = loaded;
    } catch (_) {}
  }

  Future<void> _save() => _repo.save(state);

  /// Overwrites all UI prefs at once and persists them.
  ///
  /// Used by higher-level Settings flows that stage changes before applying.
  Future<void> overwrite(UiPrefsData data) async {
    state = data;
    await _save();
  }

  Future<void> setTopK(int value) async {
    final v = value.clamp(5, 100);
    state = state.copyWith(topKPerQuadrant: v);
    await _save();
  }

  Future<void> setGamma(double value) async {
    final v = value.clamp(0.70, 1.0);
    state = state.copyWith(gamma: v);
    await _save();
  }

  Future<void> setMinArea(double value) async {
    final v = value.clamp(0.00002, 0.0002);
    state = state.copyWith(minAreaNormalized: v);
    await _save();
  }

  Future<void> setPadding(double value) async {
    final v = value.clamp(0.0, 0.02);
    state = state.copyWith(quadrantPadding: v);
    await _save();
  }

  /// Apply multiple layout-related preferences in a single save.
  Future<void> applyLayoutPrefs({
    required int topKPerQuadrant,
    required double gamma,
    required double minAreaNormalized,
    required double quadrantPadding,
  }) async {
    final k = topKPerQuadrant.clamp(5, 100);
    final g = gamma.clamp(0.70, 1.0);
    final minA = minAreaNormalized.clamp(0.00002, 0.0002);
    final pad = quadrantPadding.clamp(0.0, 0.02);
    state = state.copyWith(
      topKPerQuadrant: k,
      gamma: g,
      minAreaNormalized: minA,
      quadrantPadding: pad,
    );
    await _save();
  }

  // Language & Region setters
  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    await _save();
  }

  Future<void> setRegionCode(String code) async {
    state = state.copyWith(regionCode: code);
    await _save();
  }

  Future<void> setDateFormat(String fmt) async {
    state = state.copyWith(dateFormat: fmt);
    await _save();
  }

  Future<void> setUse24h(bool v) async {
    state = state.copyWith(use24h: v);
    await _save();
  }

  // Notifications setters
  Future<void> setDailyReminderTime(String hhmm) async {
    state = state.copyWith(dailyReminderTime: hhmm);
    await _save();
  }

  Future<void> setEndOfDaySummary(bool v) async {
    state = state.copyWith(endOfDaySummary: v);
    await _save();
  }

  Future<void> setEndOfDayTime(String hhmm) async {
    state = state.copyWith(endOfDayTime: hhmm);
    await _save();
  }

  Future<void> setPomodoroAlert(String mode) async {
    state = state.copyWith(pomodoroAlert: mode);
    await _save();
  }

  Future<void> setNotificationTone(String tone) async {
    state = state.copyWith(notificationTone: tone);
    await _save();
  }

  Future<void> setWorkflowPlanEnabled(bool v) async {
    state = state.copyWith(workflowPlanEnabled: v);
    await _save();
  }

  // Text scale
  Future<void> setTextScaleLevel(int level) async {
    final v = level.clamp(1, 5);
    state = state.copyWith(textScaleLevel: v);
    await _save();
  }

  // Density preset override
  Future<void> setDensityPreset(String preset) async {
    const allowed = {'auto', 'comfy', 'compact', 'ultra'};
    final p = allowed.contains(preset) ? preset : 'auto';
    state = state.copyWith(densityPreset: p);
    await _save();
  }

  // View mode override (treemap | list)
  Future<void> setViewMode(String mode) async {
    const allowed = {'treemap', 'list'};
    final m = allowed.contains(mode) ? mode : 'treemap';
    state = state.copyWith(viewMode: m);
    await _save();
  }

  // Calendar/Gantt setters
  Future<void> applyGanttPrefs({
    required String timeScale, // 'days' | 'weeks' | 'months'
    required bool showBadges,
    required bool compactLanes,
    required bool workweekOnly,
    required bool showTodayLine,
  }) async {
    // sanitize
    final allowed = {'days', 'weeks', 'months'};
    final ts = allowed.contains(timeScale) ? timeScale : 'weeks';
    state = state.copyWith(
      ganttTimeScale: ts,
      ganttShowBadges: showBadges,
      ganttCompactLanes: compactLanes,
      ganttWorkweekOnly: workweekOnly,
      ganttShowTodayLine: showTodayLine,
    );
    await _save();
  }
}

final uiPrefsControllerProvider =
    NotifierProvider<UiPrefsController, UiPrefsData>(UiPrefsController.new);

// Convenience provider alias to watch prefs data
final uiPrefsProvider =
    Provider<UiPrefsData>((ref) => ref.watch(uiPrefsControllerProvider));
