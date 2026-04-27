import 'package:eisen/core/sync/syncable_entity.dart';

enum SyncQueueOperation {
  create,
  update,
  delete,
}

class SyncQueueItem<T extends SyncableEntity> {
  const SyncQueueItem({
    required this.entity,
    required this.operation,
    required this.enqueuedAt,
    this.attemptCount = 0,
    this.lastError,
  });

  final T entity;
  final SyncQueueOperation operation;
  final DateTime enqueuedAt;
  final int attemptCount;
  final String? lastError;
}

abstract interface class SyncQueue<T extends SyncableEntity> {
  Future<void> enqueue(SyncQueueItem<T> item);
  Future<List<SyncQueueItem<T>>> pending({int limit = 50});
  Future<void> acknowledge(String localId);
  Future<void> fail(String localId, Object error);
}
