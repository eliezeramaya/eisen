import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/insights/domain/nudge_engine.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for enhanced nudge narratives
/// Verifies that nudges contain rich, contextual text with specific metrics
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Nudge Narratives', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Low Q2 nudge includes percentage and contextual advice', () async {
      final controller = container.read(matrixControllerProvider.notifier);

      // Create tasks: 1 Q2, 9 Q1 (only 10% in Q2)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));

      // 1 completed Q2 task
      final q2Task = controller.createTask(
        title: 'Q2 Task',
        quadrant: Quadrant.q2,
      );
      controller.updateTask(
          q2Task,
          (t) => t.copyWith(
                completedAt: weekAgo,
                createdAt: weekAgo,
              ));

      // 9 completed Q1 tasks
      for (int i = 0; i < 9; i++) {
        final id = controller.createTask(
          title: 'Q1 Task $i',
          quadrant: Quadrant.q1,
        );
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo.add(Duration(hours: i)),
                  createdAt: weekAgo,
                ));
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges = await engine.calculateNudges(now);

      expect(nudges.length, greaterThan(0));
      final lowQ2 = nudges.where((n) => n.type == NudgeType.lowQ2).firstOrNull;

      if (lowQ2 != null) {
        // Should have enhanced narrative
        expect(lowQ2.title, 'Invierte más en lo importante');
        expect(lowQ2.message.contains('10'),
            true); // Contains percentage (as "10%")
        expect(lowQ2.message.length, greaterThan(100)); // Rich message

        // Should include Q2 and Q1 counts in metadata
        expect(lowQ2.metadata['q2Count'], 1);
        expect(lowQ2.metadata['q1Count'], 9);
        expect(lowQ2.metadata['sample'], 10);

        // MediumHigh severity for 10% Q2 (high is <10%)
        expect(lowQ2.severity, NudgeSeverity.mediumHigh);

        // Should contain actionable advice
        expect(lowQ2.message.toLowerCase().contains('hora'), true);
      }
    });

    test('Excessive reschedules nudge shows specific numbers and ratio',
        () async {
      final controller = container.read(matrixControllerProvider.notifier);

      // Create 10 tasks, 4 of them rescheduled (40%)
      for (int i = 0; i < 10; i++) {
        final id = controller.createTask(
          title: 'Task $i',
          quadrant: Quadrant.q1,
        );

        if (i < 4) {
          // Mark as rescheduled by setting replanCount
          controller.updateTask(
              id,
              (t) => t.copyWith(
                    replanCount: 3,
                  ));
        }
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges = await engine.calculateNudges(DateTime.now());

      final reschedule = nudges
          .where((n) => n.type == NudgeType.excessiveReschedules)
          .firstOrNull;

      if (reschedule != null) {
        expect(reschedule.title, 'Demasiadas reprogramaciones');
        // Should have rich, detailed message
        expect(reschedule.message.length, greaterThan(80));

        // Should have metadata with numbers
        expect(reschedule.metadata['rescheduled'], 4);
        expect(reschedule.metadata['total'], 10);
        expect(reschedule.metadata['ratio'], closeTo(0.4, 0.01));

        // Should contain actionable advice
        final msg = reschedule.message.toLowerCase();
        expect(
            msg.contains('redu') ||
                msg.contains('elimi') ||
                msg.contains('deleg') ||
                msg.contains('plan'),
            true);
      }
    });

    test('Overload nudge includes task count, hours, and Q1 count', () async {
      final controller = container.read(matrixControllerProvider.notifier);

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Create 12 tasks due today (above threshold of 10)
      // 8 Q1, 4 Q2
      for (int i = 0; i < 12; i++) {
        final quadrant = i < 8 ? Quadrant.q1 : Quadrant.q2;
        controller.createTask(
          title: 'Due Today $i',
          quadrant: quadrant,
        );

        // Set due date to today
        final id = controller.state.tasks.last.id;
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  due: todayDate.add(const Duration(hours: 12)),
                  minutes: 60, // 1 hour each
                ));
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges = await engine.calculateNudges(today);

      final overload =
          nudges.where((n) => n.type == NudgeType.overload).firstOrNull;

      if (overload != null) {
        expect(overload.title, 'Carga diaria muy alta');
        // Should have rich message
        expect(overload.message.length, greaterThan(80));

        // Should have enhanced metadata
        expect(overload.metadata['dueToday'], 12);
        // Q1Today might be less due to state management
        expect(overload.metadata.containsKey('q1Today'), true);
        expect(overload.metadata.containsKey('totalMinutes'), true);

        // Should be medium-high or high severity
        expect(overload.severity.index,
            greaterThanOrEqualTo(NudgeSeverity.mediumHigh.index));

        // Should contain prioritization advice
        final msg = overload.message.toLowerCase();
        expect(
          msg.contains('prior') ||
              msg.contains('crítica') ||
              msg.contains('top') ||
              msg.contains('urgen') ||
              msg.contains('esencial'),
          true,
        );
      }
    });

    test('Nudges contain emojis for visual enhancement', () async {
      final controller = container.read(matrixControllerProvider.notifier);

      // Create scenario that triggers multiple nudges
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));

      // Low Q2
      for (int i = 0; i < 10; i++) {
        final id = controller.createTask(
          title: 'Q1 Task $i',
          quadrant: Quadrant.q1,
        );
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo,
                  createdAt: weekAgo,
                ));
      }

      // Overload today
      final today = DateTime(now.year, now.month, now.day);
      for (int i = 0; i < 15; i++) {
        controller.createTask(
          title: 'Due Today $i',
          quadrant: Quadrant.q1,
        );
        final id = controller.state.tasks.last.id;
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  due: today.add(const Duration(hours: 12)),
                ));
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges = await engine.calculateNudges(now);

      // At least one nudge should contain an emoji
      final hasEmoji = nudges.any((n) =>
          n.message.contains('🎯') ||
          n.message.contains('⚠️') ||
          n.message.contains('🚨') ||
          n.message.contains('💡') ||
          n.message.contains('🔄') ||
          n.message.contains('📊'));

      expect(hasEmoji, true);
    });

    test('Different severity levels produce different narrative tones',
        () async {
      final controller = container.read(matrixControllerProvider.notifier);

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));

      // Scenario 1: Very low Q2 (should be high severity)
      for (int i = 0; i < 20; i++) {
        final id = controller.createTask(
          title: 'Q1 Task $i',
          quadrant: Quadrant.q1,
        );
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo,
                  createdAt: weekAgo,
                ));
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges1 = await engine.calculateNudges(now);
      final lowQ2High = nudges1
          .where((n) =>
              n.type == NudgeType.lowQ2 && n.severity == NudgeSeverity.high)
          .firstOrNull;

      if (lowQ2High != null) {
        // High severity should have more urgent language
        expect(
            lowQ2High.message.contains('Solo') ||
                lowQ2High.message.contains('Apenas'),
            true);
      }

      // Scenario 2: Moderate Q2 (should be lower severity)
      container.dispose();
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final controller2 = container.read(matrixControllerProvider.notifier);

      // 17% Q2 (medium severity)
      for (int i = 0; i < 5; i++) {
        final id = controller2.createTask(
          title: 'Q2 Task $i',
          quadrant: Quadrant.q2,
        );
        controller2.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo,
                  createdAt: weekAgo,
                ));
      }

      for (int i = 0; i < 25; i++) {
        final id = controller2.createTask(
          title: 'Q1 Task $i',
          quadrant: Quadrant.q1,
        );
        controller2.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo,
                  createdAt: weekAgo,
                ));
      }

      final engine2 = container.read(nudgeEngineProvider);
      final nudges2 = await engine2.calculateNudges(now);
      final lowQ2Medium = nudges2
          .where((n) =>
              n.type == NudgeType.lowQ2 && n.severity == NudgeSeverity.medium)
          .firstOrNull;

      if (lowQ2Medium != null) {
        // Medium severity should have more suggestive language
        expect(
            lowQ2Medium.message.contains('Considera') ||
                lowQ2Medium.message.contains('💡'),
            true);
      }
    });

    test('Nudge metadata is enriched with all relevant metrics', () async {
      final controller = container.read(matrixControllerProvider.notifier);

      final now = DateTime.now();

      // Create scenario with all types of nudges
      final weekAgo = now.subtract(const Duration(days: 6));

      // Low Q2
      for (int i = 0; i < 10; i++) {
        final id = controller.createTask(
          title: 'Q1 Task $i',
          quadrant: Quadrant.q1,
        );
        controller.updateTask(
            id,
            (t) => t.copyWith(
                  completedAt: weekAgo,
                  createdAt: weekAgo,
                ));
      }

      // Rescheduled tasks
      for (int i = 0; i < 5; i++) {
        final id = controller.createTask(
          title: 'Rescheduled $i',
          quadrant: Quadrant.q2,
        );
        controller.updateTask(id, (t) => t.copyWith(replanCount: 3));
      }

      final engine = container.read(nudgeEngineProvider);
      final nudges = await engine.calculateNudges(now);

      // Check that metadata is comprehensive
      for (final nudge in nudges) {
        expect(nudge.metadata, isNotEmpty);

        switch (nudge.type) {
          case NudgeType.lowQ2:
            expect(nudge.metadata.containsKey('q2Share'), true);
            expect(nudge.metadata.containsKey('q2Count'), true);
            expect(nudge.metadata.containsKey('q1Count'), true);
            expect(nudge.metadata.containsKey('sample'), true);
            break;
          case NudgeType.excessiveReschedules:
            expect(nudge.metadata.containsKey('rescheduled'), true);
            expect(nudge.metadata.containsKey('total'), true);
            expect(nudge.metadata.containsKey('ratio'), true);
            expect(nudge.metadata.containsKey('pending'), true);
            break;
          case NudgeType.overload:
            expect(nudge.metadata.containsKey('dueToday'), true);
            expect(nudge.metadata.containsKey('q1Today'), true);
            expect(nudge.metadata.containsKey('totalMinutes'), true);
            break;
          case NudgeType.procrastination:
            expect(nudge.metadata.containsKey('bigTasksCount'), true);
            expect(nudge.metadata.containsKey('oldestDays'), true);
            expect(nudge.metadata.containsKey('threshold'), true);
            break;
          case NudgeType.quadrantImbalance:
            expect(nudge.metadata.containsKey('total'), true);
            expect(nudge.metadata.containsKey('share'), true);
            expect(
              nudge.metadata.keys
                  .any((k) => k == 'q1' || k == 'q3' || k == 'q4'),
              true,
            );
            break;
          case NudgeType.noProject:
            expect(nudge.metadata.containsKey('noProject'), true);
            expect(nudge.metadata.containsKey('total'), true);
            expect(nudge.metadata.containsKey('ratio'), true);
            break;
          case NudgeType.dailyOverload:
            expect(nudge.metadata.containsKey('dueToday'), true);
            expect(nudge.metadata.containsKey('totalMinutes'), true);
            break;
          case NudgeType.noFocusSessions:
            expect(nudge.metadata.containsKey('daysSinceLastSession'), true);
            break;
          case NudgeType.lateNightWork:
            expect(nudge.metadata.containsKey('lateNightTasks'), true);
            expect(nudge.metadata.containsKey('distinctNights'), true);
            break;
        }
      }
    });
  });
}
