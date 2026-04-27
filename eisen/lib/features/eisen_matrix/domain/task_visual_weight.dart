import 'dart:math' as math;

import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

double computeTaskVisualWeight(
  Task task, {
  Map<Quadrant, double> quadrantLearningAdjustments =
      const <Quadrant, double>{},
}) {
  final basePriority = task.priority.clamp(1, 10).toDouble();
  final minutesFactor =
      math.pow(task.minutes.clamp(5, 240).toDouble(), 0.65).toDouble();
  final quadrantBoost = getQuadrantBoost(task.quadrant);
  final learningFactor = quadrantLearningAdjustments[task.quadrant] ?? 1.0;
  final confidenceFactor = getConfidenceFactor(task.classificationConfidence);
  final horizonFactor = getHorizonFactor(task.horizon);
  final dueFactor = _getDueFactor(task.due);
  final freshnessFactor = _getFreshnessFactor(task);

  final raw = basePriority *
      minutesFactor *
      quadrantBoost *
      learningFactor *
      confidenceFactor *
      horizonFactor *
      dueFactor *
      freshnessFactor;

  return raw.isFinite && !raw.isNaN ? math.max(0.0, raw) : 0.0;
}

double getQuadrantBoost(Quadrant quadrant) {
  return switch (quadrant) {
    Quadrant.q1 => 1.30,
    Quadrant.q2 => 1.18,
    Quadrant.q3 => 0.92,
    Quadrant.q4 => 0.65,
  };
}

double getConfidenceFactor(ConfidenceLevel? confidence) {
  return switch (confidence) {
    ConfidenceLevel.high => 1.00,
    ConfidenceLevel.medium => 0.92,
    ConfidenceLevel.low => 0.82,
    null => 0.90,
  };
}

double getHorizonFactor(TimeHorizon? horizon) {
  return switch (horizon) {
    TimeHorizon.today => 1.18,
    TimeHorizon.thisWeek => 1.00,
    TimeHorizon.thisMonth => 0.85,
    TimeHorizon.someday => 0.65,
    null => 0.90,
  };
}

double _getDueFactor(DateTime? due) {
  if (due == null) return 1.0;
  final daysToDue = due.difference(DateTime.now()).inHours / 24.0;
  final clamped = math.max(0.0, daysToDue);
  return 1.0 + 0.18 * math.exp(-0.7 * clamped);
}

double _getFreshnessFactor(Task task) {
  final now = DateTime.now();
  final lastTouch = task.updatedAt ?? task.createdAt ?? now;
  final days = math.max(0.0, now.difference(lastTouch).inDays.toDouble());
  final freshness = math.exp(-0.15 * days);
  return 0.82 + 0.18 * freshness;
}
