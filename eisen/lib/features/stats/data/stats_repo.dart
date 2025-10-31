import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calculators.dart' as calc;
import '../domain/models.dart';

class StatsRepo {
  StatsRepo(this.ref);
  final Ref ref;

  List<Task> _tasks() => ref.read(matrixControllerProvider).tasks;

  Future<WeeklyStats> computeWeeklyStats(DateTime now) async {
    final tasks = _tasks();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final weekEnd =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final daysActive = calc.streakDays(tasks, now).clamp(0, 7);
    final balance = calc.weeklyBalance(tasks, weekStart, weekEnd);
    final total =
        (balance.q1 + balance.q2 + balance.q3 + balance.q4).clamp(1, 1 << 30);
    final q2Share = total == 0 ? 0.0 : balance.q2 / total;
    int focusMinutes = 0;
    for (int i = 0; i < 7; i++) {
      final dayEnd = weekEnd.subtract(Duration(days: i));
      final dayStart = dayEnd.subtract(const Duration(days: 1));
      focusMinutes += calc.dayFocusMinutes(tasks, dayStart, dayEnd);
    }
    final lt = calc.weeklyLeadTimeMedianHours(tasks, weekStart, weekEnd);
    // Replan heuristic: count tasks with updatedAt vastly later than createdAt (proxy)
    final int replans = tasks
        .where((t) =>
            t.updatedAt != null &&
            t.createdAt != null &&
            t.updatedAt!.difference(t.createdAt!).inHours > 24)
        .length;
    final int done = tasks
        .where((t) =>
            t.completedAt != null &&
            t.completedAt!.isAfter(weekStart) &&
            t.completedAt!.isBefore(weekEnd))
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

  Future<BalanceBreakdown> weeklyBalance(DateTime now) async {
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return calc.weeklyBalance(_tasks(), start, end);
  }

  Future<List<TrendPoint>> focusTrend({required int days}) async {
    return calc.focusTrend(_tasks(), days: days, end: DateTime.now());
  }
}
