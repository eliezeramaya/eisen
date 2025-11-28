import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weight increases with priority and minutes', () {
    final base = Task(
        id: '1', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);
    final low = base.copyWith(priority: 3, minutes: 10);
    final high = base.copyWith(priority: 9, minutes: 120);
    expect(weight(high) > weight(base), isTrue);
    expect(weight(base) > weight(low), isTrue);
  });

  test('urgent quadrants get boost (q1/q3 urgent)', () {
    final base = Task(
        id: 'a', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);
    final q1 = base.copyWith(quadrant: Quadrant.q1);
    final q3 = base.copyWith(quadrant: Quadrant.q3);
    final q4 = base.copyWith(quadrant: Quadrant.q4);
    // Q1 and Q3 are urgent, thus boosted relative to base (Q2: important but not urgent)
    expect(weight(q1) > weight(base), isTrue);
    expect(weight(q3) > weight(base), isTrue);
    // Q4 is neither urgent nor important; should not exceed base solely due to quadrant
    expect(weight(q4) <= weight(q1), isTrue);
  });
}
