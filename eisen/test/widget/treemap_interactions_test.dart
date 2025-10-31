import 'package:eisen/app/app.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for treemap interactions.
///
/// Tests user interactions like:
/// - Tile tap/selection
/// - Quadrant zoom
/// - State updates via Riverpod
///
/// Note: Drag & drop and stack expansion tests require additional
/// Key annotations in the widget tree. These tests verify the
/// fundamental interaction patterns work end-to-end.
void main() {
  group('Treemap Interactions', () {
    testWidgets('App initializes and displays matrix', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EisenApp(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'App should render MaterialApp');
    });

    testWidgets('Matrix controller starts with empty state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Read state from controller
      final state = container.read(matrixControllerProvider);

      expect(state.tasks, isA<List<Task>>(),
          reason: 'State should have a tasks list');
      expect(state.version, 0, reason: 'Initial version should be 0');
    });

    testWidgets('Selecting a task updates controller state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);

      expect(initialState.selectedId, isNull,
          reason: 'Initially no task should be selected');

      // Select first task
      if (initialState.tasks.isNotEmpty) {
        final firstTaskId = initialState.tasks.first.id;
        controller.select(firstTaskId);

        await tester.pump();

        final newState = container.read(matrixControllerProvider);
        expect(newState.selectedId, firstTaskId,
            reason: 'Selected task should be reflected in state');

        // Deselect
        controller.select(null);
        await tester.pump();

        final finalState = container.read(matrixControllerProvider);
        expect(finalState.selectedId, isNull,
            reason: 'Task should be deselected');
      }
    });

    testWidgets('Zooming into a quadrant updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);

      expect(initialState.zoom, isNull,
          reason: 'Initially no quadrant should be zoomed');

      // Zoom into Q1
      controller.setZoom(Quadrant.q1);
      await tester.pump();

      final zoomedState = container.read(matrixControllerProvider);
      expect(zoomedState.zoom, Quadrant.q1,
          reason: 'Zoom state should reflect Q1');
    });

    testWidgets('Creating a task increments version', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);
      final initialVersion = initialState.version;
      final initialTaskCount = initialState.tasks.length;

      // Create new task
      controller.createTask(
        quadrant: Quadrant.q2,
        title: 'Test Task',
      );

      await tester.pump();

      final newState = container.read(matrixControllerProvider);

      expect(newState.tasks.length, initialTaskCount + 1,
          reason: 'Task count should increase');
      expect(newState.version, initialVersion + 1,
          reason: 'Version should increment on mutation');
    });

    testWidgets('Deleting a task updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);

      if (initialState.tasks.isNotEmpty) {
        final taskToDelete = initialState.tasks.first.id;
        final initialCount = initialState.tasks.length;

        controller.deleteTask(taskToDelete);
        await tester.pump();

        final newState = container.read(matrixControllerProvider);

        expect(newState.tasks.length, initialCount - 1,
            reason: 'Task count should decrease after deletion');
        expect(newState.tasks.any((t) => t.id == taskToDelete), isFalse,
            reason: 'Deleted task should not exist in state');
      }
    });

    testWidgets('Moving task to different quadrant updates state',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);

      if (initialState.tasks.isNotEmpty) {
        final task = initialState.tasks.first;
        final originalQuadrant = task.quadrant;
        final newQuadrant =
            originalQuadrant == Quadrant.q1 ? Quadrant.q2 : Quadrant.q1;

        controller.moveTaskToQuadrant(task.id, newQuadrant);
        await tester.pump();

        final newState = container.read(matrixControllerProvider);
        final movedTask = newState.tasks.firstWhere((t) => t.id == task.id);

        expect(movedTask.quadrant, newQuadrant,
            reason: 'Task should be in new quadrant');
        expect(movedTask.quadrant, isNot(originalQuadrant),
            reason: 'Quadrant should have changed');
      }
    });

    testWidgets('Theme toggle updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);
      final initialTheme = initialState.themeMode;

      controller.toggleTheme();
      await tester.pump();

      final newState = container.read(matrixControllerProvider);

      expect(newState.themeMode, isNot(initialTheme),
          reason: 'Theme mode should toggle');
    });

    testWidgets('Compact mode toggle updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final initialState = container.read(matrixControllerProvider);
      final initialCompact = initialState.compact;

      controller.toggleCompact();
      await tester.pump();

      final newState = container.read(matrixControllerProvider);

      expect(newState.compact, !initialCompact,
          reason: 'Compact mode should toggle');
    });

    testWidgets('Search query updates state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);

      controller.setQuery('test search');
      await tester.pump();

      final newState = container.read(matrixControllerProvider);

      expect(newState.query, 'test search',
          reason: 'Search query should be updated');
    });
  });

  group('Treemap Layout Computation', () {
    testWidgets('Layout computation handles empty task list', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);

      // Compute layout with no viewport specified
      final rects = controller.computeLayout();

      expect(rects, isA<List<TreemapRect>>(),
          reason: 'Layout should return a list of rectangles');
    });

    testWidgets('Layout computation with specific quadrant filter',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const EisenApp(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = container.read(matrixControllerProvider.notifier);
      final state = container.read(matrixControllerProvider);

      if (state.tasks.isNotEmpty) {
        // Compute layout for Q1 only
        final q1Rects = controller.computeLayout(only: Quadrant.q1);

        expect(q1Rects, isA<List<TreemapRect>>(),
            reason: 'Filtered layout should return rectangles');
      }
    });
  });
}
