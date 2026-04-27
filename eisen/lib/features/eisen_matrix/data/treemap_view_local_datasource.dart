import 'dart:convert';

import 'package:eisen/features/eisen_matrix/domain/treemap_view_preferences.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TreemapViewLocalDatasource {
  static const _preferencesKey = 'eisen.treemap.view_preferences.v1';
  static const _stateKey = 'eisen.treemap.view_state.v1';

  Future<TreemapViewPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferencesKey);
    if (raw == null) return TreemapViewPreferencesDefaults.value;
    final decoded = jsonDecode(raw);
    return TreemapViewPreferences.fromJson(
      (decoded as Map).cast<String, Object?>(),
    );
  }

  Future<void> savePreferences(TreemapViewPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }

  Future<TreemapViewportState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return TreemapViewportState.fromJson(
      (decoded as Map).cast<String, Object?>(),
    );
  }

  Future<void> saveState(TreemapViewportState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stateKey,
      jsonEncode(state.toJson()),
    );
  }
}
