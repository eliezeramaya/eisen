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
    var updated = updater(current);
    // Normalize critical fields to keep invariants and avoid invalid data.
    final prio = updated.priority.clamp(1, 10);
    final mins = updated.minutes.clamp(1, 24 * 60);
    final title = updated.title.trim().isEmpty
        ? current.title
        : updated.title.trim();

    updated = updated.copyWith(
      title: title,
      priority: prio,
      minutes: mins,
    );
    return updated.copyWith(updatedAt: DateTime.now());
  }
}
