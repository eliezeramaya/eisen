import 'package:flutter/foundation.dart';

class WeeklyStats {
  // median hours created->completed
  const WeeklyStats({
    required this.daysActive,
    required this.tasksDone,
    required this.tasksReplanned,
    required this.q2Share,
    required this.focusMinutes,
    required this.leadTimeHoursMedian,
  });
  final int daysActive; // 0..7
  final int tasksDone;
  final int tasksReplanned;
  final double q2Share; // 0..1
  final int focusMinutes; // total minutes done/estimated
  final double leadTimeHoursMedian;
}

@immutable
class BalanceBreakdown {
  const BalanceBreakdown(this.q1, this.q2, this.q3, this.q4);
  final int q1;
  final int q2;
  final int q3;
  final int q4;
}

@immutable
class TrendPoint {
  const TrendPoint(this.day, this.focusMinutes);
  final DateTime day;
  final int focusMinutes;
}
