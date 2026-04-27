import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weight() monotonicity and bounds', () {
    final baseTask = Task(
      id: 'test-1',
      title: 'Test Task',
      quadrant: Quadrant.q1,
      priority: 5,
      minutes: 60,
      due: null,
      tags: const [],
      notes: '',
      category: '',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: null,
      completedAt: null,
      replanCount: 0,
      snoozeCount: 0,
      normalizedPriority: null,
      normalizedMinutes: null,
    );

    test('weight is monotone with respect to due date proximity', () {
      // Tasks with earlier due dates should have >= weight than later ones
      final now = DateTime(2025, 1, 15, 12, 0);

      final task1DayAway =
          baseTask.copyWith(due: now.add(const Duration(days: 1)));
      final task3DaysAway =
          baseTask.copyWith(due: now.add(const Duration(days: 3)));
      final task7DaysAway =
          baseTask.copyWith(due: now.add(const Duration(days: 7)));
      final task30DaysAway =
          baseTask.copyWith(due: now.add(const Duration(days: 30)));

      final w1 = weight(task1DayAway);
      final w3 = weight(task3DaysAway);
      final w7 = weight(task7DaysAway);
      final w30 = weight(task30DaysAway);

      // Monotonicity: closer due dates have higher weights
      expect(w1 >= w3, isTrue,
          reason: '1 day away should weigh >= 3 days away');
      expect(w3 >= w7, isTrue,
          reason: '3 days away should weigh >= 7 days away');
      expect(w7 >= w30, isTrue,
          reason: '7 days away should weigh >= 30 days away');
    });

    test('weight is monotone with respect to priority', () {
      final low = baseTask.copyWith(priority: 2);
      final mid = baseTask.copyWith(priority: 5);
      final high = baseTask.copyWith(priority: 9);

      final wLow = weight(low);
      final wMid = weight(mid);
      final wHigh = weight(high);

      expect(wHigh > wMid, isTrue,
          reason: 'Priority 9 should weigh > priority 5');
      expect(wMid > wLow, isTrue,
          reason: 'Priority 5 should weigh > priority 2');
    });

    test('weight is monotone with respect to minutes', () {
      final short = baseTask.copyWith(minutes: 15);
      final medium = baseTask.copyWith(minutes: 60);
      final long = baseTask.copyWith(minutes: 180);

      final wShort = weight(short);
      final wMedium = weight(medium);
      final wLong = weight(long);

      expect(wLong > wMedium, isTrue, reason: '180 min should weigh > 60 min');
      expect(wMedium > wShort, isTrue, reason: '60 min should weigh > 15 min');
    });

    test('quadrant-aware order is Q1 > Q2 > Q3 > Q4 (same other params)', () {
      final urgentQ1 =
          baseTask.copyWith(quadrant: Quadrant.q1); // Urgent & Important
      final urgentQ3 =
          baseTask.copyWith(quadrant: Quadrant.q3); // Urgent & Not Important
      final notUrgentQ2 =
          baseTask.copyWith(quadrant: Quadrant.q2); // Not Urgent & Important
      final notUrgentQ4 = baseTask.copyWith(
          quadrant: Quadrant.q4); // Not Urgent & Not Important

      final wQ1 = weight(urgentQ1);
      final wQ3 = weight(urgentQ3);
      final wQ2 = weight(notUrgentQ2);
      final wQ4 = weight(notUrgentQ4);

      expect(wQ1 > wQ2, isTrue, reason: 'Q1 should weigh > Q2');
      expect(wQ2 > wQ3, isTrue,
          reason: 'Q2 growth should stay visible above Q3');
      expect(wQ3 > wQ4, isTrue, reason: 'Q3 should weigh > Q4');
    });

    test('weight handles null due date gracefully (base dueBoost = 1.0)', () {
      final withDue = baseTask.copyWith(due: DateTime(2025, 1, 20));
      final noDue = baseTask.copyWith(due: null);

      final wWithDue = weight(withDue);
      final wNoDue = weight(noDue);

      // Both should be valid, finite, positive numbers
      expect(wWithDue.isFinite, isTrue);
      expect(wWithDue > 0, isTrue);
      expect(wNoDue.isFinite, isTrue);
      expect(wNoDue > 0, isTrue);

      // No due date uses dueBoost = 1.0, so if due is far away, noDue might be > withDue
      // Just verify both are reasonable
    });

    test('weight handles past due dates (daysToDue clamped to 0)', () {
      // Note: This test is time-dependent since weight() uses DateTime.now()
      // We can only verify the result is valid, not specific comparisons
      final now = DateTime.now();
      final pastDue = baseTask.copyWith(
        due: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 10)),
      );

      final w = weight(pastDue);

      // Should get maximum dueBoost (1.25) due to exp(-0.7 * 0) = 1
      expect(w.isFinite, isTrue);
      expect(w > 0, isTrue);

      // Verify it's a reasonable weight value
      expect(w > 10, isTrue, reason: 'Past due should have substantial weight');
    });

    test('weight is always finite and non-negative', () {
      // Test edge cases
      final tasks = [
        baseTask.copyWith(priority: 1, minutes: 5), // Min values
        baseTask.copyWith(priority: 10, minutes: 240), // Max values
        baseTask.copyWith(priority: 0, minutes: 0), // Below min (should clamp)
        baseTask.copyWith(
            priority: 15, minutes: 500), // Above max (should clamp)
        baseTask.copyWith(due: null), // No due date
        baseTask.copyWith(due: DateTime(2025, 1, 1)), // Due date
        baseTask.copyWith(
          createdAt: DateTime(2020, 1, 1),
          updatedAt: DateTime(2020, 1, 1),
        ), // Very stale
      ];

      for (final task in tasks) {
        final w = weight(task);
        expect(w.isFinite, isTrue,
            reason: 'Weight must be finite for task: ${task.title}');
        expect(w.isNaN, isFalse,
            reason: 'Weight must not be NaN for task: ${task.title}');
        expect(w >= 0, isTrue,
            reason: 'Weight must be non-negative for task: ${task.title}');
      }
    });

    test('weight output is within documented range', () {
      // Min: priority=1, minutes=5, low quadrant boost, max decay
      final minTask = Task(
        id: 'min',
        title: 'Min',
        quadrant: Quadrant.q4,
        priority: 1,
        minutes: 5,
        due: null, // No due boost
        tags: const [],
        notes: '',
        category: '',
        createdAt: DateTime(2020, 1, 1), // Very stale for max decay
        updatedAt: DateTime(2020, 1, 1),
        completedAt: null,
        replanCount: 0,
        snoozeCount: 0,
        normalizedPriority: null,
        normalizedMinutes: null,
      );

      // Max: priority=10, minutes=240, Q1, due soon, fresh
      final now = DateTime.now();
      final maxTask = Task(
        id: 'max',
        title: 'Max',
        quadrant: Quadrant.q1, // Urgent
        priority: 10,
        minutes: 240,
        due: now.add(const Duration(
            hours: 1)), // Due very soon for high boost, but not past
        tags: const [],
        notes: '',
        category: '',
        createdAt: now, // Fresh
        updatedAt: now,
        completedAt: null,
        replanCount: 0,
        snoozeCount: 0,
        normalizedPriority: null,
        normalizedMinutes: null,
      );

      final wMin = weight(minTask);
      final wMax = weight(maxTask);

      expect(wMin >= 1.0, isTrue, reason: 'Min weight should stay positive');
      expect(wMin <= 4.0, isTrue, reason: 'Min weight should stay compact');
      // Max weight can vary significantly depending on due date timing
      expect(wMax >= 200, isTrue, reason: 'Max weight should be substantial');
      expect(wMax.isFinite, isTrue, reason: 'Max weight must be finite');
      expect(wMax > 0, isTrue, reason: 'Max weight must be positive');

      // Max should be significantly larger than min
      expect(wMax > wMin * 50, isTrue,
          reason: 'Max weight should be much larger than min');
    });

    test('freshness decay reduces weight for stale tasks', () {
      // Note: weight() uses DateTime.now() internally, so we test relative decay
      // Freshness factor is (0.75 + 0.25 * exp(-0.15 * days)), so decay is gradual
      final now = DateTime.now();

      final fresh = baseTask.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      final stale30Days = baseTask.copyWith(
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );

      final stale180Days = baseTask.copyWith(
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 180)),
      );

      final wFresh = weight(fresh);
      final wStale30 = weight(stale30Days);
      final wStale180 = weight(stale180Days);

      // Freshness should decay: fresh >= stale30 >= stale180
      // Using >= because the decay is gradual (factor ranges from 1.0 to 0.75)
      expect(wFresh >= wStale30, isTrue,
          reason: 'Fresh task should weigh >= 30-day stale');
      expect(wStale30 >= wStale180, isTrue,
          reason: '30-day stale should weigh >= 180-day stale');

      // Verify all weights are valid
      expect(wFresh > 0 && wFresh.isFinite, isTrue);
      expect(wStale30 > 0 && wStale30.isFinite, isTrue);
      expect(wStale180 > 0 && wStale180.isFinite, isTrue);
    });
  });
}
