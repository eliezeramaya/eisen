import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'models.dart';

/// Returns number of consecutive days ending at [now] with at least one task completed.
int streakDays(List<Task> tasks, DateTime now) {
  int days = 0;
  DateTime cursor = DateTime(now.year, now.month, now.day);
  while (true) {
    final dayStart = cursor;
    final dayEnd = dayStart.add(const Duration(days: 1));
    final has = tasks.any((t) => t.completedAt != null && t.completedAt!.isAfter(dayStart) && t.completedAt!.isBefore(dayEnd));
    if (has) {
      days += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return days;
}

/// Share of Q2 tasks in the week [start..end).
double weeklyQ2Share(List<Task> tasks, DateTime start, DateTime end) {
  final inWeek = tasks.where((t) => (t.completedAt ?? t.createdAt ?? t.updatedAt ?? start).isAfter(start) && (t.completedAt ?? t.createdAt ?? end).isBefore(end)).toList();
  if (inWeek.isEmpty) return 0;
  final q2 = inWeek.where((t) => t.quadrant == Quadrant.q2).length;
  return q2 / inWeek.length;
}

/// Sum of minutes for tasks considered focused in [dayStart..dayEnd).
int dayFocusMinutes(List<Task> tasks, DateTime dayStart, DateTime dayEnd) {
  int sum = 0;
  for (final t in tasks) {
    final c = t.completedAt ?? t.updatedAt ?? t.createdAt;
    if (c != null && c.isAfter(dayStart) && c.isBefore(dayEnd)) {
      sum += t.minutes;
    }
  }
  return sum;
}

/// Median hours between created and completed for tasks completed in [start..end).
double weeklyLeadTimeMedianHours(List<Task> tasks, DateTime start, DateTime end) {
  final hs = <double>[];
  for (final t in tasks) {
    final cAt = t.completedAt;
    final crAt = t.createdAt;
    if (cAt != null && crAt != null && cAt.isAfter(start) && cAt.isBefore(end)) {
      hs.add(cAt.difference(crAt).inMinutes / 60.0);
    }
  }
  if (hs.isEmpty) return 0;
  hs.sort();
  final mid = hs.length ~/ 2;
  return hs.length.isOdd ? hs[mid] : (hs[mid - 1] + hs[mid]) / 2.0;
}

BalanceBreakdown weeklyBalance(List<Task> tasks, DateTime start, DateTime end) {
  int q1 = 0, q2 = 0, q3 = 0, q4 = 0;
  for (final t in tasks) {
    final stamp = t.completedAt ?? t.updatedAt ?? t.createdAt;
    if (stamp == null || !stamp.isAfter(start) || !stamp.isBefore(end)) continue;
    switch (t.quadrant) {
      case Quadrant.q1:
        q1++; break;
      case Quadrant.q2:
        q2++; break;
      case Quadrant.q3:
        q3++; break;
      case Quadrant.q4:
        q4++; break;
    }
  }
  return BalanceBreakdown(q1, q2, q3, q4);
}

List<TrendPoint> focusTrend(List<Task> tasks, {required int days, required DateTime end}) {
  final out = <TrendPoint>[];
  DateTime cursorEnd = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
  for (int i = 0; i < days; i++) {
    final dayEnd = cursorEnd.subtract(Duration(days: i));
    final dayStart = dayEnd.subtract(const Duration(days: 1));
    final m = dayFocusMinutes(tasks, dayStart, dayEnd);
    out.add(TrendPoint(dayStart, m));
  }
  return out.reversed.toList();
}

