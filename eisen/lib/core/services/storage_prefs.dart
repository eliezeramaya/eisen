import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoragePrefs {
  static const _key = 'eisen.tasks.v1';

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
}

