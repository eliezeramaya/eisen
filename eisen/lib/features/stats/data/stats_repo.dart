import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calculators.dart' as calc;
import '../domain/models.dart';

class StatsRepo {
  StatsRepo(this.ref);
  final Ref ref;

  List<Task> _tasks() => ref.read(matrixControllerProvider).tasks;

  List<Task> _filteredTasks(ProjectCategory project) {
    final all = _tasks();
    if (project == ProjectCategory.all) {
      return all;
    }
    final target = project.displayName.toLowerCase();
    return all
        .where((t) =>
            t.category != null &&
            t.category!.toLowerCase() == target)
        .toList(growable: false);
  }

  /// Computes stats for the given [range] and [project], ending at [now].
  Future<WeeklyStats> computeStats(
      StatsRange range, ProjectCategory project, DateTime now) async {
    final tasks = _filteredTasks(project);
    final today = DateTime(now.year, now.month, now.day);
    final rangeEnd = today.add(const Duration(days: 1));
    final rangeStart =
        rangeEnd.subtract(Duration(days: range.days)); // [start, end)

    final daysActive = calc.streakDays(tasks, now).clamp(0, range.days);
    final balance = calc.weeklyBalance(tasks, rangeStart, rangeEnd);
    final total =
        (balance.q1 + balance.q2 + balance.q3 + balance.q4).clamp(1, 1 << 30);
    final q2Share = total == 0 ? 0.0 : balance.q2 / total;
    int focusMinutes = 0;
    for (int i = 0; i < range.days; i++) {
      final dayEnd = rangeEnd.subtract(Duration(days: i));
      final dayStart = dayEnd.subtract(const Duration(days: 1));
      focusMinutes += calc.dayFocusMinutes(tasks, dayStart, dayEnd);
    }
    final lt =
        calc.weeklyLeadTimeMedianHours(tasks, rangeStart, rangeEnd);
    // Replan heuristic: count tasks with updatedAt vastly later than createdAt (proxy)
    final int replans = tasks
        .where((t) {
          final updated = t.updatedAt;
          final created = t.createdAt;
          if (updated == null || created == null) return false;
          if (!updated.isAfter(rangeStart) || !updated.isBefore(rangeEnd)) {
            return false;
          }
          return updated.difference(created).inHours > 24;
        })
        .length;
    final int done = tasks
        .where((t) =>
            t.completedAt != null &&
            t.completedAt!.isAfter(rangeStart) &&
            t.completedAt!.isBefore(rangeEnd))
        .length;
    return WeeklyStats(
      daysActive: daysActive,
      tasksDone: done,
      tasksReplanned: replans,
      q2Share: q2Share,
      focusMinutes: focusMinutes,
      leadTimeHoursMedian: lt,
    );
  }

  int currentStreak() => calc.streakDays(_tasks(), DateTime.now());

  /// Balance breakdown for the given [range] and [project], ending at [now].
  Future<BalanceBreakdown> rangeBalance(
      StatsRange range, ProjectCategory project, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1));
    final start = end.subtract(Duration(days: range.days)); // [start, end)
    return calc.weeklyBalance(_filteredTasks(project), start, end);
  }

  /// Focus trend for the selected [range] and [project].
  Future<List<TrendPoint>> focusTrend({
    required StatsRange range,
    required ProjectCategory project,
  }) async {
    return calc.focusTrend(
      _filteredTasks(project),
      days: range.days,
      end: DateTime.now(),
    );
  }
}
