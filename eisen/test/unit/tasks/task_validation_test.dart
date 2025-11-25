import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task basic invariants', () {
    final now = DateTime(2024, 1, 1);

    test('isCompleted flag reflects completedAt', () {
      final pending = Task(
        id: 't1',
        title: 'Pending',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 60,
        createdAt: now,
      );
      final done = pending.copyWith(completedAt: now);

      expect(pending.isCompleted, isFalse);
      expect(done.isCompleted, isTrue);
    });

    test('subtask progress computes correctly', () {
      final task = Task(
        id: 't1',
        title: 'With subtasks',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 60,
        createdAt: now,
        subtasks: const [
          Subtask(id: 's1', title: 'a', completed: true),
          Subtask(id: 's2', title: 'b', completed: false),
        ],
      );

      expect(task.subtaskProgress, closeTo(0.5, 0.01));
      expect(task.completedSubtaskCount, 1);
    });

    test('copyWith preserves identity and updates fields', () {
      final task = Task(
        id: 't1',
        title: 'Base',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 60,
        createdAt: now,
      );

      final updated = task.copyWith(
        title: 'Renamed',
        minutes: 90,
        priority: 7,
      );

      expect(updated.id, task.id);
      expect(updated.title, 'Renamed');
      expect(updated.minutes, 90);
      expect(updated.priority, 7);
    });

    test('normalized values stay within 0..1', () {
      final task = Task(
        id: 't1',
        title: 'Norm',
        quadrant: Quadrant.q3,
        priority: 20,
        minutes: 300,
        createdAt: now,
      );

      expect(task.priorityNorm, inExclusiveRange(0.0, 1.01));
      expect(task.minutesNorm, inExclusiveRange(0.0, 1.01));
    });
  });
}
