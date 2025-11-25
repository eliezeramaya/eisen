import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/application/stats_controller.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  group('WeeklyStats', () {
    test('computes aggregates for a typical week', () async {
      final now = DateTime(2025, 1, 8, 12);
      final tasks = [
        buildTask(
          id: 't1',
          quadrant: Quadrant.q2,
          minutes: 30,
          createdAt: DateTime(2025, 1, 2, 9),
          completedAt: DateTime(2025, 1, 3, 10),
        ),
        buildTask(
          id: 't2',
          quadrant: Quadrant.q1,
          minutes: 60,
          createdAt: DateTime(2025, 1, 2, 11),
          completedAt: DateTime(2025, 1, 4, 12),
        ),
        buildTask(
          id: 't3',
          quadrant: Quadrant.q2,
          minutes: 45,
          createdAt: DateTime(2025, 1, 6, 9),
          completedAt: DateTime(2025, 1, 8, 9),
        ),
        buildTask(
          id: 't4',
          quadrant: Quadrant.q3,
          minutes: 25,
          createdAt: DateTime(2025, 1, 2, 10),
          updatedAt: DateTime(2025, 1, 5, 10), // replan proxy
        ),
        buildTask(
          id: 't5',
          quadrant: Quadrant.q4,
          minutes: 15,
          createdAt: DateTime(2025, 1, 1, 9),
          completedAt: DateTime(2025, 1, 1, 10), // outside window
        ),
        buildTask(
          id: 't6',
          quadrant: Quadrant.q1,
          minutes: 20,
          createdAt: DateTime(2025, 1, 6, 12),
          completedAt: DateTime(2025, 1, 7, 13),
        ),
      ];

      final container = buildStatsContainer(tasks: tasks);
      final repo = container.read(statsRepoProvider);

      final stats = await repo.computeStats(
        StatsRange.last7Days,
        ProjectCategory.all,
        now,
      );

      expect(stats.daysActive, 2); // 8th + 7th consecutively
      expect(stats.tasksDone, 4); // completed within window
      expect(stats.tasksReplanned, 1);
      expect(stats.focusMinutes, 180); // sum of minutes for tasks in window
      expect(stats.q2Share, closeTo(0.4, 1e-6)); // 2 of 5 tasks in window
      expect(stats.leadTimeHoursMedian, closeTo(36.5, 0.01));
    });

    test('returns zeroed stats when no tasks or invalid timestamps', () async {
      final tasks = [
        buildTask(
          id: 'ghost',
          quadrant: Quadrant.q1,
          minutes: 10,
          // no timestamps => ignored safely
        ),
      ];
      final container = buildStatsContainer(tasks: tasks);
      final repo = container.read(statsRepoProvider);

      final stats = await repo.computeStats(
        StatsRange.last7Days,
        ProjectCategory.all,
        DateTime(2025, 1, 8),
      );

      expect(stats.daysActive, 0);
      expect(stats.tasksDone, 0);
      expect(stats.tasksReplanned, 0);
      expect(stats.q2Share, 0);
      expect(stats.focusMinutes, 0);
      expect(stats.leadTimeHoursMedian, 0);
    });
  });
}
