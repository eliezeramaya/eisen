import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _nextTick() =>
    Future<void>.delayed(const Duration(milliseconds: 1));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gantt Integration with Real Tasks', () {
    test('calendarSpansProvider converts tasks with due dates to spans',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Create tasks with due dates
      final controller = container.read(matrixControllerProvider.notifier);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = now.add(const Duration(days: 7));

      final id1 = controller.createTask(quadrant: Quadrant.q1, title: 'Task 1');
      controller.updateTask(
          id1,
          (t) => t.copyWith(
                priority: 3,
                minutes: 120, // 2 hours -> 1 day span
                due: tomorrow,
              ));

      await _nextTick();
      final id2 = controller.createTask(quadrant: Quadrant.q2, title: 'Task 2');
      controller.updateTask(
          id2,
          (t) => t.copyWith(
                priority: 2,
                minutes: 480, // 8 hours -> 2 days span
                due: nextWeek,
              ));

      // Verify spans are created
      final spans = container.read(calendarSpansProvider);

      expect(spans.length, 2);
      expect(spans[0].title, 'Task 1');
      expect(spans[1].title, 'Task 2');

      // Verify span kinds match quadrants
      expect(spans[0].kind, GanttKind.dev); // Q1 -> dev
      expect(spans[1].kind, GanttKind.design); // Q2 -> design
    });

    test('completed tasks are filtered out from Gantt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(matrixControllerProvider.notifier);
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Create two tasks
      final id1 =
          controller.createTask(quadrant: Quadrant.q1, title: 'Active Task');
      controller.updateTask(
          id1,
          (t) => t.copyWith(
                minutes: 60,
                due: tomorrow,
              ));

      await _nextTick();
      final id2 =
          controller.createTask(quadrant: Quadrant.q1, title: 'Completed Task');
      controller.updateTask(
          id2,
          (t) => t.copyWith(
                minutes: 60,
                due: tomorrow,
              ));

      // Complete one task
      controller.updateTask(
          id2, (t) => t.copyWith(completedAt: DateTime.now()));

      // Verify only active task appears in Gantt
      final spans = container.read(calendarSpansProvider);

      expect(spans.length, 1,
          reason: 'spans=$spans tasks=${container.read(matrixTasksProvider)}');
      expect(spans[0].title, 'Active Task');
      expect(spans[0].id, id1);
    });

    test('tasks without due dates are filtered out', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(matrixControllerProvider.notifier);
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final id1 = controller.createTask(
          quadrant: Quadrant.q1, title: 'Task with due date');
      controller.updateTask(id1, (t) => t.copyWith(due: tomorrow));

      await _nextTick();
      controller.createTask(
          quadrant: Quadrant.q2, title: 'Task without due date');
      // Don't add due date

      final spans = container.read(calendarSpansProvider);

      expect(spans.length, 1);
      expect(spans[0].title, 'Task with due date');
    });

    test('span duration is estimated from task minutes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(matrixControllerProvider.notifier);
      final dueDate = DateTime(2025, 3, 15);

      // Short task: < 60 min -> 1 day
      final id1 = controller.createTask(quadrant: Quadrant.q1, title: 'Short');
      controller.updateTask(id1, (t) => t.copyWith(minutes: 30, due: dueDate));

      // Medium task: 180 min -> 2 days
      await _nextTick();
      final id2 = controller.createTask(quadrant: Quadrant.q1, title: 'Medium');
      controller.updateTask(id2, (t) => t.copyWith(minutes: 180, due: dueDate));

      // Long task: 720 min (12 hours) -> 2 days (ceil(720/360))
      await _nextTick();
      final id3 = controller.createTask(quadrant: Quadrant.q1, title: 'Long');
      controller.updateTask(id3, (t) => t.copyWith(minutes: 720, due: dueDate));

      final spans = container.read(calendarSpansProvider);

      expect(spans.length, 3);

      // Verify span durations
      final shortDuration = spans[0].end.difference(spans[0].start).inDays;
      final mediumDuration = spans[1].end.difference(spans[1].start).inDays;
      final longDuration = spans[2].end.difference(spans[2].start).inDays;

      expect(shortDuration, 1); // < 60 min
      expect(mediumDuration, 3); // 180 min hits the 3-day bucket (<360)
      expect(longDuration, 2); // ceil(720/360)
    });

    test('span end date matches task due date', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(matrixControllerProvider.notifier);
      final dueDate = DateTime(2025, 3, 15, 23, 59); // With time component

      final id = controller.createTask(quadrant: Quadrant.q1, title: 'Task');
      controller.updateTask(id, (t) => t.copyWith(minutes: 60, due: dueDate));

      final spans = container.read(calendarSpansProvider);

      expect(spans.length, 1);

      // Span end should be exclusive: day after due date at midnight
      final expectedEnd = DateTime(2025, 3, 16);
      expect(spans[0].end, expectedEnd);

      // Verify we can convert back: due = end - 1 day
      final reconstructedDue = spans[0].end.subtract(const Duration(days: 1));
      expect(reconstructedDue.year, dueDate.year);
      expect(reconstructedDue.month, dueDate.month);
      expect(reconstructedDue.day, dueDate.day);
    });

    test('lanesProvider assigns non-overlapping lanes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(matrixControllerProvider.notifier);

      // Create overlapping tasks
      final baseDate = DateTime(2025, 3, 10);

      final id1 = controller.createTask(quadrant: Quadrant.q1, title: 'Task 1');
      controller.updateTask(
          id1,
          (t) => t.copyWith(
                minutes: 180, // 3 days
                due: baseDate.add(const Duration(days: 3)),
              ));

      await _nextTick();
      final id2 = controller.createTask(quadrant: Quadrant.q1, title: 'Task 2');
      controller.updateTask(
          id2,
          (t) => t.copyWith(
                minutes: 180, // 3 days, overlaps with Task 1
                due: baseDate.add(const Duration(days: 4)),
              ));

      await _nextTick();
      final id3 = controller.createTask(quadrant: Quadrant.q1, title: 'Task 3');
      controller.updateTask(
          id3,
          (t) => t.copyWith(
                minutes: 60, // 1 day, after both
                due: baseDate.add(const Duration(days: 7)),
              ));

      final spans = container.read(lanesProvider);

      expect(spans.length, 3);
      final details =
          spans.map((s) => '${s.id}:${s.start}..${s.end} lane=${s.lane}');

      // Verify all spans have assigned lanes (not -1)
      expect(spans.every((s) => s.lane >= 0), true);

      // Verify overlapping tasks are in different lanes
      expect(spans[0].lane != spans[1].lane, true,
          reason:
              'lanes=${spans.map((s) => s.lane).toList()} details=$details');

      // Task 3 should be able to reuse a lane since it doesn't overlap
      expect(spans[2].lane, isIn([spans[0].lane, spans[1].lane]));
    });
  });
}
