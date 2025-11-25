import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/application/stats_controller.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  test('StatsRange maps to trailing days', () {
    expect(StatsRange.last7Days.days, 7);
    expect(StatsRange.last14Days.days, 14);
    expect(StatsRange.last30Days.days, 30);
  });

  group('StatsRepo filters', () {
    test('respects date window boundaries', () async {
      final now = DateTime(2025, 3, 10, 8);
      final tasks = [
        buildTask(
          id: 'start-boundary',
          quadrant: Quadrant.q1,
          completedAt: DateTime(2025, 3, 4, 0),
        ),
        buildTask(
          id: 'inside',
          quadrant: Quadrant.q2,
          completedAt: DateTime(2025, 3, 7, 12),
        ),
        buildTask(
          id: 'before-window',
          quadrant: Quadrant.q3,
          completedAt: DateTime(2025, 3, 3, 23, 59),
        ),
        buildTask(
          id: 'end-exclusive',
          quadrant: Quadrant.q4,
          completedAt: DateTime(2025, 3, 11, 0), // equals window.end
        ),
      ];

      final container = buildStatsContainer(tasks: tasks);
      final repo = container.read(statsRepoProvider);

      final stats = await repo.computeStats(
        StatsRange.last7Days,
        ProjectCategory.all,
        now,
      );

      expect(stats.tasksDone, 2); // start boundary + inside only
      expect(stats.q2Share, closeTo(0.5, 1e-9)); // one of two is q2
    });

    test('filters by project/category', () async {
      final now = DateTime(2025, 3, 10);
      final tasks = [
        buildTask(
          id: 'work-1',
          quadrant: Quadrant.q1,
          category: 'Trabajo',
          completedAt: DateTime(2025, 3, 8),
        ),
        buildTask(
          id: 'personal-1',
          quadrant: Quadrant.q2,
          category: 'Personal',
          completedAt: DateTime(2025, 3, 8),
        ),
      ];

      final container = buildStatsContainer(tasks: tasks);
      final repo = container.read(statsRepoProvider);

      final workStats = await repo.computeStats(
        StatsRange.last30Days,
        ProjectCategory.work,
        now,
      );
      final personalStats = await repo.computeStats(
        StatsRange.last30Days,
        ProjectCategory.personal,
        now,
      );

      expect(workStats.tasksDone, 1);
      expect(workStats.q2Share, 0); // only q1 task counted
      expect(personalStats.tasksDone, 1);
      expect(personalStats.q2Share, 1); // single q2 task
    });
  });
}
