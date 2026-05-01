import 'package:eisen/features/atlas/domain/atlas_weight.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Q1 > Q2 > Q3 > Q4 por boost visual', () {
    final q1 = computeAtlasTaskWeight(_task('1', quadrant: Quadrant.q1));
    final q2 = computeAtlasTaskWeight(_task('2', quadrant: Quadrant.q2));
    final q3 = computeAtlasTaskWeight(_task('3', quadrant: Quadrant.q3));
    final q4 = computeAtlasTaskWeight(_task('4', quadrant: Quadrant.q4));

    expect(q1, greaterThan(q2));
    expect(q2, greaterThan(q3));
    expect(q3, greaterThan(q4));
  });

  test('baja confianza reduce peso', () {
    final high = computeAtlasTaskWeight(
      _task('1', confidence: ConfidenceLevel.high),
    );
    final low = computeAtlasTaskWeight(
      _task('2', confidence: ConfidenceLevel.low),
    );

    expect(high, greaterThan(low));
  });

  test('archivada reduce peso y completada se excluye', () {
    final active = _task('1');
    final archived = _task('2', isArchived: true);
    final completed = _task('3', completedAt: DateTime(2026));

    expect(computeAtlasTaskWeight(archived),
        lessThan(computeAtlasTaskWeight(active)));
    expect(includeTaskInAtlas(archived), isFalse);
    expect(includeTaskInAtlas(archived, showArchived: true), isTrue);
    expect(includeTaskInAtlas(completed), isFalse);
  });

  test('no produce peso cero', () {
    final weight = computeAtlasTaskWeight(
      _task('1', priority: -10, minutes: -10),
    );

    expect(weight, greaterThanOrEqualTo(1.0));
    expect(weight.isFinite, isTrue);
  });
}

Task _task(
  String id, {
  Quadrant quadrant = Quadrant.q2,
  int priority = 5,
  int minutes = 30,
  ConfidenceLevel? confidence = ConfidenceLevel.high,
  bool isArchived = false,
  DateTime? completedAt,
}) {
  return Task(
    id: id,
    title: 'Task $id',
    quadrant: quadrant,
    priority: priority,
    minutes: minutes,
    classificationConfidence: confidence,
    isArchived: isArchived,
    completedAt: completedAt,
  );
}
