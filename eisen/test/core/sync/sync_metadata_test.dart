import 'package:eisen/core/sync/sync_metadata.dart';
import 'package:eisen/core/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('metadata starts local-only and dirty', () {
    final metadata = SyncMetadata(localId: 'local-1');

    expect(metadata.syncStatus, SyncStatus.localOnly);
    expect(metadata.dirty, isTrue);
    expect(metadata.remoteId, isNull);
  });

  test('markSynced clears dirty flag', () {
    final metadata = SyncMetadata(localId: 'local-1').markSynced(
      remoteId: 'remote-1',
    );

    expect(metadata.syncStatus, SyncStatus.synced);
    expect(metadata.dirty, isFalse);
    expect(metadata.remoteId, 'remote-1');
    expect(metadata.lastSyncedAt, isNotNull);
  });
}
