import 'dart:math' as math;

import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class QuadrantInferenceResult {
  const QuadrantInferenceResult({
    required this.suggestedQuadrant,
    required this.urgencyScore,
    required this.importanceScore,
    required this.reason,
  });

  final Quadrant suggestedQuadrant;
  final double urgencyScore;
  final double importanceScore;
  final String reason;
}

class UrgencyImportanceScorer {
  const UrgencyImportanceScorer();

  double computeUrgencyScore({
    required String normalizedText,
    TimeHorizon? horizon,
  }) {
    var score = 0.30;

    if (_containsAny(normalizedText, _veryStrongUrgencySignals)) score += 0.40;
    if (_containsAny(normalizedText, _strongUrgencySignals)) score += 0.25;
    if (_containsAny(normalizedText, _mediumUrgencySignals)) score += 0.15;
    if (_containsAny(normalizedText, _externalDemandSignals)) score += 0.12;
    if (_containsAny(normalizedText, _lowUrgencySignals)) score -= 0.25;

    score += switch (horizon) {
      TimeHorizon.today => 0.30,
      TimeHorizon.thisWeek => 0.15,
      TimeHorizon.thisMonth => 0.06,
      TimeHorizon.someday => -0.22,
      null => 0.0,
    };

    return _clamp01(score);
  }

  double computeImportanceScore({
    required String normalizedText,
    EntryKind? kind,
    String? category,
    List<String> autoTags = const <String>[],
  }) {
    var score = 0.42;
    final categoryText = category?.toLowerCase() ?? '';
    final tagText = autoTags.join(' ').toLowerCase();
    final combined = '$normalizedText $categoryText $tagText';

    if (_containsAny(combined, _workImportanceSignals)) score += 0.28;
    if (_containsAny(combined, _growthImportanceSignals)) score += 0.30;
    if (_containsAny(combined, _financeImportanceSignals)) score += 0.22;
    if (_containsAny(combined, _lowImportanceSignals)) score -= 0.26;
    if (_containsAny(combined, _externalDemandSignals)) score -= 0.12;

    score += switch (kind) {
      EntryKind.project => 0.24,
      EntryKind.habit => 0.20,
      EntryKind.idea => _containsAny(combined, _ideaImportantSignals)
          ? 0.12
          : (_containsAny(combined, _lowUrgencySignals) ? -0.18 : -0.06),
      EntryKind.shoppingItem =>
        _containsAny(normalizedText, _veryStrongUrgencySignals) ? 0.02 : -0.12,
      EntryKind.reminder => 0.02,
      EntryKind.task => 0.0,
      null => 0.0,
    };

    return _clamp01(score);
  }

  QuadrantInferenceResult infer({
    required double urgency,
    required double importance,
  }) {
    final quadrant = inferQuadrant(urgency: urgency, importance: importance);
    return QuadrantInferenceResult(
      suggestedQuadrant: quadrant,
      urgencyScore: _clamp01(urgency),
      importanceScore: _clamp01(importance),
      reason: quadrantInferenceReason(quadrant),
    );
  }
}

Quadrant inferQuadrant({
  required double urgency,
  required double importance,
}) {
  if (urgency >= 0.65 && importance >= 0.65) return Quadrant.q1;
  if (urgency < 0.65 && importance >= 0.65) return Quadrant.q2;
  if (urgency >= 0.65 && importance < 0.65) return Quadrant.q3;
  return Quadrant.q4;
}

String quadrantInferenceReason(Quadrant quadrant) {
  return switch (quadrant) {
    Quadrant.q1 => 'Alta urgencia y alta importancia',
    Quadrant.q2 => 'Importante pero no urgente',
    Quadrant.q3 => 'Urgente, pero con baja importancia',
    Quadrant.q4 => 'Baja urgencia y baja importancia',
  };
}

bool _containsAny(String input, Iterable<String> needles) {
  return needles.any(input.contains);
}

double _clamp01(double value) => math.max(0.0, math.min(1.0, value));

const _veryStrongUrgencySignals = <String>[
  'hoy',
  'ahora',
  'ahorita',
  'urgente',
  'vencimiento',
  'deadline',
  'entregar hoy',
  'antes de',
  'para hoy',
];

const _strongUrgencySignals = <String>[
  'entrega',
  'cliente esperando',
  'problema',
  'bloquear',
  'bloquea',
  'resolver',
  'ultimo dia',
  'último día',
  'rapido',
  'rápido',
];

const _mediumUrgencySignals = <String>[
  'manana',
  'mañana',
  'esta semana',
  'lunes',
  'martes',
  'miercoles',
  'miércoles',
  'jueves',
  'viernes',
  'sabado',
  'sábado',
  'domingo',
];

const _lowUrgencySignals = <String>[
  'algun dia',
  'algún día',
  'luego',
  'despues',
  'después',
  'mas adelante',
  'más adelante',
  'cuando pueda',
  'sin prisa',
];

const _externalDemandSignals = <String>[
  'favor',
  'otra persona',
  'alguien',
  'externo',
  'interrupcion',
  'interrupción',
];

const _workImportanceSignals = <String>[
  'proyecto',
  'cliente',
  'entrega final',
  'estrategia',
  'propuesta',
  'contrato',
  'obra',
  'planos',
  'render',
  'presupuesto',
];

const _growthImportanceSignals = <String>[
  'mejorar',
  'aprender',
  'estudiar',
  'practicar',
  'habito',
  'hábito',
  'rutina',
  'salud',
  'ejercicio',
  'meta',
  'objetivo',
  'crecimiento',
  'largo plazo',
];

const _financeImportanceSignals = <String>[
  'pagar',
  'factura',
  'banco',
  'tarjeta',
  'impuestos',
  'transferencia',
];

const _lowImportanceSignals = <String>[
  'favor',
  'rapido',
  'rápido',
  'opcional',
  'tal vez',
  'curioso',
  'algun dia',
  'algún día',
  'revisar despues',
  'revisar después',
  'si hay tiempo',
  'sin importancia',
];

const _ideaImportantSignals = <String>[
  'meta',
  'proyecto',
  'mejorar',
  'objetivo',
  'crecimiento',
];
