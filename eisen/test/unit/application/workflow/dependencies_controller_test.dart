import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DependenciesController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build() initializes empty state when no task dependencies', () {
      final dependencies = container.read(dependenciesControllerProvider);

      expect(dependencies, isEmpty);
    });

    // Note: Skipping build() with tasks test as it requires complex Task setup
    // The controller can load from tasks but we'll test the CRUD operations directly

    group('addDependency', () {
      test('adds valid dependency', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        final result = controller.addDependency(
          prerequisiteId: 'task-a',
          dependentId: 'task-b',
        );

        expect(result.hasCycle, false);

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);

        final dep = dependencies.values.first;
        expect(dep.prerequisiteId, 'task-a');
        expect(dep.dependentId, 'task-b');
        expect(dep.type, DependencyType.finishToStart);
        expect(dep.lagDays, 0);
      });

      test('adds dependency with custom type and lag', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(
          prerequisiteId: 'task-a',
          dependentId: 'task-b',
          type: DependencyType.startToStart,
          lagDays: 2,
        );

        final dependencies = container.read(dependenciesControllerProvider);
        final dep = dependencies.values.first;

        expect(dep.type, DependencyType.startToStart);
        expect(dep.lagDays, 2);
      });

      test('prevents adding dependency that creates cycle', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        // Add a -> b
        controller.addDependency(
          prerequisiteId: 'a',
          dependentId: 'b',
        );

        // Try to add b -> a (would create cycle)
        final result = controller.addDependency(
          prerequisiteId: 'b',
          dependentId: 'a',
        );

        expect(result.hasCycle, true);
        expect(result.cycle, isNotEmpty);

        // Should only have 1 dependency (the valid one)
        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
      });

      test('prevents adding dependency with complex cycle', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        // Create chain: a -> b -> c
        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        // Try to add c -> a (would create cycle)
        final result = controller.addDependency(
          prerequisiteId: 'c',
          dependentId: 'a',
        );

        expect(result.hasCycle, true);

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 2); // Only the 2 valid ones
      });

      test('allows adding multiple dependencies to same task', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 2);

        final forTaskC = controller.getDependenciesForTask('c');
        expect(forTaskC.length, 2);
      });
    });

    group('removeDependency', () {
      test('removes existing dependency', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        expect(container.read(dependenciesControllerProvider).length, 1);

        controller.removeDependency(prerequisiteId: 'a', dependentId: 'b');
        expect(container.read(dependenciesControllerProvider), isEmpty);
      });

      test('does nothing when removing non-existent dependency', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');

        // Try to remove non-existent dependency
        controller.removeDependency(prerequisiteId: 'x', dependentId: 'y');

        expect(container.read(dependenciesControllerProvider).length, 1);
      });

      test('removes only specified dependency from multiple', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        controller.removeDependency(prerequisiteId: 'a', dependentId: 'c');

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
        expect(dependencies.values.first.prerequisiteId, 'b');
      });
    });

    group('updateDependency', () {
      test('updates dependency type', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(
          prerequisiteId: 'a',
          dependentId: 'b',
          type: DependencyType.finishToStart,
        );

        controller.updateDependency(
          prerequisiteId: 'a',
          dependentId: 'b',
          type: DependencyType.startToFinish,
        );

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.values.first.type, DependencyType.startToFinish);
      });

      test('updates lag days', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(
          prerequisiteId: 'a',
          dependentId: 'b',
          lagDays: 0,
        );

        controller.updateDependency(
          prerequisiteId: 'a',
          dependentId: 'b',
          lagDays: 5,
        );

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.values.first.lagDays, 5);
      });

      test('does nothing when updating non-existent dependency', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');

        // Try to update non-existent dependency
        controller.updateDependency(
          prerequisiteId: 'x',
          dependentId: 'y',
          lagDays: 10,
        );

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
        expect(dependencies.values.first.lagDays, 0);
      });
    });

    group('getDependenciesForTask', () {
      test('returns empty list for task with no dependencies', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');

        final deps = controller.getDependenciesForTask('c');
        expect(deps, isEmpty);
      });

      test('returns all dependencies for task as dependent', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        final deps = controller.getDependenciesForTask('c');
        expect(deps.length, 2);
        expect(deps.every((d) => d.dependentId == 'c'), true);
      });

      test('does not return dependencies where task is prerequisite', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');

        final deps = controller.getDependenciesForTask('a');
        expect(deps, isEmpty);
      });
    });

    group('getDependentsForTask', () {
      test('returns empty list for task with no dependents', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');

        final dependents = controller.getDependentsForTask('b');
        expect(dependents, isEmpty);
      });

      test('returns all dependents for task as prerequisite', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');

        final dependents = controller.getDependentsForTask('a');
        expect(dependents.length, 2);
        expect(dependents.every((d) => d.prerequisiteId == 'a'), true);
      });

      test('does not return dependencies where task is dependent', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'c', dependentId: 'b');

        final dependents = controller.getDependentsForTask('b');
        expect(dependents, isEmpty);
      });
    });

    group('validateAll', () {
      test('returns no cycle for valid dependency graph', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        final result = controller.validateAll();
        expect(result.hasCycle, false);
      });

      test('returns no cycle for empty graph', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        final result = controller.validateAll();
        expect(result.hasCycle, false);
      });
    });

    group('removeDependenciesForTask', () {
      test('removes all dependencies where task is prerequisite', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'd', dependentId: 'e');

        controller.removeDependenciesForTask('a');

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
        expect(dependencies.values.first.prerequisiteId, 'd');
      });

      test('removes all dependencies where task is dependent', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'd', dependentId: 'e');

        controller.removeDependenciesForTask('c');

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
        expect(dependencies.values.first.dependentId, 'e');
      });

      test('removes all dependencies for task in both directions', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');
        controller.addDependency(prerequisiteId: 'd', dependentId: 'e');

        controller.removeDependenciesForTask('b');

        final dependencies = container.read(dependenciesControllerProvider);
        expect(dependencies.length, 1);
        expect(dependencies.values.first.prerequisiteId, 'd');
      });

      test('does nothing when removing non-existent task', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');

        controller.removeDependenciesForTask('z');

        expect(container.read(dependenciesControllerProvider).length, 1);
      });
    });

    group('Providers', () {
      test('dependencyArrowsProvider returns list of dependencies', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        final arrows = container.read(dependencyArrowsProvider);
        expect(arrows.length, 2);
      });

      test('tasksWithDependenciesProvider returns all involved task IDs', () {
        final controller =
            container.read(dependenciesControllerProvider.notifier);

        controller.addDependency(prerequisiteId: 'a', dependentId: 'b');
        controller.addDependency(prerequisiteId: 'b', dependentId: 'c');

        final taskIds = container.read(tasksWithDependenciesProvider);
        expect(taskIds, containsAll(['a', 'b', 'c']));
        expect(taskIds.length, 3);
      });

      test('tasksWithDependenciesProvider returns empty for no dependencies',
          () {
        final taskIds = container.read(tasksWithDependenciesProvider);
        expect(taskIds, isEmpty);
      });
    });
  });
}
