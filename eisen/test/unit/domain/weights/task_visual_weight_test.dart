import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/task_visual_weight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Task task({
    Quadrant quadrant = Quadrant.q1,
    ConfidenceLevel? confidence,
    TimeHorizon? horizon,
  }) {
    return Task(
      id: quadrant.name,
      title: 't',
      quadrant: quadrant,
      priority: 5,
      minutes: 60,
      classificationConfidence: confidence,
      horizon: horizon,
    );
  }

  test('quadrant boost orders Q1 > Q2 > Q3 > Q4', () {
    final q1 = computeTaskVisualWeight(task(quadrant: Quadrant.q1));
    final q2 = computeTaskVisualWeight(task(quadrant: Quadrant.q2));
    final q3 = computeTaskVisualWeight(task(quadrant: Quadrant.q3));
    final q4 = computeTaskVisualWeight(task(quadrant: Quadrant.q4));

    expect(q1, greaterThan(q2));
    expect(q2, greaterThan(q3));
    expect(q3, greaterThan(q4));
  });

  test('low confidence reduces visual weight', () {
    final high = computeTaskVisualWeight(
      task(confidence: ConfidenceLevel.high),
    );
    final low = computeTaskVisualWeight(
      task(confidence: ConfidenceLevel.low),
    );

    expect(low, lessThan(high));
  });

  test('someday horizon reduces visual weight', () {
    final week = computeTaskVisualWeight(task(horizon: TimeHorizon.thisWeek));
    final someday = computeTaskVisualWeight(task(horizon: TimeHorizon.someday));

    expect(someday, lessThan(week));
  });

  test('learning adjustment can raise a quadrant visual weight', () {
    final baseline = computeTaskVisualWeight(task(quadrant: Quadrant.q2));
    final adjusted = computeTaskVisualWeight(
      task(quadrant: Quadrant.q2),
      quadrantLearningAdjustments: const <Quadrant, double>{
        Quadrant.q2: 1.12,
      },
    );

    expect(adjusted, greaterThan(baseline));
  });
}
