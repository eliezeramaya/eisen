import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Remote tasks sync contract (placeholder while backend is absent).
abstract interface class RemoteTasksService {
  Future<List<Task>?> fetchRemoteTasks();
  Future<void> pushRemoteTasks(List<Task> tasks);
  Future<List<Task>> resolveConflict({
    required List<Task> local,
    required List<Task> remote,
  });
}
