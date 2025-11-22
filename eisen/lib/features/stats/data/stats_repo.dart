import 'dart:convert';

import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calculators.dart' as calc;
import '../domain/models.dart';
import '../domain/report.dart';

class StatsRepo {
  StatsRepo(this.ref);
  final Ref ref;

  List<Task> _tasks() => ref.read(matrixControllerProvider).tasks;

  DateTimeRange _window(StatsRange range, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1)); // exclusive
    final start = end.subtract(Duration(days: range.days));
    return DateTimeRange(start: start, end: end);
  }

  List<Task> _filteredTasks(
    ProjectCategory project,
    DateTimeRange window,
  ) {
    final all = _tasks();
    Iterable<Task> filtered = all;

    if (project != ProjectCategory.all) {
      final target = project.displayName.toLowerCase();
      filtered = filtered.where(
        (t) => t.category != null && t.category!.toLowerCase() == target,
      );
    }

    // Apply time window using the best available timestamp per task.
    filtered = filtered.where((t) {
      final stamp = t.completedAt ?? t.updatedAt ?? t.createdAt;
      if (stamp == null) return false;
      return !stamp.isBefore(window.start) && stamp.isBefore(window.end);
    });

    return filtered.toList(growable: false);
  }

  /// Computes stats for the given [range] and [project], ending at [now].
  Future<WeeklyStats> computeStats(
      StatsRange range, ProjectCategory project, DateTime now) async {
    final window = _window(range, now);
    final tasks = _filteredTasks(project, window);
    final rangeStart = window.start;
    final rangeEnd = window.end;

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
    final window = _window(range, now);
    return calc.weeklyBalance(
      _filteredTasks(project, window),
      window.start,
      window.end,
    );
  }

  /// Focus trend for the selected [range] and [project].
  Future<List<TrendPoint>> focusTrend({
    required StatsRange range,
    required ProjectCategory project,
  }) async {
    final window = _window(range, DateTime.now());
    return calc.focusTrend(
      _filteredTasks(project, window),
      days: range.days,
      end: window.end.subtract(const Duration(days: 1)),
    );
  }

  /// Builds a structured report (summary + serialized formats).
  Future<StatsExportBundle> exportReport({
    required StatsRange range,
    required ProjectCategory project,
    required DateTime now,
  }) async {
    final window = _window(range, now);
    final weekly = await computeStats(range, project, now);
    final balance = await rangeBalance(range, project, now);
    final trend = await focusTrend(range: range, project: project);

    final report = StatsReport(
      generatedAt: now,
      range: window,
      project: project,
      weekly: weekly,
      balance: balance,
      trend: trend,
    );

    final jsonPayload = _buildJson(report);
    final csvPayload = _buildCsv(report);
    final pdfLike = _buildPrintable(report);

    return StatsExportBundle(
      report: report,
      json: jsonPayload,
      csv: csvPayload,
      printable: pdfLike,
    );
  }

  String _buildJson(StatsReport r) {
    String fmt(DateTime d) => d.toIso8601String();
    final map = {
      'generatedAt': fmt(r.generatedAt),
      'range': {
        'start': fmt(r.range.start),
        'end': fmt(r.range.end),
        'days': r.range.duration.inDays,
      },
      'project': r.project.displayName,
      'weekly': {
        'daysActive': r.weekly.daysActive,
        'tasksDone': r.weekly.tasksDone,
        'tasksReplanned': r.weekly.tasksReplanned,
        'q2Share': r.weekly.q2Share,
        'focusMinutes': r.weekly.focusMinutes,
        'leadTimeHoursMedian': r.weekly.leadTimeHoursMedian,
      },
      'balance': {
        'q1': r.balance.q1,
        'q2': r.balance.q2,
        'q3': r.balance.q3,
        'q4': r.balance.q4,
      },
      'trend': r.trend
          .map((t) => {
                'day': fmt(t.day),
                'focusMinutes': t.focusMinutes,
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  String _buildCsv(StatsReport r) {
    final sb = StringBuffer();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    sb.writeln('Eisen Stats Export');
    sb.writeln('Project,${r.project.displayName}');
    sb.writeln('Range Start,${fmt(r.range.start)}');
    sb.writeln('Range End,${fmt(r.range.end)}');
    sb.writeln('Generated At,${r.generatedAt.toIso8601String()}');
    sb.writeln();
    sb.writeln('Summary');
    sb.writeln('Days Active,${r.weekly.daysActive}');
    sb.writeln('Tasks Done,${r.weekly.tasksDone}');
    sb.writeln('Tasks Replanned,${r.weekly.tasksReplanned}');
    sb.writeln('Q2 Share,${(r.weekly.q2Share * 100).toStringAsFixed(1)}%');
    sb.writeln('Focus Minutes,${r.weekly.focusMinutes}');
    sb.writeln('Lead Time Median (h),${r.weekly.leadTimeHoursMedian.toStringAsFixed(2)}');
    sb.writeln();
    sb.writeln('Balance');
    sb.writeln('Quadrant,Count');
    sb.writeln('Q1,${r.balance.q1}');
    sb.writeln('Q2,${r.balance.q2}');
    sb.writeln('Q3,${r.balance.q3}');
    sb.writeln('Q4,${r.balance.q4}');
    sb.writeln();
    sb.writeln('Trend (daily focus minutes)');
    sb.writeln('Day,Focus Minutes');
    for (final t in r.trend) {
      sb.writeln('${fmt(t.day)},${t.focusMinutes}');
    }
    return sb.toString();
  }

  String _buildPrintable(StatsReport r) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final balanceTotal =
        (r.balance.q1 + r.balance.q2 + r.balance.q3 + r.balance.q4)
            .clamp(1, 1 << 30);
    String pct(int v) =>
        '${((v / balanceTotal) * 100).toStringAsFixed(1)}%';
    final trendLines = r.trend
        .map((t) => '  • ${fmt(t.day)} — ${t.focusMinutes} min foco')
        .join('\n');
    return '''
EISEN · Reporte de foco
Proyecto: ${r.project.displayName}
Rango: ${fmt(r.range.start)} — ${fmt(r.range.end)}
Generado: ${r.generatedAt.toIso8601String()}

Resumen rápido
- Días con actividad: ${r.weekly.daysActive}/${r.range.duration.inDays}
- Tareas completadas: ${r.weekly.tasksDone}
- Replanificaciones detectadas: ${r.weekly.tasksReplanned}
- Peso en Q2: ${(r.weekly.q2Share * 100).toStringAsFixed(1)}%
- Minutos totales de foco: ${r.weekly.focusMinutes}
- Lead time mediano: ${r.weekly.leadTimeHoursMedian.toStringAsFixed(1)} h

Balance por cuadrante
- Q1: ${r.balance.q1} (${pct(r.balance.q1)})
- Q2: ${r.balance.q2} (${pct(r.balance.q2)})
- Q3: ${r.balance.q3} (${pct(r.balance.q3)})
- Q4: ${r.balance.q4} (${pct(r.balance.q4)})

Tendencia (minutos de foco por día)
$trendLines
''';
  }
}
