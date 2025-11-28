import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for Task entity equality using Equatable.
///
/// Verifies that:
/// 1. Tasks with identical data are equal (prevents unnecessary rebuilds)
/// 2. Tasks with different data are not equal (ensures correct updates)
/// 3. Equatable properly handles all fields including collections
void main() {
  group('Task Equality (Equatable)', () {
    test('identical tasks are equal', () {
      final task1 = Task(
        id: 't1',
        title: 'Test Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        due: DateTime(2025, 10, 30),
        tags: ['work', 'urgent'],
        notes: 'Important meeting',
        category: 'project',
      );

      final task2 = Task(
        id: 't1',
        title: 'Test Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        due: DateTime(2025, 10, 30),
        tags: ['work', 'urgent'],
        notes: 'Important meeting',
        category: 'project',
      );

      expect(task1 == task2, isTrue,
          reason: 'Tasks with identical data should be equal');
      expect(task1.hashCode, task2.hashCode,
          reason: 'Equal tasks should have same hashCode');
    });

    test('copyWith with same values maintains equality', () {
      final original = Task(
        id: 't1',
        title: 'Original',
        quadrant: Quadrant.q1,
        priority: 7,
        minutes: 60,
      );

      final copied = original.copyWith(
        title: original.title, // Same value
        priority: original.priority, // Same value
      );

      expect(original == copied, isTrue,
          reason: 'copyWith with same values should maintain equality');
    });

    test('different priority makes tasks unequal', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
      );

      final task2 = task1.copyWith(priority: 6);

      expect(task1 == task2, isFalse,
          reason: 'Tasks with different priority should not be equal');
      expect(task1.hashCode != task2.hashCode, isTrue,
          reason: 'Different tasks should likely have different hashCodes');
    });

    test('different title makes tasks unequal', () {
      final task1 = Task(
        id: 't1',
        title: 'Original',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
      );

      final task2 = task1.copyWith(title: 'Modified');

      expect(task1 == task2, isFalse,
          reason: 'Tasks with different titles should not be equal');
    });

    test('different quadrant makes tasks unequal', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 30,
      );

      final task2 = task1.copyWith(quadrant: Quadrant.q3);

      expect(task1 == task2, isFalse,
          reason: 'Tasks in different quadrants should not be equal');
    });

    test('different tags makes tasks unequal', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        tags: ['work'],
      );

      final task2 = task1.copyWith(tags: ['personal']);

      expect(task1 == task2, isFalse,
          reason: 'Tasks with different tags should not be equal');
    });

    test('same task instance is identical', () {
      final task = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
      );

      expect(identical(task, task), isTrue,
          reason: 'Same instance should be identical');
      expect(task == task, isTrue, reason: 'Task should equal itself');
    });

    test('equatable handles empty tags correctly', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        tags: [],
      );

      final task2 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        tags: [],
      );

      expect(task1 == task2, isTrue,
          reason: 'Tasks with empty tags should be equal');
    });

    test('equatable handles null optional fields correctly', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        due: null,
        notes: null,
        category: null,
      );

      final task2 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        due: null,
        notes: null,
        category: null,
      );

      expect(task1 == task2, isTrue,
          reason: 'Tasks with null optional fields should be equal');
    });

    test('different normalized values make tasks unequal', () {
      final task1 = Task(
        id: 't1',
        title: 'Task',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
        normalizedPriority: 0.5,
      );

      final task2 = task1.copyWith(normalizedPriority: 0.6);

      expect(task1 == task2, isFalse,
          reason: 'Tasks with different normalized values should not be equal');
    });
  });

  group('Task Equality - Render Stability', () {
    test('stable task list prevents unnecessary rebuilds', () {
      final tasks1 = [
        Task(
            id: 't1',
            title: 'A',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 't2',
            title: 'B',
            quadrant: Quadrant.q2,
            priority: 3,
            minutes: 20),
      ];

      final tasks2 = [
        Task(
            id: 't1',
            title: 'A',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 't2',
            title: 'B',
            quadrant: Quadrant.q2,
            priority: 3,
            minutes: 20),
      ];

      // Element-wise equality
      expect(tasks1[0] == tasks2[0], isTrue);
      expect(tasks1[1] == tasks2[1], isTrue);

      // List equality (for Riverpod .select comparisons)
      final listsEqual = tasks1.length == tasks2.length &&
          tasks1.asMap().entries.every((e) => e.value == tasks2[e.key]);

      expect(listsEqual, isTrue,
          reason:
              'Lists with equal tasks should be considered equal for render optimization');
    });

    test('changed task in list is detected', () {
      final tasks1 = [
        Task(
            id: 't1',
            title: 'A',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 't2',
            title: 'B',
            quadrant: Quadrant.q2,
            priority: 3,
            minutes: 20),
      ];

      final tasks2 = [
        Task(
            id: 't1',
            title: 'A',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 't2',
            title: 'B MODIFIED',
            quadrant: Quadrant.q2,
            priority: 3,
            minutes: 20),
      ];

      // Element-wise check detects change
      expect(tasks1[0] == tasks2[0], isTrue);
      expect(tasks1[1] == tasks2[1], isFalse,
          reason: 'Modified task should not equal original');

      final listsEqual = tasks1.length == tasks2.length &&
          tasks1.asMap().entries.every((e) => e.value == tasks2[e.key]);

      expect(listsEqual, isFalse,
          reason: 'Lists with different tasks should trigger re-render');
    });
  });
}
