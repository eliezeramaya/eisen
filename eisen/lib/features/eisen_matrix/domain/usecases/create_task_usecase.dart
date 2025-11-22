import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Use case for creating a new task in the matrix.
///
/// Generates a unique ID, sets creation timestamp, and returns the new task.
class CreateTaskUseCase {
  /// Creates a new task with the given parameters.
  ///
  /// [quadrant]: Target quadrant (default Q2)
  /// [title]: Initial title (default 'New Task')
  /// Returns: Newly created [Task] with generated ID and timestamps
  Task execute({
    Quadrant quadrant = Quadrant.q2,
    String title = 'New Task',
    int priority = 5,
    int minutes = 30,
  }) {
    final safeTitle = title.trim().isEmpty ? 'New Task' : title.trim();
    final prio = priority.clamp(1, 10);
    final mins = minutes.clamp(1, 24 * 60);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    return Task(
      id: id,
      title: safeTitle,
      quadrant: quadrant,
      priority: prio,
      minutes: mins,
      createdAt: now,
    );
  }
}
