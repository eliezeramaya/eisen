import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasGroupingPrefs {
  const AtlasGroupingPrefs();

  Future<AtlasGrouping> load() async {
    final prefs = await SharedPreferences.getInstance();
    return atlasGroupingFromName(
      prefs.getString(LocalStorageKeys.atlasGrouping),
    );
  }

  Future<void> save(AtlasGrouping grouping) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStorageKeys.atlasGrouping, grouping.name);
  }
}
