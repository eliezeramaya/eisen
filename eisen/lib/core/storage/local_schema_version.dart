import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSchemaVersion {
  const LocalSchemaVersion({
    required this.currentSchemaVersion,
    this.lastMigratedAt,
  });

  final int currentSchemaVersion;
  final DateTime? lastMigratedAt;
}

class LocalSchemaVersionStore {
  const LocalSchemaVersionStore();

  Future<LocalSchemaVersion> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDate = prefs.getString(LocalStorageKeys.localSchemaLastMigratedAt);
    return LocalSchemaVersion(
      currentSchemaVersion:
          prefs.getInt(LocalStorageKeys.localSchemaVersion) ?? 0,
      lastMigratedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  Future<void> save(int version, {DateTime? migratedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = migratedAt ?? DateTime.now();
    await prefs.setInt(LocalStorageKeys.localSchemaVersion, version);
    await prefs.setString(
      LocalStorageKeys.localSchemaLastMigratedAt,
      timestamp.toIso8601String(),
    );
  }
}
