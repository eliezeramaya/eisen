import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiPrefsData {
  final ThemeMode themeMode;
  final bool compact;
  final bool showAxisLegends;
  final bool minimal;
  const UiPrefsData({
    this.themeMode = ThemeMode.system,
    this.compact = false,
    this.showAxisLegends = true,
    this.minimal = false,
  });

  UiPrefsData copyWith({ThemeMode? themeMode, bool? compact, bool? showAxisLegends, bool? minimal}) => UiPrefsData(
        themeMode: themeMode ?? this.themeMode,
        compact: compact ?? this.compact,
        showAxisLegends: showAxisLegends ?? this.showAxisLegends,
        minimal: minimal ?? this.minimal,
      );

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'compact': compact,
        'showAxisLegends': showAxisLegends,
        'minimal': minimal,
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
