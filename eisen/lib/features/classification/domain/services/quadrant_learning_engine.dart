import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class QuadrantLearningProfile {
  const QuadrantLearningProfile({
    this.visualWeightAdjustments = const <Quadrant, double>{},
    this.transitionCount = 0,
  });

  static const neutral = QuadrantLearningProfile();

  final Map<Quadrant, double> visualWeightAdjustments;
  final int transitionCount;

  bool get hasSignals => transitionCount > 0;

  double factorFor(Quadrant quadrant) {
    return visualWeightAdjustments[quadrant] ?? 1.0;
  }
}

class QuadrantLearningEngine {
  const QuadrantLearningEngine({
    this.maxBoost = 1.18,
    this.minPenalty = 0.85,
  });

  final double maxBoost;
  final double minPenalty;

  QuadrantLearningProfile learnFromCorrections(
    List<ClassificationCorrectionEvent> corrections,
  ) {
    final deltas = <Quadrant, double>{
      for (final quadrant in Quadrant.values) quadrant: 0.0,
    };
    var transitions = 0;

    for (final correction in corrections) {
      final corrected = correction.correctedQuadrant;
      final original = correction.originalQuadrant;
      if (corrected == null || corrected == original) continue;

      transitions += 1;
      deltas[corrected] = (deltas[corrected] ?? 0) + 0.04;
      if (original != null) {
        deltas[original] = (deltas[original] ?? 0) - 0.02;
      }
    }

    if (transitions == 0) return QuadrantLearningProfile.neutral;

    return QuadrantLearningProfile(
      transitionCount: transitions,
      visualWeightAdjustments: {
        for (final quadrant in Quadrant.values)
          quadrant: (1.0 + (deltas[quadrant] ?? 0.0))
              .clamp(minPenalty, maxBoost)
              .toDouble(),
      },
    );
  }
}
