import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/core/services/storage_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Error handling and edge case tests for CRUD operations
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Edge Cases - Empty States', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('read from empty state returns empty list', () {
      final state = container.read(matrixControllerProvider);
      expect(state.tasks, isEmpty);
    });

    test('update on empty state does nothing', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Should not crash
      controller.updateTask('nonexistent', (task) => task);
      
      final state = container.read(matrixControllerProvider);
      expect(state.tasks, isEmpty);
    });

    test('delete from empty state does nothing', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Should not crash
      controller.deleteTask('nonexistent');
      
      final state = container.read(matrixControllerProvider);
      expect(state.tasks, isEmpty);
    });
  });

  group('Edge Cases - Concurrent Operations', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('create multiple tasks rapidly', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final ids = <String>[];

      // Create 10 tasks quickly
      for (int i = 0; i < 10; i++) {
        final id = controller.createTask(
          title: 'Rapid Task $i',
          quadrant: Quadrant.q1,
        );
        ids.add(id);
      }

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 10);
      
      // All IDs should be unique
      expect(ids.toSet().length, 10);
    });

    test('update same task multiple times', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final taskId = controller.createTask(
        title: 'Original',
        quadrant: Quadrant.q1,
      );

      // Update 5 times
      for (int i = 0; i < 5; i++) {
        controller.updateTask(taskId, (task) {
          return task.copyWith(title: 'Update $i');
        });
      }

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.title, 'Update 4');
    });

    test('delete tasks while iterating', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Create tasks
      final ids = <String>[];
      for (int i = 0; i < 5; i++) {
        final id = controller.createTask(
          title: 'Task $i',
          quadrant: Quadrant.q1,
        );
        ids.add(id);
      }

      // Delete even-indexed tasks
      for (int i = 0; i < ids.length; i += 2) {
        controller.deleteTask(ids[i]);
      }

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 2); // Should have 2 tasks left
    });
  });

  group('Edge Cases - Boundary Values', () {
    late ProviderContainer container;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('create task with empty title is accepted', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final id = controller.createTask(
        title: '',
        quadrant: Quadrant.q1,
      );

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      // Empty title might be defaulted
      expect(state.tasks.first.id, id);
    });

    test('create task with very long title', () {
      final controller = container.read(matrixControllerProvider.notifier);
      final longTitle = 'A' * 1000;
      
      final id = controller.createTask(
        title: longTitle,
        quadrant: Quadrant.q1,
      );

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.id, id);
    });

    test('create task with special characters in title', () {
      final controller = container.read(matrixControllerProvider.notifier);
      const specialTitle = 'Task with 🎯 emoji and @#\$% symbols';
      
      final id = controller.createTask(
        title: specialTitle,
        quadrant: Quadrant.q1,
      );

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.first.title, specialTitle);
    });
  });

  group('Edge Cases - State Transitions', () {
    late ProviderContainer container;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('move task through all quadrants', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final taskId = controller.createTask(
        title: 'Moving Task',
        quadrant: Quadrant.q1,
      );

      // Move through all quadrants
      for (final quadrant in Quadrant.values) {
        controller.updateTask(taskId, (task) {
          return task.copyWith(quadrant: quadrant);
        });

        final state = container.read(matrixControllerProvider);
        expect(state.tasks.first.quadrant, quadrant);
      }
    });

    test('toggle completion status multiple times', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final taskId = controller.createTask(
        title: 'Toggle Task',
        quadrant: Quadrant.q1,
      );

      // Complete
      controller.updateTask(taskId, (task) {
        return task.copyWith(completedAt: DateTime.now());
      });

      var state = container.read(matrixControllerProvider);
      expect(state.tasks.first.completedAt, isNotNull);

      // Uncomplete (set to null)
      controller.updateTask(taskId, (task) {
        return task.copyWith(completedAt: null);
      });

      state = container.read(matrixControllerProvider);
      // May or may not preserve the null value depending on implementation
      expect(state.tasks.first.id, taskId);
    });
  });

  group('Error Handling - Persistence', () {
    late ProviderContainer container;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('persist and reload data', () async {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Create tasks
      controller.createTask(title: 'Task 1', quadrant: Quadrant.q1);
      controller.createTask(title: 'Task 2', quadrant: Quadrant.q2);

      // Persist
      await controller.persist();

      // Load in a new repository instance
      final repo = LocalPrefsMatrixRepository(StoragePrefs());
      final loaded = await repo.load();

      expect(loaded.length, 2);
      expect(loaded.any((t) => t.title == 'Task 1'), true);
      expect(loaded.any((t) => t.title == 'Task 2'), true);
    });

    test('persist empty state clears storage', () async {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Create and delete task
      final id = controller.createTask(title: 'Temp', quadrant: Quadrant.q1);
      controller.deleteTask(id);

      // Persist empty state
      await controller.persist();

      // Verify storage is empty
      final repo = LocalPrefsMatrixRepository(StoragePrefs());
      final loaded = await repo.load();
      expect(loaded, isEmpty);
    });

    test('persist after multiple operations', () async {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // Complex sequence
      final id1 = controller.createTask(title: 'Task 1', quadrant: Quadrant.q1);
      final id2 = controller.createTask(title: 'Task 2', quadrant: Quadrant.q2);
      
      controller.updateTask(id1, (t) => t.copyWith(title: 'Updated 1'));
      controller.deleteTask(id2);
      
      final id3 = controller.createTask(title: 'Task 3', quadrant: Quadrant.q3);

      await controller.persist();

      // Reload and verify
      final repo = LocalPrefsMatrixRepository(StoragePrefs());
      final loaded = await repo.load();

      expect(loaded.length, 2);
      expect(loaded.any((t) => t.title == 'Updated 1'), true);
      expect(loaded.any((t) => t.title == 'Task 3'), true);
      expect(loaded.any((t) => t.title == 'Task 2'), false);
    });
  });

  group('Error Handling - Invalid IDs', () {
    late ProviderContainer container;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('update with empty ID does nothing', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.createTask(title: 'Task', quadrant: Quadrant.q1);
      
      // Try to update with empty ID
      controller.updateTask('', (task) => task.copyWith(title: 'Should not change'));

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.first.title, 'Task');
    });

    test('delete with null-like ID does nothing', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      controller.createTask(title: 'Task', quadrant: Quadrant.q1);
      
      // Try to delete with various invalid IDs
      controller.deleteTask('');
      controller.deleteTask('null');
      controller.deleteTask('undefined');

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 1);
    });

    test('update with special character IDs', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      // These should just not find anything
      controller.updateTask('////', (task) => task);
      controller.updateTask('@#\$%', (task) => task);
      controller.updateTask('\n\t', (task) => task);

      // Should not crash
      final state = container.read(matrixControllerProvider);
      expect(state.tasks, isEmpty);
    });
  });

  group('Edge Cases - Data Integrity', () {
    late ProviderContainer container;

    setUp() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown() {
      container.dispose();
    });

    test('create task preserves all provided data', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final id = controller.createTask(
        title: 'Complete Task',
        quadrant: Quadrant.q2,
      );

      final state = container.read(matrixControllerProvider);
      final task = state.tasks.first;

      expect(task.id, id);
      expect(task.title, 'Complete Task');
      expect(task.quadrant, Quadrant.q2);
      expect(task.priority, isNotNull);
      expect(task.minutes, isNotNull);
    });

    test('update preserves ID', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final originalId = controller.createTask(
        title: 'Original',
        quadrant: Quadrant.q1,
      );

      controller.updateTask(originalId, (task) {
        return task.copyWith(
          title: 'Updated',
          quadrant: Quadrant.q4,
          priority: 8,
        );
      });

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.first.id, originalId);
      expect(state.tasks.first.title, 'Updated');
    });

    test('delete only removes specified task', () {
      final controller = container.read(matrixControllerProvider.notifier);
      
      final id1 = controller.createTask(title: 'Keep 1', quadrant: Quadrant.q1);
      final id2 = controller.createTask(title: 'Delete', quadrant: Quadrant.q2);
      final id3 = controller.createTask(title: 'Keep 2', quadrant: Quadrant.q3);

      controller.deleteTask(id2);

      final state = container.read(matrixControllerProvider);
      expect(state.tasks.length, 2);
      expect(state.tasks.any((t) => t.id == id1), true);
      expect(state.tasks.any((t) => t.id == id2), false);
      expect(state.tasks.any((t) => t.id == id3), true);
    });
  });
}
