import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/services/urgency_importance_scorer.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scorer = UrgencyImportanceScorer();

  Quadrant infer(
    String text, {
    TimeHorizon? horizon,
    EntryKind? kind,
  }) {
    final urgency = scorer.computeUrgencyScore(
      normalizedText: text,
      horizon: horizon,
    );
    final importance = scorer.computeImportanceScore(
      normalizedText: text,
      kind: kind,
    );
    return inferQuadrant(urgency: urgency, importance: importance);
  }

  test('urgent client delivery is Q1', () {
    final text = 'entrega urgente para cliente hoy';
    final urgency = scorer.computeUrgencyScore(
      normalizedText: text,
      horizon: TimeHorizon.today,
    );
    final importance = scorer.computeImportanceScore(
      normalizedText: text,
      kind: EntryKind.task,
    );

    expect(urgency, greaterThanOrEqualTo(0.65));
    expect(importance, greaterThanOrEqualTo(0.65));
    expect(
        inferQuadrant(urgency: urgency, importance: importance), Quadrant.q1);
  });

  test('growth habit is Q2', () {
    expect(
      infer(
        'mejorar rutina de ejercicio',
        horizon: TimeHorizon.thisMonth,
        kind: EntryKind.habit,
      ),
      Quadrant.q2,
    );
  });

  test('external quick favor is Q3', () {
    expect(
      infer(
        'favor rapido de otra persona',
        horizon: TimeHorizon.thisWeek,
        kind: EntryKind.task,
      ),
      Quadrant.q3,
    );
  });

  test('someday idea is Q4', () {
    expect(
      infer(
        'idea para revisar algun dia',
        horizon: TimeHorizon.someday,
        kind: EntryKind.idea,
      ),
      Quadrant.q4,
    );
  });
}
