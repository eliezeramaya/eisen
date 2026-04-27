import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/suggestion_engine.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SuggestionEngine();

  ClassificationCorrectionEvent correction(int index) {
    return ClassificationCorrectionEvent(
      id: 'correction-$index',
      rawText: 'rosario seguimiento',
      originalCategoryId: null,
      correctedCategoryId: null,
      originalKind: null,
      correctedKind: null,
      originalHorizon: null,
      correctedHorizon: null,
      originalEnergy: null,
      correctedEnergy: null,
      originalQuadrant: Quadrant.q4,
      correctedQuadrant: Quadrant.q2,
      confidenceBefore: ConfidenceLevel.medium,
      detectedKeyword: 'rosario',
      createdAt: DateTime(2026, 1, index + 1),
    );
  }

  test('suggests a user rule from repeated quadrant corrections', () {
    final suggestions = engine.suggestRules([
      correction(0),
      correction(1),
      correction(2),
    ]);

    expect(suggestions, hasLength(1));
    expect(suggestions.single.suggestedRule.targetQuadrant, Quadrant.q2);
    expect(suggestions.single.suggestedRule.targetCategoryId, isNull);
  });
}
