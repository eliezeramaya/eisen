import 'package:eisen/core/sync/sync_status.dart';

class SyncMetadata {
  SyncMetadata({
    required this.localId,
    this.remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.localOnly,
    this.version = 1,
    this.dirty = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String localId;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final int version;
  final bool dirty;

  bool get isDeleted => deletedAt != null;
  bool get canSync =>
      remoteId != null || syncStatus == SyncStatus.pendingCreate;

  SyncMetadata markSynced({
    required String remoteId,
    DateTime? syncedAt,
  }) {
    final now = syncedAt ?? DateTime.now();
    return copyWith(
      remoteId: remoteId,
      lastSyncedAt: now,
      syncStatus: SyncStatus.synced,
      dirty: false,
      updatedAt: now,
    );
  }

  SyncMetadata copyWith({
    String? localId,
    String? remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    int? version,
    bool? dirty,
  }) {
    return SyncMetadata(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      dirty: dirty ?? this.dirty,
    );
  }
}
