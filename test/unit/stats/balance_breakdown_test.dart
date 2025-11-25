import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/domain/calculators.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  group('BalanceBreakdown', () {
    test('counts tasks per quadrant inside window', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 8);
      final tasks = [
        buildTask(
          id: 'q1',
          quadrant: Quadrant.q1,
          completedAt: DateTime(2025, 1, 2, 10),
        ),
        buildTask(
          id: 'q2',
          quadrant: Quadrant.q2,
          completedAt: DateTime(2025, 1, 3, 12),
        ),
        buildTask(
          id: 'q3',
          quadrant: Quadrant.q3,
          updatedAt: DateTime(2025, 1, 4, 9),
        ),
        buildTask(
          id: 'out-of-range',
          quadrant: Quadrant.q4,
          completedAt: DateTime(2024, 12, 31, 23),
        ),
      ];

      final breakdown = weeklyBalance(tasks, start, end);

      expect(breakdown.q1, 1);
      expect(breakdown.q2, 1);
      expect(breakdown.q3, 1);
      expect(breakdown.q4, 0);
    });

    test('handles single quadrant dominance', () {
      final start = DateTime(2025, 2, 1);
      final end = DateTime(2025, 2, 8);
      final tasks = List.generate(
        5,
        (i) => buildTask(
          id: 'q2-$i',
          quadrant: Quadrant.q2,
          completedAt: DateTime(2025, 2, 2 + i),
        ),
      );

      final breakdown = weeklyBalance(tasks, start, end);

      expect(breakdown.q1, 0);
      expect(breakdown.q2, 5);
      expect(breakdown.q3, 0);
      expect(breakdown.q4, 0);
    });

    test('returns zeros for empty input', () {
      final breakdown = weeklyBalance(
        const [],
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 8),
      );

      expect(breakdown.q1, 0);
      expect(breakdown.q2, 0);
      expect(breakdown.q3, 0);
      expect(breakdown.q4, 0);
    });
  });
}
