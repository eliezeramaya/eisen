import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/quadrant_learning_engine.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = QuadrantLearningEngine();

  ClassificationCorrectionEvent correction({
    required Quadrant from,
    required Quadrant to,
  }) {
    return ClassificationCorrectionEvent(
      id: 'c-${from.name}-${to.name}',
      rawText: 'entrada',
      originalCategoryId: null,
      correctedCategoryId: null,
      originalKind: null,
      correctedKind: null,
      originalHorizon: null,
      correctedHorizon: null,
      originalEnergy: null,
      correctedEnergy: null,
      originalQuadrant: from,
      correctedQuadrant: to,
      confidenceBefore: ConfidenceLevel.medium,
      createdAt: DateTime(2026),
    );
  }

  test('learns visual weight factors from quadrant corrections', () {
    final profile = engine.learnFromCorrections([
      correction(from: Quadrant.q4, to: Quadrant.q2),
      correction(from: Quadrant.q3, to: Quadrant.q2),
      correction(from: Quadrant.q4, to: Quadrant.q1),
    ]);

    expect(profile.hasSignals, isTrue);
    expect(profile.transitionCount, 3);
    expect(profile.factorFor(Quadrant.q2), greaterThan(1.0));
    expect(profile.factorFor(Quadrant.q4), lessThan(1.0));
  });

  test('returns neutral profile without quadrant transitions', () {
    final profile = engine.learnFromCorrections(const []);

    expect(profile.hasSignals, isFalse);
    expect(profile.factorFor(Quadrant.q2), 1.0);
  });
}
