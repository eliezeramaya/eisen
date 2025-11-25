import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/stats/application/stats_controller.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  test('weeklyStatsProvider reacts to range changes', () async {
    final now = DateTime.now();
    final tasks = [
      buildTask(
        id: 'recent-work',
        quadrant: Quadrant.q1,
        category: 'Trabajo',
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      buildTask(
        id: 'recent-personal',
        quadrant: Quadrant.q2,
        category: 'Personal',
        completedAt: now.subtract(const Duration(days: 2)),
      ),
      buildTask(
        id: 'older-work',
        quadrant: Quadrant.q2,
        category: 'Trabajo',
        completedAt: now.subtract(const Duration(days: 10)),
      ),
      buildTask(
        id: 'oldest-work',
        quadrant: Quadrant.q3,
        category: 'Trabajo',
        completedAt: now.subtract(const Duration(days: 25)),
      ),
    ];

    final container = buildStatsContainer(tasks: tasks);

    final weekStats =
        await container.read(weeklyStatsProvider.future); // default 7 days
    expect(weekStats.tasksDone, 2);

    container
        .read(statsRangeProvider.notifier)
        .set(StatsRange.last30Days);
    final monthStats = await container.read(weeklyStatsProvider.future);
    expect(monthStats.tasksDone, 4);
  });

  test('providers respect project filter', () async {
    final now = DateTime.now();
    final tasks = [
      buildTask(
        id: 'work',
        quadrant: Quadrant.q1,
        category: 'Trabajo',
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      buildTask(
        id: 'personal',
        quadrant: Quadrant.q2,
        category: 'Personal',
        completedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    final container = buildStatsContainer(tasks: tasks);

    container
        .read(statsProjectProvider.notifier)
        .set(ProjectCategory.work);
    final workStats = await container.read(weeklyStatsProvider.future);
    expect(workStats.tasksDone, 1);

    container
        .read(statsProjectProvider.notifier)
        .set(ProjectCategory.personal);
    final personalStats = await container.read(weeklyStatsProvider.future);
    expect(personalStats.tasksDone, 1);
    expect(personalStats.q2Share, 1); // only one q2 task counted
  });
}
