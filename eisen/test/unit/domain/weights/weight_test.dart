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

  test('quadrant-aware boost protects Q2 over Q3 and Q4', () {
    final base = Task(
        id: 'a', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);
    final q1 = base.copyWith(quadrant: Quadrant.q1);
    final q3 = base.copyWith(quadrant: Quadrant.q3);
    final q4 = base.copyWith(quadrant: Quadrant.q4);
    // Q2 (growth) should remain more visible than urgent-but-low-importance Q3.
    expect(weight(q1) > weight(base), isTrue);
    expect(weight(base) > weight(q3), isTrue);
    expect(weight(q3) > weight(q4), isTrue);
  });
}
