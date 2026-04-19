// ignore_for_file: sort_constructors_first

import 'dart:async';

import 'package:eisen/core/workers/worker_models.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

class StatsWorkerInput {
  const StatsWorkerInput({
    required this.tasks,
    required this.now,
    this.weeks = 12,
    this.months = 6,
  });

  final List<TaskIsolateSnapshot> tasks;
  final DateTime now;
  final int weeks;
  final int months;

  Map<String, Object?> toJson() => {
        'tasks': tasks.map((t) => t.toJson()).toList(growable: false),
        'now': now.toIso8601String(),
        'weeks': weeks,
        'months': months,
      };

  factory StatsWorkerInput.fromJson(Map<String, Object?> json) {
    final tasksJson = json['tasks'];
    final nowRaw = json['now'];
    DateTime? parsedNow;
    if (nowRaw is String) {
      parsedNow = DateTime.tryParse(nowRaw);
    } else if (nowRaw is DateTime) {
      parsedNow = nowRaw;
    }
    return StatsWorkerInput(
      tasks: tasksJson is List
          ? tasksJson
              .whereType<Map<String, Object?>>()
              .map(TaskIsolateSnapshot.fromJson)
              .toList(growable: false)
          : const <TaskIsolateSnapshot>[],
      now: parsedNow ?? DateTime.now(),
      weeks: json['weeks'] as int? ?? 12,
      months: json['months'] as int? ?? 6,
    );
  }
}

class StatsPeriodSummary {
  const StatsPeriodSummary({
    required this.last7,
    required this.last14,
    required this.last30,
  });

  final int last7;
  final int last14;
  final int last30;

  Map<String, Object> toJson() => {
        'last7': last7,
        'last14': last14,
        'last30': last30,
      };

  factory StatsPeriodSummary.fromJson(Map<String, Object?> json) =>
      StatsPeriodSummary(
        last7: json['last7'] as int? ?? 0,
        last14: json['last14'] as int? ?? 0,
        last30: json['last30'] as int? ?? 0,
      );
}

class StatsBucket {
  const StatsBucket({
    required this.start,
    required this.count,
  });

  final DateTime start;
  final int count;

  Map<String, Object> toJson() => {
        'start': start.toIso8601String(),
        'count': count,
      };

  factory StatsBucket.fromJson(Map<String, Object?> json) => StatsBucket(
        start: DateTime.parse(json['start'] as String),
        count: json['count'] as int,
      );
}

class StatsWorkerOutput {
  const StatsWorkerOutput({
    required this.total,
    required this.active,
    required this.completed,
    required this.byQuadrant,
    required this.byStatus,
    required this.periods,
    required this.byProject,
    required this.weekly,
    required this.monthly,
    required this.completionRate,
    required this.elapsedMs,
  });

  final int total;
  final int active;
  final int completed;
  final Map<Quadrant, int> byQuadrant;
  final Map<TaskStatus, int> byStatus;
  final StatsPeriodSummary periods;
  final Map<String, int> byProject;
  final List<StatsBucket> weekly;
  final List<StatsBucket> monthly;
  final double completionRate;
  final double elapsedMs;

  Map<String, Object?> toJson() => {
        'total': total,
        'active': active,
        'completed': completed,
        'byQuadrant': byQuadrant
            .map((key, value) => MapEntry<String, int>(key.name, value)),
        'byStatus': byStatus
            .map((key, value) => MapEntry<String, int>(key.name, value)),
        'periods': periods.toJson(),
        'byProject': byProject,
        'weekly': weekly.map((b) => b.toJson()).toList(growable: false),
        'monthly': monthly.map((b) => b.toJson()).toList(growable: false),
        'completionRate': completionRate,
        'elapsedMs': elapsedMs,
      };

  factory StatsWorkerOutput.fromJson(Map<String, Object?> json) =>
      StatsWorkerOutput(
        total: json['total'] as int? ?? 0,
        active: json['active'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        byQuadrant: (json['byQuadrant'] as Map<String, Object?>?)?.map(
              (key, value) => MapEntry<Quadrant, int>(
                Quadrant.values.firstWhere(
                  (q) => q.name == key,
                  orElse: () => Quadrant.q1,
                ),
                value as int,
              ),
            ) ??
            const <Quadrant, int>{},
        byStatus: (json['byStatus'] as Map<String, Object?>?)?.map(
              (key, value) => MapEntry<TaskStatus, int>(
                TaskStatus.values.firstWhere(
                  (s) => s.name == key,
                  orElse: () => TaskStatus.pending,
                ),
                value as int,
              ),
            ) ??
            const <TaskStatus, int>{},
        periods: StatsPeriodSummary.fromJson(
            json['periods']! as Map<String, Object?>),
        byProject: (json['byProject'] as Map?)?.cast<String, int>() ?? const {},
        weekly: (json['weekly'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, Object?>>()
            .map(StatsBucket.fromJson)
            .toList(growable: false),
        monthly: (json['monthly'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, Object?>>()
            .map(StatsBucket.fromJson)
            .toList(growable: false),
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
        elapsedMs: (json['elapsedMs'] as num?)?.toDouble() ?? 0,
      );
}

/// Isolate-friendly stats aggregation for heavy dashboards.
Future<StatsWorkerOutput> statsWorker(
  Map<String, Object?> message,
) async {
  final input = StatsWorkerInput.fromJson(message);
  final sw = Stopwatch()..start();
  final tasks = input.tasks;
  final total = tasks.length;
  final completed = tasks.where((t) => t.completedAt != null).toList();
  final active = total - completed.length;

  final byQuadrant = <Quadrant, int>{
    for (final q in Quadrant.values) q: 0,
  };
  for (final t in tasks) {
    byQuadrant[t.quadrant] = (byQuadrant[t.quadrant] ?? 0) + 1;
  }

  final byStatus = <TaskStatus, int>{
    for (final s in TaskStatus.values) s: 0,
  };
  for (final t in tasks) {
    byStatus[t.status] = (byStatus[t.status] ?? 0) + 1;
  }

  final periods = _periodSummary(tasks, input.now);
  final byProject = <String, int>{};
  for (final t in tasks) {
    final key = t.projectId ?? '__none__';
    byProject[key] = (byProject[key] ?? 0) + 1;
  }

  final weekly = _weeklyBuckets(tasks, input.now, input.weeks);
  final monthly = _monthlyBuckets(tasks, input.now, input.months);

  sw.stop();

  final completionRate = total == 0 ? 0.0 : completed.length / total;
  final output = StatsWorkerOutput(
    total: total,
    active: active,
    completed: completed.length,
    byQuadrant: byQuadrant,
    byStatus: byStatus,
    periods: periods,
    byProject: byProject,
    weekly: weekly,
    monthly: monthly,
    completionRate: completionRate,
    elapsedMs: sw.elapsedMicroseconds / 1000.0,
  );

  if (kDebugMode) {
    debugPrint(
        '[StatsWorker] tasks=$total elapsed=${output.elapsedMs.toStringAsFixed(2)}ms');
  }
  return output;
}

StatsPeriodSummary _periodSummary(
    List<TaskIsolateSnapshot> tasks, DateTime now) {
  int countSince(int days) {
    final since = now.subtract(Duration(days: days));
    return tasks.where((t) {
      final stamp = _activityStamp(t);
      return stamp != null && !stamp.isBefore(since);
    }).length;
  }

  return StatsPeriodSummary(
    last7: countSince(7),
    last14: countSince(14),
    last30: countSince(30),
  );
}

List<StatsBucket> _weeklyBuckets(
  List<TaskIsolateSnapshot> tasks,
  DateTime now,
  int weeks,
) {
  final startOfWeek = _startOfWeek(now);
  final buckets = <StatsBucket>[];
  for (var i = weeks - 1; i >= 0; i--) {
    final start = startOfWeek.subtract(Duration(days: 7 * i));
    final end = start.add(const Duration(days: 7));
    final count = tasks.where((t) {
      final stamp = _activityStamp(t);
      return stamp != null && !stamp.isBefore(start) && stamp.isBefore(end);
    }).length;
    buckets.add(StatsBucket(start: start, count: count));
  }
  return buckets;
}

List<StatsBucket> _monthlyBuckets(
  List<TaskIsolateSnapshot> tasks,
  DateTime now,
  int months,
) {
  final buckets = <StatsBucket>[];
  DateTime cursor = DateTime.utc(now.year, now.month, 1);
  for (var i = 0; i < months; i++) {
    final start = DateTime.utc(cursor.year, cursor.month, 1);
    final end = DateTime.utc(cursor.year, cursor.month + 1, 1);
    final count = tasks.where((t) {
      final stamp = _activityStamp(t);
      return stamp != null && !stamp.isBefore(start) && stamp.isBefore(end);
    }).length;
    buckets.insert(0, StatsBucket(start: start, count: count));
    cursor = DateTime.utc(cursor.year, cursor.month - 1, 1);
  }
  return buckets;
}

DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday; // Monday = 1
  final delta = weekday - DateTime.monday;
  final start = date.subtract(Duration(days: delta));
  return DateTime.utc(start.year, start.month, start.day);
}

DateTime? _activityStamp(TaskIsolateSnapshot task) =>
    task.completedAt ?? task.updatedAt ?? task.createdAt;
