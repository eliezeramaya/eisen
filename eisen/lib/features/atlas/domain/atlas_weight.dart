import 'dart:math' as math;

import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

double computeAtlasTaskWeight(Task task) {
  final basePriority = task.priority.clamp(1, 10).toDouble();
  final minutesFactor =
      math.pow(task.minutes.clamp(5, 240).toDouble(), 0.65).toDouble();
  final raw = basePriority *
      minutesFactor *
      _quadrantBoost(task.quadrant) *
      _horizonFactor(task.horizon) *
      _confidenceFactor(task.classificationConfidence);
  final adjusted = task.isArchived ? raw * 0.25 : raw;
  return adjusted.isFinite && !adjusted.isNaN ? math.max(1.0, adjusted) : 1.0;
}

double atlasQuadrantBoost(Quadrant quadrant) => _quadrantBoost(quadrant);

bool includeTaskInAtlas(Task task, {bool showArchived = false}) {
  if (task.completedAt != null) return false;
  if (task.isArchived && !showArchived) return false;
  return true;
}

double _quadrantBoost(Quadrant quadrant) {
  return switch (quadrant) {
    Quadrant.q1 => 1.30,
    Quadrant.q2 => 1.18,
    Quadrant.q3 => 0.92,
    Quadrant.q4 => 0.65,
  };
}

double _horizonFactor(TimeHorizon? horizon) {
  return switch (horizon) {
    // The current model has no explicit "now" horizon yet.
    TimeHorizon.today => 1.18,
    TimeHorizon.thisWeek => 1.00,
    TimeHorizon.thisMonth => 0.85,
    TimeHorizon.someday => 0.65,
    null => 0.90,
  };
}

double _confidenceFactor(ConfidenceLevel? confidence) {
  return switch (confidence) {
    ConfidenceLevel.high => 1.00,
    ConfidenceLevel.medium => 0.92,
    ConfidenceLevel.low => 0.82,
    null => 0.90,
  };
}
