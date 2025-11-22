import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Isolated CRUD operation tests for tasks
/// Each operation tested separately with proper setup and teardown
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Isolated CREATE operations', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('create task with minimal fields returns valid ID', () {
      final controller = container.read(matrixControllerProvider.notifier);

      final id = controller.createTask(
        title: 'Minimal Task',
        quadrant: Quadrant.q1,
      );

      expect(id, isNotEmpty);
      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.title, 'Minimal Task');
      expect(state.tasks.first.quadrant, Quadrant.q1);
      expect(state.tasks.first.id, id);
    });

    test('create multiple tasks in different quadrants', () {
      final controller = container.read(matrixControllerProvider.notifier);

      for (final quadrant in Quadrant.values) {
        controller.createTask(
          title: 'Task in ${quadrant.name}',
          quadrant: quadrant,
        );
      }

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 4);
      
      for (final quadrant in Quadrant.values) {
        final tasksInQuadrant = state.tasks.where((t) => t.quadrant == quadrant);
        expect(tasksInQuadrant.length, 1);
      }
    });

    test('create task generates unique IDs', () {
      final controller = container.read(matrixControllerProvider.notifier);

      final id1 = controller.createTask(
        title: 'Task 1',
        quadrant: Quadrant.q1,
      );

      final id2 = controller.createTask(
        title: 'Task 2',
        quadrant: Quadrant.q1,
      );

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 2);
      expect(id1, isNot(equals(id2)));
    });

    test('created task is automatically selected', () {
      final controller = container.read(matrixControllerProvider.notifier);

      final id = controller.createTask(
        title: 'Selected Task',
        quadrant: Quadrant.q2,
      );

      final state = container.read(matrixControllerProvider);
      expect(state.selectedId, id);
    });
  });

  group('Isolated READ operations', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      
      // Create some test data
      final controller = container.read(matrixControllerProvider.notifier);
      for (int i = 1; i <= 5; i++) {
        controller.createTask(
          title: 'Task $i',
          quadrant: Quadrant.values[i % 4],
        );
      }
    });

    tearDown(() {
      container.dispose();
    });

    test('read all tasks returns correct count', () {
      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 5);
    });

    test('read tasks by quadrant works correctly', () {
      final state = container.read(matrixControllerProvider);
      
      final q1Tasks = state.tasks.where((t) => t.quadrant == Quadrant.q1).toList();
      final q2Tasks = state.tasks.where((t) => t.quadrant == Quadrant.q2).toList();
      
      expect(q1Tasks.length, greaterThan(0));
      expect(q2Tasks.length, greaterThan(0));
    });

    test('read task by id finds correct task', () {
      final state = container.read(matrixControllerProvider);
      final firstTask = state.tasks.first;
      
      final foundTask = state.tasks.firstWhere((t) => t.id == firstTask.id);
      expect(foundTask.id, firstTask.id);
      expect(foundTask.title, firstTask.title);
    });
  });

  group('Isolated UPDATE operations', () {
    late ProviderContainer container;
    late String taskId;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      
      // Create a task to update
      final controller = container.read(matrixControllerProvider.notifier);
      taskId = controller.createTask(
        title: 'Original Title',
        quadrant: Quadrant.q1,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('update task title changes the title', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(title: 'Updated Title');
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.title, 'Updated Title');
    });

    test('update task quadrant moves task correctly', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(quadrant: Quadrant.q3);
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.quadrant, Quadrant.q3);
    });

    test('update task priority and minutes', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(priority: 10, minutes: 120);
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.priority, 10);
      expect(task.minutes, 120);
    });

    test('update sets updatedAt timestamp', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final beforeUpdate = DateTime.now();
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(title: 'New Title', updatedAt: DateTime.now());
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.updatedAt, isNotNull);
      expect(task.updatedAt!.isAfter(beforeUpdate.subtract(const Duration(seconds: 1))), true);
    });

    test('update preserves unchanged fields', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final originalState = container.read(matrixControllerProvider);
      final originalTask = originalState.tasks.firstWhere((t) => t.id == taskId);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(title: 'Only Title Changed');
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      
      expect(task.quadrant, originalTask.quadrant);
      expect(task.priority, originalTask.priority);
      expect(task.minutes, originalTask.minutes);
    });

    test('update multiple fields at once', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(
          title: 'Multi Update',
          quadrant: Quadrant.q4,
          priority: 7,
          minutes: 90,
        );
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      
      expect(task.title, 'Multi Update');
      expect(task.quadrant, Quadrant.q4);
      expect(task.priority, 7);
      expect(task.minutes, 90);
    });
  });

  group('Isolated DELETE operations', () {
    late ProviderContainer container;
    late List<String> taskIds;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      
      // Create multiple tasks
      final controller = container.read(matrixControllerProvider.notifier);
      taskIds = [];
      
      for (int i = 1; i <= 3; i++) {
        final id = controller.createTask(
          title: 'Task $i',
          quadrant: Quadrant.q1,
        );
        taskIds.add(id);
      }
    });

    tearDown() {
      container.dispose();
    });

    test('delete single task removes it from state', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.deleteTask(taskIds.first);

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 2);
      expect(state.tasks.any((t) => t.id == taskIds.first), false);
    });

    test('delete multiple tasks sequentially', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.deleteTask(taskIds[0]);
      controller.deleteTask(taskIds[1]);

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.id, taskIds.last);
    });

    test('delete all tasks results in empty state', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      for (final id in taskIds) {
        controller.deleteTask(id);
      }

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.isEmpty, true);
    });

    test('delete nonexistent task does not crash', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // This should not throw
      controller.deleteTask('nonexistent-id-12345');

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 3); // All tasks still present
    });

    test('delete clears selection if deleting selected task', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final selectedId = taskIds.first;
      
      // Ensure task is selected
      expect(container.read(matrixControllerProvider).selectedId, isNotNull);
      
      controller.deleteTask(selectedId);

      final state = container.read(matrixControllerProvider);
      // Selection should be cleared or moved to another task
      expect(state.selectedId != selectedId || state.selectedId == null, true);
    });
  });

  group('Isolated COMPLETE operations', () {
    late ProviderContainer container;
    late String taskId;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      
      final controller = container.read(matrixControllerProvider.notifier);
      taskId = controller.createTask(
        title: 'Task to Complete',
        quadrant: Quadrant.q1,
      );
    });

    tearDown() {
      container.dispose();
    });

    test('mark task as complete sets completedAt', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final completionTime = DateTime.now();
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(completedAt: completionTime);
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.completedAt, isNotNull);
    });

    test('completed task remains in state', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(completedAt: DateTime.now());
      });

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.completedAt, isNotNull);
    });

    test('can update status field separately', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.updateTask(taskId, (task) {
        return task.copyWith(status: TaskStatus.completed);
      });

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      expect(task.status, TaskStatus.completed);
    });
  });
}
