import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';

class ConfidenceResult {
  const ConfidenceResult({
    required this.level,
    required this.reason,
    required this.score,
  });

  final ConfidenceLevel level;
  final String reason;
  final double score;
}

class ClassificationConfidenceInput {
  const ClassificationConfidenceInput({
    required this.source,
    required this.heuristicSignalCount,
    required this.matchedKeywordCount,
    required this.hasCategory,
    required this.hasKind,
    required this.hasHorizon,
    required this.hasEnergy,
    required this.hasPriority,
  });

  final ClassificationSource source;
  final int heuristicSignalCount;
  final int matchedKeywordCount;
  final bool hasCategory;
  final bool hasKind;
  final bool hasHorizon;
  final bool hasEnergy;
  final bool hasPriority;
}

class ConfidenceScorer {
  const ConfidenceScorer();

  ConfidenceResult evaluate(
    ClassificationConfidenceInput input,
    ClassificationSettings settings,
  ) {
    final score = _score(input).clamp(0.0, 1.0);
    final level = levelFor(score, settings);
    final reason = reasonFor(
      source: input.source,
      level: level,
      heuristicSignalCount: input.heuristicSignalCount,
      matchedKeywordCount: input.matchedKeywordCount,
      hasCategory: input.hasCategory,
      hasPriority: input.hasPriority,
    );
    return ConfidenceResult(
      level: level,
      reason: reason,
      score: score,
    );
  }

  double score(ClassificationConfidenceInput input) => _score(input);

  double _score(ClassificationConfidenceInput input) {
    switch (input.source) {
      case ClassificationSource.userCorrection:
        return 0.98;
      case ClassificationSource.rule:
        return 0.6 +
            (input.matchedKeywordCount >= 1 ? 0.18 : 0.0) +
            (input.hasPriority ? 0.06 : 0.0);
      case ClassificationSource.alias:
        return 0.5 +
            (input.matchedKeywordCount >= 2 ? 0.22 : 0.12) +
            (input.hasCategory ? 0.08 : 0.0);
      case ClassificationSource.heuristic:
        return _heuristicScore(input);
      case ClassificationSource.fallback:
        return 0.18;
    }
  }

  double _heuristicScore(ClassificationConfidenceInput input) {
    final filledFields = [
      input.hasCategory,
      input.hasKind,
      input.hasHorizon,
      input.hasEnergy,
      input.hasPriority,
    ].where((item) => item).length;
    var score = 0.08;
    if (input.hasCategory) score += 0.16;
    if (input.hasKind) score += 0.08;
    if (input.hasHorizon) score += 0.08;
    if (input.hasEnergy) score += 0.06;
    if (input.hasPriority) score += 0.06;
    if (input.matchedKeywordCount >= 2) {
      score += 0.3;
    } else if (input.matchedKeywordCount == 1) {
      score += 0.16;
    }
    if (input.heuristicSignalCount >= 4) {
      score += 0.1;
    } else if (input.heuristicSignalCount >= 2) {
      score += 0.04;
    }

    final conflictingSignals = input.matchedKeywordCount == 0 &&
        input.heuristicSignalCount >= 3 &&
        filledFields <= 2;
    if (conflictingSignals) {
      score -= 0.4;
    }

    final ambiguousInput = input.matchedKeywordCount == 0 &&
        input.heuristicSignalCount <= 1 &&
        filledFields <= 2;
    if (ambiguousInput) {
      score -= 0.3;
    }

    return score;
  }

  ConfidenceLevel levelFor(
    double score,
    ClassificationSettings settings,
  ) {
    if (score >= settings.mediumConfidenceThreshold) {
      return ConfidenceLevel.high;
    }
    if (score >= settings.lowConfidenceThreshold) {
      return ConfidenceLevel.medium;
    }
    return ConfidenceLevel.low;
  }

  String reasonFor({
    required ClassificationSource source,
    required ConfidenceLevel level,
    required int heuristicSignalCount,
    int matchedKeywordCount = 0,
    bool hasCategory = false,
    bool hasPriority = false,
  }) {
    switch (source) {
      case ClassificationSource.userCorrection:
        return 'Confianza alta por corrección manual del usuario.';
      case ClassificationSource.rule:
        return 'Matched user rule with strong deterministic signal.';
      case ClassificationSource.alias:
        return 'Matched vocabulary alias with stable personalized mapping.';
      case ClassificationSource.heuristic:
        if (matchedKeywordCount >= 2 && hasCategory) {
          return 'Multiple coherent keywords matched the same heuristic category.';
        }
        if (level == ConfidenceLevel.medium && heuristicSignalCount >= 3) {
          return 'Heuristic match with several consistent signals.';
        }
        if (level == ConfidenceLevel.low && !hasCategory) {
          return 'Input ambiguous: not enough coherent signals to classify safely.';
        }
        return hasPriority
            ? 'Heuristic match with urgency cues but incomplete classification context.'
            : 'Heuristic match with limited evidence.';
      case ClassificationSource.fallback:
        return 'No clear signals found, using safe fallback classification.';
    }
  }
}
