import 'dart:convert';

import 'package:eisen/features/settings/domain/language_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LanguagePrefsRepository {
  Future<LanguagePrefs> load();
  Future<void> save(LanguagePrefs prefs);
}

class LanguagePrefsLocalRepository implements LanguagePrefsRepository {
  static const _key = 'settings.language.v1';

  @override
  Future<LanguagePrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const LanguagePrefs(null);
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, Object?>) {
        return LanguagePrefs.fromJson(map);
      }
    } catch (_) {}
    return const LanguagePrefs(null);
  }

  @override
  Future<void> save(LanguagePrefs prefs) async {
    final prefsStore = await SharedPreferences.getInstance();
    await prefsStore.setString(_key, jsonEncode(prefs.toJson()));
  }
}

final languagePrefsRepositoryProvider =
    Provider<LanguagePrefsRepository>((ref) => LanguagePrefsLocalRepository());
