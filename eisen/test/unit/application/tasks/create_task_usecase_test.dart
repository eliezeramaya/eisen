import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/create_task_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateTaskUseCase', () {
    final useCase = CreateTaskUseCase();

    test('creates task with sane defaults and generated id', () {
      final task = useCase.execute();

      expect(task.id, isNotEmpty);
      expect(task.title, 'New Task');
      expect(task.quadrant, Quadrant.q2);
      expect(task.priority, 5);
      expect(task.minutes, 30);
      expect(task.createdAt, isNotNull);
    });

    test('trims title and clamps priority/minutes', () {
      final task = useCase.execute(
        title: '   Focus time   ',
        priority: 15, // clamp to 10
        minutes: 2000, // clamp to 1440
        quadrant: Quadrant.q1,
      );

      expect(task.title, 'Focus time');
      expect(task.priority, 10);
      expect(task.minutes, 24 * 60);
      expect(task.quadrant, Quadrant.q1);
    });

    test('replaces empty/whitespace title with default', () {
      final task = useCase.execute(title: '   ');
      expect(task.title, 'New Task');
    });

    test('clamps negative or tiny minutes/priority to minimums', () {
      final task = useCase.execute(priority: -5, minutes: -10);
      expect(task.priority, 1);
      expect(task.minutes, 1);
    });

    test('supports large titles without throwing', () {
      final longTitle = 'a' * 500;
      final task = useCase.execute(title: longTitle);
      expect(task.title.length, 500);
    });
  });
}
