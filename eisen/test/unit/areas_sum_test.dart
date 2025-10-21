import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  test('sum of areas ≈ quadrant area (±1%)', () {
    final tasks = [
      // Q1 three tasks
      Task(id: 'q1a', title: 'A', quadrant: Quadrant.q1, priority: 5, minutes: 60),
      Task(id: 'q1b', title: 'B', quadrant: Quadrant.q1, priority: 8, minutes: 120),
      Task(id: 'q1c', title: 'C', quadrant: Quadrant.q1, priority: 2, minutes: 30),
      // Q2 two tasks
      Task(id: 'q2a', title: 'A', quadrant: Quadrant.q2, priority: 7, minutes: 45),
      Task(id: 'q2b', title: 'B', quadrant: Quadrant.q2, priority: 3, minutes: 15),
      // Q3 one task
      Task(id: 'q3a', title: 'A', quadrant: Quadrant.q3, priority: 5, minutes: 60),
      // Q4 four tasks
      Task(id: 'q4a', title: 'A', quadrant: Quadrant.q4, priority: 6, minutes: 25),
      Task(id: 'q4b', title: 'B', quadrant: Quadrant.q4, priority: 4, minutes: 40),
      Task(id: 'q4c', title: 'C', quadrant: Quadrant.q4, priority: 9, minutes: 80),
      Task(id: 'q4d', title: 'D', quadrant: Quadrant.q4, priority: 1, minutes: 10),
    ];

    final layout = computeStableLayout(tasks);
    final byQ = <Quadrant, List<TreemapRect>>{for (final q in Quadrant.values) q: []};
    for (final r in layout) {
      byQ[r.task.quadrant]!.add(r);
    }
    const quadArea = 0.5 * 0.5; // each quadrant
    for (final q in Quadrant.values) {
      final sum = byQ[q]!.fold<double>(0.0, (a, e) => a + e.rect01.width * e.rect01.height);
      expect((sum - quadArea).abs() / quadArea, lessThan(0.01), reason: 'Area drift in $q: $sum');
    }
  });
}

