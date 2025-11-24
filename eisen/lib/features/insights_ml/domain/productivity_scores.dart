import 'package:flutter/material.dart';

/// Score diario heurístico basado en señales de comportamiento.
class DailyProductivityScore {
  const DailyProductivityScore({
    required this.day,
    required this.overloadScore,
    required this.q2Ratio,
    required this.procrastinationScore,
    required this.focusConsistencyScore,
  });

  final DateTime day;
  final double overloadScore; // 0..1 (1 = muy sobrecargado)
  final double q2Ratio; // 0..1 (proporción de Q2 sobre completadas)
  final double procrastinationScore; // 0..1 (1 = mucha procrastinación)
  final double focusConsistencyScore; // 0..1 (1 = foco consistente)
}

/// Ventana sugerida de foco con confianza heurística.
class FocusWindowSuggestion {
  const FocusWindowSuggestion({
    required this.start,
    required this.end,
    required this.confidence,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final double confidence; // 0..1
}

/// Predicción simplificada de probabilidad de completar a tiempo.
class TaskCompletionPrediction {
  const TaskCompletionPrediction({
    required this.onTimeProbability,
    required this.reprogramProbability,
  });

  final double onTimeProbability; // 0..1
  final double reprogramProbability; // 0..1
}

/// Riesgo de sobrecarga diaria (0 bajo, 1 alto).
class OverloadRisk {
  const OverloadRisk(this.score);
  final double score; // 0..1
}

/// Puntaje de procrastinación (0 bajo, 1 alto).
class ProcrastinationScore {
  const ProcrastinationScore(this.value);
  final double value; // 0..1
}
