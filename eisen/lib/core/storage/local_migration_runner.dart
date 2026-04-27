import 'package:eisen/core/observability/error_reporter.dart';
import 'package:eisen/core/storage/local_schema_version.dart';

typedef LocalMigration = Future<void> Function();

class LocalMigrationRunner {
  LocalMigrationRunner({
    required this.versionStore,
    required this.errorReporter,
    Map<int, LocalMigration>? migrations,
  }) : migrations = migrations ?? <int, LocalMigration>{};

  final LocalSchemaVersionStore versionStore;
  final ErrorReporter errorReporter;
  final Map<int, LocalMigration> migrations;

  static Future<void> noopMigration() async {}

  Future<void> run({required int targetVersion}) async {
    final current = await versionStore.load();
    if (current.currentSchemaVersion >= targetVersion) return;

    for (var version = current.currentSchemaVersion + 1;
        version <= targetVersion;
        version += 1) {
      final migration = migrations[version] ?? noopMigration;
      try {
        await migration();
        await versionStore.save(version);
      } catch (error, stackTrace) {
        await errorReporter.captureException(
          error,
          stackTrace,
          context: <String, dynamic>{
            'migration_version': version,
            'target_version': targetVersion,
          },
        );
        rethrow;
      }
    }
  }
}
