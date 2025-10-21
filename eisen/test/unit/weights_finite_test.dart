import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

void main() {
  test('weight is finite and non-negative with clamps', () {
    final now = DateTime.now();
    final tasks = [
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 1, minutes: 5),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q2, priority: 10, minutes: 240, due: now.add(const Duration(days: 1))),
      Task(id: 'c', title: 'C', quadrant: Quadrant.q3, priority: 999, minutes: -1000, due: null),
      Task(id: 'd', title: 'D', quadrant: Quadrant.q4, priority: -999, minutes: 9999999, due: now.subtract(const Duration(days: 2))),
    ];
    for (final t in tasks) {
      final w = weight(t);
      expect(w.isFinite, isTrue, reason: 'Weight must be finite');
      expect(w.isNaN, isFalse, reason: 'Weight must not be NaN');
      expect(w >= 0, isTrue, reason: 'Weight must be non-negative');
    }
  });
}

