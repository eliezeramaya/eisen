import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/create_task_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/delete_task_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/update_task_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tasks edge cases', () {
    final create = CreateTaskUseCase();
    final update = UpdateTaskUseCase();
    final delete = DeleteTaskUseCase();

    test('stress: create 10k tasks without crashing', () {
      final tasks = <Task>[];
      for (var i = 0; i < 10000; i++) {
        tasks.add(create.execute(title: 'Task $i', minutes: 15 + i % 60));
      }
      expect(tasks.length, 10000);
      expect(tasks.every((t) => t.id.isNotEmpty), isTrue);
    });

    test('update multiple fields in sequence', () {
      var task = create.execute(title: 'Seq', minutes: 30);
      task = update.execute(task, (t) {
        return t.copyWith(
          title: 'Seq Updated',
          minutes: 90,
          quadrant: Quadrant.q1,
        );
      });
      task = update.execute(task, (t) {
        return t.copyWith(priority: 9, notes: 'note');
      });

      expect(task.title, 'Seq Updated');
      expect(task.minutes, 90);
      expect(task.priority, 9);
      expect(task.notes, 'note');
    });

    test('delete immediately after create cleans cache safely', () {
      final task = create.execute(title: 'Temp');
      final cache = LayoutCache();
      cache.lastWeight[task.id] = 1.0;
      cache.lastRank[task.id] = 1;

      delete.cleanupCache(task.id, cache);

      expect(cache.lastWeight.containsKey(task.id), isFalse);
      expect(cache.lastRect.containsKey(task.id), isFalse);
      expect(cache.lastRank.containsKey(task.id), isFalse);
    });

    test('create + edit + delete sequence', () {
      final cache = LayoutCache();
      final created = create.execute(title: 'Chain', minutes: 20);
      final edited = update.execute(created, (t) {
        return t.copyWith(minutes: 40, quadrant: Quadrant.q4);
      });

      expect(edited.minutes, 40);
      expect(edited.quadrant, Quadrant.q4);
      delete.cleanupCache(edited.id, cache); // ensure no throw
    });
  });
}
