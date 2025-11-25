import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/calendar_gantt/presentation/widgets/manage_dependencies_sheet.dart';
import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';

void main() {
  group('ManageDependenciesSheet Widget Tests', () {
    late Task testTask;
    late List<Task> allTasks;

    setUp(() {
      testTask = Task(
        id: 'task-1',
        title: 'Test Task',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 60,
      );

      allTasks = [
        testTask,
        Task(
          id: 'task-2',
          title: 'Prerequisite Task',
          quadrant: Quadrant.q2,
          priority: 3,
          minutes: 30,
        ),
        Task(
          id: 'task-3',
          title: 'Another Task',
          quadrant: Quadrant.q3,
          priority: 2,
          minutes: 45,
        ),
      ];
    });

    Widget buildWidget({List<Task>? tasks}) {
      return ProviderScope(
        overrides: [
          matrixTasksProvider.overrideWith((ref) => tasks ?? allTasks),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ManageDependenciesSheet(task: testTask),
          ),
        ),
      );
    }

    testWidgets('displays task title in header', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Dependencies for "Test Task"'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('closes sheet when close button tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixTasksProvider.overrideWith((ref) => allTasks),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => ManageDependenciesSheet(task: testTask),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Dependencies for "Test Task"'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Dependencies for "Test Task"'), findsNothing);
    });

    testWidgets('displays empty state when no dependencies', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.textContaining('No dependencies yet'), findsOneWidget);
    });

    testWidgets('displays available tasks dropdown', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Should show dropdown for selecting prerequisite
      expect(find.text('Select prerequisite task'), findsOneWidget);
    });

    testWidgets('dropdown shows available tasks excluding self',
        (tester) async {
      await tester.pumpWidget(buildWidget());

      // Tap dropdown
      await tester.tap(find.text('Select prerequisite task'));
      await tester.pumpAndSettle();

      // Should show other tasks but not self
      expect(find.text('Prerequisite Task').hitTestable(), findsOneWidget);
      expect(find.text('Another Task').hitTestable(), findsOneWidget);
      expect(find.text('Test Task').hitTestable(), findsNothing);
    });

    testWidgets('displays dependency type selector', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Should have type selector (default to Finish-to-Start)
      expect(find.textContaining('Finish-to-Start'), findsOneWidget);
    });

    testWidgets('can change dependency type', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Tap type selector
      await tester.tap(find.textContaining('Finish-to-Start'));
      await tester.pumpAndSettle();

      // Should show all 4 types
      expect(
        find.textContaining('Start-to-Start').hitTestable(),
        findsOneWidget,
      );
      expect(
        find.textContaining('Finish-to-Finish').hitTestable(),
        findsOneWidget,
      );
      expect(
        find.textContaining('Start-to-Finish').hitTestable(),
        findsOneWidget,
      );

      // Select different type
      await tester.tap(find.textContaining('Start-to-Start').hitTestable());
      await tester.pumpAndSettle();

      // Should update selection
      expect(find.textContaining('Start-to-Start'), findsOneWidget);
    });

    testWidgets('displays add dependency button', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(
        find.byKey(const ValueKey('add-dependency-button')),
        findsOneWidget,
      );
    });

    testWidgets('add button is disabled when no task selected', (tester) async {
      await tester.pumpWidget(buildWidget());

      final addButton = find.byKey(const ValueKey('add-dependency-button'));
      expect(addButton, findsOneWidget);

      // Button should be present (exact disabled state depends on implementation)
      final button = tester.widget<FilledButton>(
        addButton,
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('can add a dependency', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Select a prerequisite task
      await tester.tap(find.text('Select prerequisite task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prerequisite Task').hitTestable());
      await tester.pumpAndSettle();

      // Tap add button
      final addButton = find.byKey(const ValueKey('add-dependency-button'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Should show the added dependency in the list
      expect(find.text('Prerequisite Task'), findsWidgets);
      expect(find.textContaining('No dependencies yet'), findsNothing);
    });

    testWidgets('displays existing dependencies', (tester) async {
      // Create a container with pre-existing dependency
      final container = ProviderContainer(
        overrides: [
          matrixTasksProvider.overrideWith((ref) => allTasks),
        ],
      );

      // Add a dependency
      final controller =
          container.read(dependenciesControllerProvider.notifier);
      controller.addDependency(
        prerequisiteId: 'task-2',
        dependentId: 'task-1',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ManageDependenciesSheet(task: testTask),
            ),
          ),
        ),
      );

      // Should display existing dependency
      expect(find.text('Prerequisite Task'), findsOneWidget);
      expect(
        find.text('Starts when prerequisite finishes'),
        findsWidgets,
      );
    });

    testWidgets('can remove an existing dependency', (tester) async {
      final container = ProviderContainer(
        overrides: [
          matrixTasksProvider.overrideWith((ref) => allTasks),
        ],
      );

      final controller =
          container.read(dependenciesControllerProvider.notifier);
      controller.addDependency(
        prerequisiteId: 'task-2',
        dependentId: 'task-1',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ManageDependenciesSheet(task: testTask),
            ),
          ),
        ),
      );

      expect(find.text('Prerequisite Task'), findsOneWidget);

      // Find and tap remove button (delete icon)
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Dependency should be removed
      expect(find.textContaining('No dependencies yet'), findsOneWidget);
    });

    testWidgets('shows error message when adding cyclic dependency',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          matrixTasksProvider.overrideWith((ref) => allTasks),
        ],
      );

      // Create dependency task-2 -> task-1
      final controller =
          container.read(dependenciesControllerProvider.notifier);
      controller.addDependency(
        prerequisiteId: 'task-2',
        dependentId: 'task-1',
      );

      // Now open sheet for task-2 and try to add task-1 as prerequisite (would create cycle)
      final task2 = allTasks[1];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ManageDependenciesSheet(task: task2),
            ),
          ),
        ),
      );

      // Select task-1 as prerequisite
      await tester.tap(find.text('Select prerequisite task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Task').hitTestable());
      await tester.pumpAndSettle();

      // Try to add (should fail with cycle error)
      final addButton = find.byKey(const ValueKey('add-dependency-button'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(
        find.textContaining('Cycle', findRichText: true),
        findsOneWidget,
        reason: 'Should display error message about cycle',
      );
    });

    testWidgets('hides already dependent tasks from dropdown', (tester) async {
      final container = ProviderContainer(
        overrides: [
          matrixTasksProvider.overrideWith((ref) => allTasks),
        ],
      );

      // Add task-2 as prerequisite
      final controller =
          container.read(dependenciesControllerProvider.notifier);
      controller.addDependency(
        prerequisiteId: 'task-2',
        dependentId: 'task-1',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ManageDependenciesSheet(task: testTask),
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('Select prerequisite task'));
      await tester.pumpAndSettle();

      // task-2 should not appear (already a dependency)
      // task-3 should appear
      expect(find.text('Another Task').hitTestable(), findsOneWidget);
      expect(find.text('Prerequisite Task').hitTestable(), findsNothing);
    });
  });
}
