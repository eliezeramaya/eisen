import 'package:flutter/foundation.dart';

class WeeklyStats {
  final int daysActive; // 0..7
  final int tasksDone;
  final int tasksReplanned;
  final double q2Share; // 0..1
  final int focusMinutes; // total minutes done/estimated
  final double leadTimeHoursMedian; // median hours created->completed
  const WeeklyStats({
    required this.daysActive,
    required this.tasksDone,
    required this.tasksReplanned,
    required this.q2Share,
    required this.focusMinutes,
    required this.leadTimeHoursMedian,
  });
}

@immutable
class BalanceBreakdown {
  final int q1;
  final int q2;
  final int q3;
  final int q4;
  const BalanceBreakdown(this.q1, this.q2, this.q3, this.q4);
}

@immutable
class TrendPoint {
  final DateTime day;
  final int focusMinutes;
  const TrendPoint(this.day, this.focusMinutes);
}

