import 'dart:convert';

import 'package:eisen/features/settings/domain/accessibility_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AccessibilityPrefsRepository {
  Future<AccessibilityPrefs> load();
  Future<void> save(AccessibilityPrefs prefs);
}

class AccessibilityPrefsLocalRepository
    implements AccessibilityPrefsRepository {
  static const _key = 'settings.accessibility.v1';

  @override
  Future<AccessibilityPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return const AccessibilityPrefs(
        largeText: false,
        highContrast: false,
        reduceAnimations: false,
        hapticsEnabled: true,
      );
    }
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, Object?>) {
        return AccessibilityPrefs.fromJson(map);
      }
    } catch (_) {}
    return const AccessibilityPrefs(
      largeText: false,
      highContrast: false,
      reduceAnimations: false,
      hapticsEnabled: true,
    );
  }

  @override
  Future<void> save(AccessibilityPrefs prefs) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(_key, jsonEncode(prefs.toJson()));
  }
}

final accessibilityPrefsRepositoryProvider =
    Provider<AccessibilityPrefsRepository>(
        (ref) => AccessibilityPrefsLocalRepository());
