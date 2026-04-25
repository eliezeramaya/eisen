import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';

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

  double score(ClassificationConfidenceInput input) {
    switch (input.source) {
      case ClassificationSource.userCorrection:
        return 0.98;
      case ClassificationSource.rule:
        return 0.92;
      case ClassificationSource.alias:
        return input.matchedKeywordCount >= 2 ? 0.88 : 0.82;
      case ClassificationSource.heuristic:
        final filledFields = [
          input.hasCategory,
          input.hasKind,
          input.hasHorizon,
          input.hasEnergy,
          input.hasPriority,
        ].where((item) => item).length;
        if (input.heuristicSignalCount >= 3 && filledFields >= 3) {
          return 0.62;
        }
        if (input.heuristicSignalCount >= 2 && filledFields >= 2) {
          return 0.48;
        }
        return 0.28;
      case ClassificationSource.fallback:
        return 0.18;
    }
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
  }) {
    switch (source) {
      case ClassificationSource.userCorrection:
        return 'Confianza alta por corrección manual del usuario.';
      case ClassificationSource.rule:
        return 'Confianza alta por coincidencia con una regla del usuario.';
      case ClassificationSource.alias:
        return 'Confianza alta por alias claro del vocabulario personal.';
      case ClassificationSource.heuristic:
        if (level == ConfidenceLevel.medium && heuristicSignalCount >= 3) {
          return 'Confianza media por múltiples señales heurísticas.';
        }
        return 'Confianza baja por heurística ambigua.';
      case ClassificationSource.fallback:
        return 'Confianza baja porque se aplicó la clasificación por defecto.';
    }
  }
}
