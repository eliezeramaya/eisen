import 'package:eisen/core/sync/remote_tasks_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class RemoteTasksServiceNoop implements RemoteTasksService {
  const RemoteTasksServiceNoop();

  @override
  Future<List<Task>?> fetchRemoteTasks() async => null;

  @override
  Future<void> pushRemoteTasks(List<Task> tasks) async {}

  @override
  Future<List<Task>> resolveConflict({
    required List<Task> local,
    required List<Task> remote,
  }) async =>
      local;
}

final remoteTasksServiceProvider = Provider<RemoteTasksService>(
  (ref) => const RemoteTasksServiceNoop(),
);
