import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userCategoriesProvider = StateNotifierProvider<UserCategoriesController, List<String>>((ref) {
  return UserCategoriesController(ref);
});

class UserCategoriesController extends StateNotifier<List<String>> {
  static const _key = 'eisen.user_categories.v1';
  final Ref read;
  UserCategoriesController(this.read) : super(const []) {
    _load();
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

