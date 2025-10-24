import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoragePrefs {
  static const _key = 'eisen.tasks.v1';
  static const _telemetryConsentKey = 'eisen.telemetry.consent.v1';
  static const _telemetrySaltKey = 'eisen.telemetry.salt.v1';

  Future<void> saveJson(Map<String, Object?> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(json));
  }

  Future<Map<String, Object?>> loadJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <String, Object?>{};
    final map = jsonDecode(raw);
    return (map is Map<String, dynamic>) ? map : <String, Object?>{};
  }

  /// Load telemetry consent status. Returns null if never set (first launch).
  Future<bool?> getTelemetryConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_telemetryConsentKey);
  }

  /// Save telemetry consent status.
  Future<void> setTelemetryConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_telemetryConsentKey, enabled);
  }

  /// Load or generate telemetry salt for ID hashing.
  /// Salt is persisted and reused for consistency.
  Future<String> getTelemetrySalt() async {
    final prefs = await SharedPreferences.getInstance();
    var salt = prefs.getString(_telemetrySaltKey);
    if (salt == null) {
      // Generate new salt (random string)
      salt = DateTime.now().millisecondsSinceEpoch.toString() + 
             DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString(_telemetrySaltKey, salt);
    }
    return salt;
  }
}

