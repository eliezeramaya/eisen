import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/create_task_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/update_task_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task validation use cases', () {
    test('CreateTaskUseCase clamps inputs and defaults title', () {
      final useCase = CreateTaskUseCase();
      final task = useCase.execute(
        quadrant: Quadrant.q1,
        title: '   ', // empty after trim
        priority: 50, // out of range
        minutes: -5, // invalid
      );

      expect(task.title, 'New Task');
      expect(task.priority, inInclusiveRange(1, 10));
      expect(task.priority, 10);
      expect(task.minutes, 1);
      expect(task.quadrant, Quadrant.q1);
      expect(task.createdAt, isNotNull);
      expect(task.id.isNotEmpty, isTrue);
    });

    test('UpdateTaskUseCase normalizes title/priority/minutes and sets updatedAt',
        () {
      final useCase = UpdateTaskUseCase();
      final original = Task(
        id: 'x',
        title: 'Original',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
      );

      final updated = useCase.execute(original, (t) {
        return t.copyWith(
          title: '  nueva   ',
          priority: 0,
          minutes: -10,
        );
      });

      expect(updated.title, 'nueva');
      expect(updated.priority, 1);
      expect(updated.minutes, 1);
      expect(updated.updatedAt, isNotNull);
      // Ensure other fields are preserved
      expect(updated.id, original.id);
      expect(updated.quadrant, original.quadrant);
    });
  });
}
