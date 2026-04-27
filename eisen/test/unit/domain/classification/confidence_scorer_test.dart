import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/confidence_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scorer = ConfidenceScorer();
  const settings = ClassificationSettingsDefaults.value;

  test('gives high confidence to user rules with explicit reason', () {
    final result = scorer.evaluate(
      const ClassificationConfidenceInput(
        source: ClassificationSource.rule,
        heuristicSignalCount: 0,
        matchedKeywordCount: 1,
        hasCategory: true,
        hasKind: true,
        hasHorizon: true,
        hasEnergy: true,
        hasPriority: true,
      ),
      settings,
    );

    expect(result.level, ConfidenceLevel.high);
    expect(result.score, greaterThanOrEqualTo(0.6));
    expect(result.reason, contains('Matched user rule'));
  });

  test('rewards aliases with medium-high score', () {
    final result = scorer.evaluate(
      const ClassificationConfidenceInput(
        source: ClassificationSource.alias,
        heuristicSignalCount: 1,
        matchedKeywordCount: 2,
        hasCategory: true,
        hasKind: true,
        hasHorizon: true,
        hasEnergy: true,
        hasPriority: false,
      ),
      settings,
    );

    expect(result.level, ConfidenceLevel.high);
    expect(result.score, greaterThan(0.7));
  });

  test('penalizes ambiguous heuristic input', () {
    final result = scorer.evaluate(
      const ClassificationConfidenceInput(
        source: ClassificationSource.heuristic,
        heuristicSignalCount: 1,
        matchedKeywordCount: 0,
        hasCategory: false,
        hasKind: true,
        hasHorizon: false,
        hasEnergy: false,
        hasPriority: false,
      ),
      settings,
    );

    expect(result.level, ConfidenceLevel.low);
    expect(result.score, lessThan(0.2));
    expect(result.reason, contains('ambiguous'));
  });

  test('rewards multiple coherent heuristic keywords', () {
    final result = scorer.evaluate(
      const ClassificationConfidenceInput(
        source: ClassificationSource.heuristic,
        heuristicSignalCount: 4,
        matchedKeywordCount: 3,
        hasCategory: true,
        hasKind: true,
        hasHorizon: true,
        hasEnergy: true,
        hasPriority: true,
      ),
      settings,
    );

    expect(result.level, ConfidenceLevel.high);
    expect(result.score, greaterThan(0.7));
    expect(result.reason, contains('Multiple coherent keywords'));
  });
}
