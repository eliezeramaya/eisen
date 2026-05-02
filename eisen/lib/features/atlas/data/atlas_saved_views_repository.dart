import 'dart:convert';

import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/atlas/domain/saved_atlas_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasSavedViewsRepository {
  const AtlasSavedViewsRepository();

  Future<List<SavedAtlasView>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(LocalStorageKeys.atlasSavedViews);
    if (raw == null || raw.trim().isEmpty) return const <SavedAtlasView>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <SavedAtlasView>[];
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map((item) => SavedAtlasView.fromJson(item.cast<String, Object?>()))
          .where((view) => view.id.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const <SavedAtlasView>[];
    } on TypeError {
      return const <SavedAtlasView>[];
    }
  }

  Future<void> save(List<SavedAtlasView> views) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      LocalStorageKeys.atlasSavedViews,
      jsonEncode(views.map((view) => view.toJson()).toList(growable: false)),
    );
  }
}
