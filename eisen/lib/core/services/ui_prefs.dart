import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiPrefsData {
  final ThemeMode themeMode;
  final bool compact;
  final bool showAxisLegends;
  final bool minimal;
  // Treemap layout settings
  final int topKPerQuadrant; // 5..60
  final double gamma; // 0.70..1.00
  final double minAreaNormalized; // 2e-5 .. 2e-4
  final double quadrantPadding; // 0.0 .. 0.02
  // General · Language & Region
  final String languageCode; // 'system' | 'en' | 'es' | ...
  final String regionCode;   // 'system' | 'US' | 'MX' | ...
  final String dateFormat;   // 'dd/MM/yyyy' | 'MM/dd/yyyy' | 'yyyy-MM-dd'
  final bool use24h;         // true=24h, false=12h
  // General · Notifications
  final String dailyReminderTime; // 'HH:mm' 24h; '' = disabled
  final bool endOfDaySummary;     // switch
  final String endOfDayTime;      // 'HH:mm' or ''
  final String pomodoroAlert;     // 'sound' | 'vibration' | 'silent'
  final String notificationTone;  // 'default' | 'chime' | 'bell'
  // Workflow plan (show Gantt-like CTA in toolbar)
  final bool workflowPlanEnabled;
  // Typography · User text scale (1..5). 3 = default
  final int textScaleLevel;
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
  });

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
  }) => UiPrefsData(
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
      pomodoroAlert: (json['pomodoroAlert'] as String?) ?? 'sound',
      notificationTone: (json['notificationTone'] as String?) ?? 'default',
      workflowPlanEnabled: (json['workflowPlanEnabled'] as bool?) ?? false,
      textScaleLevel: (json['textScaleLevel'] as int?) ?? 3,
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

  Future<void> setTopK(int value) async {
    final v = value.clamp(5, 60);
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
    final k = topKPerQuadrant.clamp(5, 60);
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
}

final uiPrefsControllerProvider = NotifierProvider<UiPrefsController, UiPrefsData>(UiPrefsController.new);

// Convenience provider alias to watch prefs data
final uiPrefsProvider = Provider<UiPrefsData>((ref) => ref.watch(uiPrefsControllerProvider));
