import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/task_visual_weight.dart';

export 'entities.dart' show Quadrant, Task;

double taskWeight(
  Task t, {
  Map<Quadrant, double> quadrantLearningAdjustments =
      const <Quadrant, double>{},
}) =>
    computeTaskVisualWeight(
      t,
      quadrantLearningAdjustments: quadrantLearningAdjustments,
    );

/// Centralized importance weight for matrix visualization.
double importanceWeight(
  Task t, {
  DateTime? now,
  Map<Quadrant, double> quadrantLearningAdjustments =
      const <Quadrant, double>{},
}) =>
    computeTaskVisualWeight(
      t,
      quadrantLearningAdjustments: quadrantLearningAdjustments,
    );
