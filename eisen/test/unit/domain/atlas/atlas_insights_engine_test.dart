import 'package:eisen/features/atlas/application/atlas_insights_engine.dart';
import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 1, 10);

  test('detecta sobrecarga del dia y prioriza insight alto', () {
    final insights = buildAtlasInsights(
      now: now,
      tasks: [
        for (var index = 0; index < 4; index++)
          _task(
            '$index',
            due: now,
            minutes: 45,
            priority: 8 - index,
          ),
      ],
    );

    expect(insights.first.kind, AtlasInsightKind.overload);
    expect(insights.first.priority, AtlasInsightPriority.high);
    expect(insights.first.taskIds, hasLength(4));
    expect(
      insights.first.actions.map((action) => action.kind),
      contains(AtlasInsightActionKind.editPrimaryTask),
    );
  });

  test('detecta oportunidad de foco Q2', () {
    final insights = buildAtlasInsights(
      now: now,
      tasks: [
        _task('q2', quadrant: Quadrant.q2, priority: 8, minutes: 60),
        _task('q4', quadrant: Quadrant.q4),
      ],
    );

    expect(
      insights.map((insight) => insight.kind),
      contains(AtlasInsightKind.focusOpportunity),
    );
    expect(insights.single.primaryTaskId, 'q2');
  });

  test('ignora tareas archivadas y completadas', () {
    final insights = buildAtlasInsights(
      now: now,
      tasks: [
        _task('archived', quadrant: Quadrant.q2, priority: 9, isArchived: true),
        _task('done', quadrant: Quadrant.q2, priority: 9, completedAt: now),
      ],
    );

    expect(insights, isEmpty);
  });

  test('detecta revision de clasificacion con confianza baja', () {
    final insights = buildAtlasInsights(
      now: now,
      tasks: [
        _task('a', confidence: ConfidenceLevel.low),
        _task('b', confidence: ConfidenceLevel.low),
      ],
    );

    expect(insights.single.kind, AtlasInsightKind.classificationReview);
    expect(
      insights.single.actions.map((action) => action.kind),
      contains(AtlasInsightActionKind.reclassifyPrimaryTask),
    );
    expect(
      insights.single.actions.map((action) => action.kind),
      contains(AtlasInsightActionKind.filterLowConfidence),
    );
  });
}

Task _task(
  String id, {
  Quadrant quadrant = Quadrant.q1,
  int priority = 5,
  int minutes = 30,
  DateTime? due,
  DateTime? completedAt,
  bool isArchived = false,
  ConfidenceLevel? confidence,
}) {
  return Task(
    id: id,
    title: 'Task $id',
    quadrant: quadrant,
    priority: priority,
    minutes: minutes,
    due: due,
    completedAt: completedAt,
    isArchived: isArchived,
    classificationConfidence: confidence,
  );
}
