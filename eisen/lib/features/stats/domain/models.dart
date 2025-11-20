import 'package:flutter/foundation.dart';

/// Time window used by the Stats dashboard.
///
/// The values are intentionally coarse-grained to keep the UI simple
/// on mobile. Each range maps to a fixed number of trailing days
/// ending at “today”.
enum StatsRange {
  last7Days,
  last14Days,
  last30Days,
}

extension StatsRangeX on StatsRange {
  /// Number of trailing days represented by this range.
  int get days {
    switch (this) {
      case StatsRange.last7Days:
        return 7;
      case StatsRange.last14Days:
        return 14;
      case StatsRange.last30Days:
        return 30;
    }
  }
}

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
