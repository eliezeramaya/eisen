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
  const UiPrefsData({
    this.themeMode = ThemeMode.system,
    this.compact = false,
    this.showAxisLegends = true,
    this.minimal = false,
    this.topKPerQuadrant = 20,
    this.gamma = 1.0,
    this.minAreaNormalized = 0.00004,
    this.quadrantPadding = 0.012,
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
  }) => UiPrefsData(
        themeMode: themeMode ?? this.themeMode,
        compact: compact ?? this.compact,
        showAxisLegends: showAxisLegends ?? this.showAxisLegends,
        minimal: minimal ?? this.minimal,
        topKPerQuadrant: topKPerQuadrant ?? this.topKPerQuadrant,
        gamma: gamma ?? this.gamma,
        minAreaNormalized: minAreaNormalized ?? this.minAreaNormalized,
        quadrantPadding: quadrantPadding ?? this.quadrantPadding,
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
}

final uiPrefsControllerProvider = NotifierProvider<UiPrefsController, UiPrefsData>(UiPrefsController.new);

// Convenience provider alias to watch prefs data
final uiPrefsProvider = Provider<UiPrefsData>((ref) => ref.watch(uiPrefsControllerProvider));
