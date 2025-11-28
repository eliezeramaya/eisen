import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BanditService', () {
    test('prioritizes urgent Q2 tasks within 48h', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 'urgent-q2',
          title: 'Prepare deck',
          quadrant: Quadrant.q2,
          priority: 5,
          minutes: 30,
          due: now.add(const Duration(hours: 24)), // within 48h guardrail
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        Task(
          id: 'later-q2',
          title: 'Plan sprint',
          quadrant: Quadrant.q2,
          priority: 9,
          minutes: 45,
          due: now.add(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final service = BanditService(seed: 7);
      final ranks = service.tieBreakRanks(tasks, Quadrant.q2);

      expect(ranks['urgent-q2'], 0, reason: 'Urgent Q2 tasks should lead ties');
      expect(ranks.length, tasks.length);
      expect(service.pickTopSpot(tasks, Quadrant.q2), 'urgent-q2');
    });

    test('returns empty ranks and null when no tasks', () {
      final service = BanditService();
      expect(service.tieBreakRanks(const [], Quadrant.q1), isEmpty);
      expect(service.pickTopSpot(const [], Quadrant.q1), isNull);
    });

    test('produces stable ordering for same seed and tasks', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 'a',
          title: 'A',
          quadrant: Quadrant.q1,
          priority: 6,
          minutes: 20,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        Task(
          id: 'b',
          title: 'B',
          quadrant: Quadrant.q1,
          priority: 6,
          minutes: 20,
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
        Task(
          id: 'c',
          title: 'C',
          quadrant: Quadrant.q1,
          priority: 6,
          minutes: 20,
          createdAt: now.subtract(const Duration(hours: 10)),
        ),
      ];

      final s1 = BanditService(seed: 99);
      final s2 = BanditService(seed: 99);
      final ranks1 = s1.tieBreakRanks(tasks, Quadrant.q1);
      final ranks2 = s2.tieBreakRanks(tasks, Quadrant.q1);

      expect(ranks1, ranks2,
          reason: 'Same seed + same tasks should yield deterministic ordering');
      expect(s1.pickTopSpot(tasks, Quadrant.q1), isIn(['a', 'b', 'c']));
    });
  });
}
