import 'package:eisen/core/sync/syncable_entity.dart';

abstract interface class SyncRepository<T extends SyncableEntity> {
  Future<List<T>> getPendingSync();
  Future<void> markSynced(T entity, {required String remoteId});
  Future<void> markFailed(T entity, Object error);
}
