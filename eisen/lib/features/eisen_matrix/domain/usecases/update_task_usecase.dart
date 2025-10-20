import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Use case for updating an existing task.
///
/// Applies an updater function to a task and sets the updatedAt timestamp.
class UpdateTaskUseCase {
  /// Updates a task using the provided [updater] function.
  ///
  /// The [updater] receives the current task and returns the modified task.
  /// The updatedAt timestamp is automatically set to now.
  Task execute(Task current, Task Function(Task) updater) {
    final updated = updater(current);
    return updated.copyWith(updatedAt: DateTime.now());
  }
}
