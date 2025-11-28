import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BanditService stability and reproducibility', () {
    final sampleTasks = [
      Task(
        id: 'task-1',
        title: 'First Task',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 60,
        due: DateTime(2025, 1, 20),
        tags: const [],
        notes: '',
        category: '',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 10),
        completedAt: null,
        replanCount: 0,
        snoozeCount: 0,
        normalizedPriority: null,
        normalizedMinutes: null,
      ),
      Task(
        id: 'task-2',
        title: 'Second Task',
        quadrant: Quadrant.q1,
        priority: 7,
        minutes: 30,
        due: DateTime(2025, 1, 22),
        tags: const [],
        notes: '',
        category: '',
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 12),
        completedAt: null,
        replanCount: 0,
        snoozeCount: 0,
        normalizedPriority: null,
        normalizedMinutes: null,
      ),
      Task(
        id: 'task-3',
        title: 'Third Task',
        quadrant: Quadrant.q1,
        priority: 5,
        minutes: 45,
        due: DateTime(2025, 1, 21),
        tags: const [],
        notes: '',
        category: '',
        createdAt: DateTime(2025, 1, 3),
        updatedAt: DateTime(2025, 1, 11),
        completedAt: null,
        replanCount: 0,
        snoozeCount: 0,
        normalizedPriority: null,
        normalizedMinutes: null,
      ),
    ];

    test('same seed + same tasks = same ordering (reproducibility)', () {
      final bandit1 = BanditService(seed: 42);
      final bandit2 = BanditService(seed: 42);

      final ranks1 = bandit1.tieBreakRanks(sampleTasks, Quadrant.q1);
      final ranks2 = bandit2.tieBreakRanks(sampleTasks, Quadrant.q1);

      // Same seed should produce identical rankings
      expect(ranks1.length, ranks2.length);
      for (final id in ranks1.keys) {
        expect(ranks1[id], ranks2[id],
            reason: 'Task $id should have same rank with same seed');
      }
    });

    test('different seeds = potentially different ordering', () {
      final bandit1 = BanditService(seed: 42);
      final bandit2 = BanditService(seed: 123);

      final ranks1 = bandit1.tieBreakRanks(sampleTasks, Quadrant.q1);
      final ranks2 = bandit2.tieBreakRanks(sampleTasks, Quadrant.q1);

      // Different seeds may produce different rankings due to noise
      // Not guaranteed to be different, but very likely
      expect(ranks1.length, ranks2.length);
      // At least verify both are valid rankings
      for (final id in ['task-1', 'task-2', 'task-3']) {
        expect(ranks1.containsKey(id), isTrue);
        expect(ranks2.containsKey(id), isTrue);
      }
    });

    test('same seed produces stable pickTopSpot across calls', () {
      final bandit1 = BanditService(seed: 42);
      final bandit2 = BanditService(seed: 42);

      final top1 = bandit1.pickTopSpot(sampleTasks, Quadrant.q1);
      final top2 = bandit2.pickTopSpot(sampleTasks, Quadrant.q1);

      expect(top1, top2, reason: 'Same seed should pick same top spot');
      expect(top1, isNotNull);
      expect(['task-1', 'task-2', 'task-3'].contains(top1), isTrue);
    });

    test('Q2 urgent tasks get priority in tie-breaks', () {
      final now = DateTime.now();
      final urgentTasks = [
        Task(
          id: 'q2-urgent',
          title: 'Urgent Q2',
          quadrant: Quadrant.q2,
          priority: 5,
          minutes: 60,
          due: now.add(const Duration(hours: 24)), // Due in 24h (< 48h)
          tags: const [],
          notes: '',
          category: '',
          createdAt: now,
          updatedAt: now,
          completedAt: null,
          replanCount: 0,
          snoozeCount: 0,
          normalizedPriority: null,
          normalizedMinutes: null,
        ),
        Task(
          id: 'q2-normal',
          title: 'Normal Q2',
          quadrant: Quadrant.q2,
          priority: 7, // Higher priority
          minutes: 60,
          due: now.add(const Duration(days: 7)), // Due in 7 days (> 48h)
          tags: const [],
          notes: '',
          category: '',
          createdAt: now,
          updatedAt: now,
          completedAt: null,
          replanCount: 0,
          snoozeCount: 0,
          normalizedPriority: null,
          normalizedMinutes: null,
        ),
      ];

      final bandit = BanditService(seed: 42);
      final ranks = bandit.tieBreakRanks(urgentTasks, Quadrant.q2);

      // Q2 urgent task should have better rank despite lower priority
      expect(ranks['q2-urgent']!, lessThan(ranks['q2-normal']!),
          reason: 'Q2 task due < 48h should rank higher');
    });

    test('tieBreakRanks handles empty task list', () {
      final bandit = BanditService(seed: 42);
      final ranks = bandit.tieBreakRanks([], Quadrant.q1);

      expect(ranks, isEmpty);
    });

    test('pickTopSpot returns null for empty task list', () {
      final bandit = BanditService(seed: 42);
      final top = bandit.pickTopSpot([], Quadrant.q1);

      expect(top, isNull);
    });

    test('tieBreakRanks assigns unique ranks to all tasks', () {
      final bandit = BanditService(seed: 42);
      final ranks = bandit.tieBreakRanks(sampleTasks, Quadrant.q1);

      // All tasks should have ranks
      expect(ranks.length, sampleTasks.length);

      // All ranks should be unique
      final rankValues = ranks.values.toSet();
      expect(rankValues.length, sampleTasks.length,
          reason: 'Each task should have a unique rank');

      // Ranks should be in valid range [0, n-1]
      for (final rank in rankValues) {
        expect(rank >= 0, isTrue);
        expect(rank < sampleTasks.length, isTrue);
      }
    });

    test('seed is publicly accessible for debugging', () {
      final bandit = BanditService(seed: 123);
      expect(bandit.seed, 123);

      final defaultBandit = BanditService();
      expect(defaultBandit.seed, 42, reason: 'Default seed should be 42');
    });

    test('repeated calls with same seed produce consistent results', () {
      // Verify that creating new BanditService instances with same seed
      // produces stable results across multiple invocations
      final results = <Map<String, int>>[];

      for (var i = 0; i < 5; i++) {
        final bandit = BanditService(seed: 99);
        final ranks = bandit.tieBreakRanks(sampleTasks, Quadrant.q1);
        results.add(ranks);
      }

      // All results should be identical
      final first = results.first;
      for (var i = 1; i < results.length; i++) {
        expect(results[i].length, first.length);
        for (final id in first.keys) {
          expect(results[i][id], first[id],
              reason: 'Iteration $i should match first iteration for task $id');
        }
      }
    });
  });
}
