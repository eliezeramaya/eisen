import 'dart:math' as math;

import 'package:eisen/core/analytics/user_behavior_service.dart';
import 'package:eisen/core/analytics/user_behavior_snapshot.dart';
import 'package:eisen/core/analytics/analytics_service.dart';
import 'package:eisen/core/analytics/user_event.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ProductivityScoringService {
  Future<List<DailyProductivityScore>> computeDailyScores({
    required DateTime from,
    required DateTime to,
  });

  Future<List<FocusWindowSuggestion>> computeFocusWindows({
    DateTime? from,
    DateTime? to,
  });

  Future<TaskCompletionPrediction> predictTaskCompletion(Task task);

  Future<OverloadRisk> computeDailyOverloadRisk(DateTime date);

  Future<ProcrastinationScore> predictTaskProcrastination(Task task);
}

/// Implementación heurística inicial.
///
/// Nota: Esta capa está pensada para ser reemplazada por un modelo ML real
/// en el futuro. Las fórmulas actuales son heurísticas simples basadas en
/// snapshots y eventos.
class HeuristicProductivityScoringService
    implements ProductivityScoringService {
  HeuristicProductivityScoringService({
    required this.behaviorService,
    required this.analyticsService,
  });

  final UserBehaviorService behaviorService;
  final AnalyticsService analyticsService;

  @override
  Future<List<DailyProductivityScore>> computeDailyScores({
    required DateTime from,
    required DateTime to,
  }) async {
    final snaps = await behaviorService.getDailySnapshots(from: from, to: to);
    if (snaps.isEmpty) return const [];

    // Promedios globales para contexto.
    final avgCreated = snaps.isEmpty
        ? 0.0
        : snaps.map((s) => s.tasksCreated).reduce((a, b) => a + b) /
            snaps.length;
    final avgFocusMinutes = snaps.isEmpty
        ? 0.0
        : snaps
                .map((s) => s.totalFocusDuration.inMinutes)
                .reduce((a, b) => a + b) /
            snaps.length;

    double clamp01(double v) => v.clamp(0.0, 1.0);

    return snaps
        .map((s) {
          // Overload: combinación de (created vs avg) y (completed vs created).
          final createdFactor =
              avgCreated <= 0 ? 0.0 : (s.tasksCreated / avgCreated);
          final completionRatio = s.tasksCreated == 0
              ? 0.0
              : s.tasksCompleted / s.tasksCreated;
          final overloadRaw = (createdFactor * 0.6) +
              ((1.0 - completionRatio.clamp(0.0, 1.0)) * 0.4);
          final overloadScore = clamp01(overloadRaw / 2.0);

          // Q2 ratio: proporción de Q2 sobre completadas.
          final totalCompleted = math.max(1, s.tasksCompleted);
          final q2Ratio = clamp01(s.tasksCompletedQ2 / totalCompleted);

          // Procrastination: replan vs created.
          final procrastRaw = s.tasksCreated == 0
              ? 0.0
              : s.tasksRescheduled / s.tasksCreated;
          final procrastinationScore = clamp01(procrastRaw);

          // Focus consistency: comparar minutos de foco vs promedio.
          final focusMinutes = s.totalFocusDuration.inMinutes.toDouble();
          final focusConsistency = avgFocusMinutes <= 0
              ? (focusMinutes > 0 ? 0.7 : 0.0)
              : clamp01(focusMinutes / avgFocusMinutes);

          return DailyProductivityScore(
            day: s.day,
            overloadScore: overloadScore,
            q2Ratio: q2Ratio,
            procrastinationScore: procrastinationScore,
            focusConsistencyScore: focusConsistency,
          );
        })
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  @override
  Future<List<FocusWindowSuggestion>> computeFocusWindows({
    DateTime? from,
    DateTime? to,
  }) async {
    final now = DateTime.now();
    final effectiveFrom =
        from ?? DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 30));
    final effectiveTo = to ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    // Leer eventos de foco para agrupar por hora.
    final events = await analyticsService.getEvents(
      from: DateTime(
          effectiveFrom.year, effectiveFrom.month, effectiveFrom.day),
      to: DateTime(effectiveTo.year, effectiveTo.month, effectiveTo.day)
          .add(const Duration(days: 1)),
    );
    final buckets = <int, List<int>>{}; // hour -> list of durations (minutes)

    for (final e in events) {
      if (e.type != UserEventType.focusSessionEnded) continue;
      final hour = e.timestamp.hour;
      final duration = (e.metadata['actualMinutes'] as num?)?.toInt() ??
          (e.metadata['plannedMinutes'] as num?)?.toInt() ??
          0;
      buckets.putIfAbsent(hour, () => []).add(duration);
    }

    if (buckets.isEmpty) return const [];

    final scored = buckets.entries.map((entry) {
      final durations = entry.value;
      final avg = durations.isEmpty
          ? 0.0
          : durations.reduce((a, b) => a + b) / durations.length;
      final count = durations.length;
      // Heurística: score = normalizar avg duración + peso por count.
      final score = (avg / 90.0).clamp(0.0, 1.0) * 0.6 +
          (count / 5.0).clamp(0.0, 1.0) * 0.4;
      return MapEntry(entry.key, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = scored.take(3).toList();
    final suggestions = <FocusWindowSuggestion>[];
    for (final entry in top) {
      final start = TimeOfDay(hour: entry.key, minute: 0);
      final end = TimeOfDay(hour: (entry.key + 1) % 24, minute: 0);
      suggestions.add(
        FocusWindowSuggestion(
          start: start,
          end: end,
          confidence: entry.value.clamp(0.0, 1.0),
        ),
      );
    }
    return suggestions;
  }

  @override
  Future<TaskCompletionPrediction> predictTaskCompletion(Task task) async {
    double base = 0.7;
    base -= task.replanCount * 0.1;
    if (task.quadrant == Quadrant.q2) base += 0.05;
    if (task.quadrant == Quadrant.q4) base -= 0.15;
    if (task.minutes > 240) base -= 0.1;
    if (task.minutes < 45) base += 0.05;
    if (task.due != null) {
      final daysToDue =
          task.due!.difference(DateTime.now()).inDays.clamp(-7, 30);
      if (daysToDue < 0) base -= 0.1;
      if (daysToDue <= 1) base += 0.05;
    }
    final onTime = base.clamp(0.0, 1.0);
    final replan = (1.0 - onTime).clamp(0.0, 1.0);
    return TaskCompletionPrediction(
      onTimeProbability: onTime,
      reprogramProbability: replan,
    );
  }

  @override
  Future<OverloadRisk> computeDailyOverloadRisk(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final snaps =
        await behaviorService.getDailySnapshots(from: dayStart, to: dayEnd);
    final today = snaps.isNotEmpty
        ? snaps.firstWhere(
            (s) => s.day == DateTime(dayStart.year, dayStart.month, dayStart.day),
            orElse: () => UserBehaviorSnapshot(day: DateTime(2000, 1, 1)),
          )
        : UserBehaviorSnapshot(day: DateTime(2000, 1, 1));

    final trailing = await behaviorService.getDailySnapshots(
      from: dayStart.subtract(const Duration(days: 7)),
      to: dayStart.subtract(const Duration(days: 1)),
    );
    final avgCompleted = trailing.isEmpty
        ? 1.0
        : trailing
                .map((s) => s.tasksCompleted)
                .reduce((a, b) => a + b) /
            trailing.length;
    final planned = today.tasksCreated;
    final score = ((planned / avgCompleted).clamp(0.0, 3.0)) / 3.0;
    return OverloadRisk(score.clamp(0.0, 1.0));
  }

  @override
  Future<ProcrastinationScore> predictTaskProcrastination(Task task) async {
    return ProcrastinationScore(_procrastinationFor(task));
  }

  double _procrastinationFor(Task task) {
    double score = 0.2;
    score += task.replanCount * 0.15;
    if (task.minutes > 180) score += 0.15;
    if (task.quadrant == Quadrant.q4) score += 0.2;
    final title = task.title.toLowerCase();
    const vague = ['revisar', 'ver', 'checar', 'check', 'look', 'review'];
    if (vague.any((v) => title.contains(v))) {
      score += 0.1;
    }
    return score.clamp(0.0, 1.0);
  }
}

final productivityScoringServiceProvider =
    Provider<ProductivityScoringService>((ref) {
  return HeuristicProductivityScoringService(
    behaviorService: ref.read(userBehaviorServiceProvider),
    analyticsService: ref.read(analyticsServiceProvider),
  );
});
