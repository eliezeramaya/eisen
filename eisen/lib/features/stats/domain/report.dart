import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Structured report used for exports.
class StatsReport {
  const StatsReport({
    required this.generatedAt,
    required this.range,
    required this.project,
    required this.weekly,
    required this.balance,
    required this.trend,
  });

  final DateTime generatedAt;
  final DateTimeRange range;
  final ProjectCategory project;
  final WeeklyStats weekly;
  final BalanceBreakdown balance;
  final List<TrendPoint> trend;
}

/// Encapsulates all exportable payloads for the Stats report.
class StatsExportBundle {
  const StatsExportBundle({
    required this.report,
    required this.json,
    required this.csv,
    required this.printable,
  });

  final StatsReport report;
  final String json;
  final String csv;
  final String printable;
}
