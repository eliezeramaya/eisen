import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/matrix/domain/entities.dart';

void main() {
  test('weight increases with priority and minutes', () {
    final base = Task(id: '1', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);
    final low = base.copyWith(priority: 3, minutes: 10);
    final high = base.copyWith(priority: 9, minutes: 120);
    expect(weight(high) > weight(base), isTrue);
    expect(weight(base) > weight(low), isTrue);
  });

  test('urgent quadrants get boost (q1/q3)', () {
    final q2 = Task(id: 'a', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);
    final q1 = q2.copyWith(quadrant: Quadrant.q1);
    final q3 = q2.copyWith(quadrant: Quadrant.q3);
    expect(weight(q1) > weight(q2), isTrue);
    expect(weight(q3) > weight(q2), isTrue);
  });
}
