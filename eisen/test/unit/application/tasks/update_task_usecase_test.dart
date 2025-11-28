import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/update_task_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateTaskUseCase', () {
    final useCase = UpdateTaskUseCase();
    final base = Task(
      id: 't1',
      title: 'Base',
      quadrant: Quadrant.q2,
      priority: 5,
      minutes: 60,
      createdAt: DateTime(2024, 1, 1),
    );

    test('updates mutable fields and sets updatedAt', () {
      final updated = useCase.execute(base, (t) {
        return t.copyWith(
          title: 'Updated title',
          minutes: 90,
          priority: 9,
          quadrant: Quadrant.q1,
        );
      });

      expect(updated.title, 'Updated title');
      expect(updated.minutes, 90);
      expect(updated.priority, 9);
      expect(updated.quadrant, Quadrant.q1);
      expect(updated.createdAt, base.createdAt);
      expect(updated.updatedAt, isNotNull);
    });

    test('preserves original title when updater leaves it empty/whitespace',
        () {
      final updated = useCase.execute(base, (t) {
        return t.copyWith(title: '   ');
      });

      expect(updated.title, base.title);
    });

    test('clamps priority/minutes after updater', () {
      final updated = useCase.execute(base, (t) {
        return t.copyWith(priority: 999, minutes: 5000);
      });

      expect(updated.priority, 10);
      expect(updated.minutes, 24 * 60);
    });

  });
}
