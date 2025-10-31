import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// kept for features that use category filters; not required by add task sheet
import 'package:shared_preferences/shared_preferences.dart';

/// Active user-defined categories repository (persisted in SharedPreferences).
final userCategoriesProvider =
    NotifierProvider<UserCategoriesController, List<String>>(
        UserCategoriesController.new);

class UserCategoriesController extends Notifier<List<String>> {
  static const _key = 'eisen.user_categories.v1';

  @override
  List<String> build() {
    // Start with empty state and then load asynchronously.
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<String>();
      state = list.toSet().toList()..sort();
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('UserCategoriesController._load error: $e\n$st');
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }

  Future<void> addOrRename({String? from, required String to}) async {
    final s = state.toSet();
    if (from != null) s.remove(from);
    if (to.isNotEmpty) s.add(to);
    state = s.toList()..sort();
    await _save();
  }

  Future<void> remove(String name) async {
    final s = state.toSet();
    s.remove(name);
    state = s.toList()..sort();
    await _save();
  }
}
