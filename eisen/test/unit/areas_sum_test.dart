import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  test('sum of areas per quadrant ≈ 100% ± 1%', () {
    final tasks = <Task>[
      // Q1
      Task(id: 'q1_a', title: 'A', quadrant: Quadrant.q1, priority: 8, minutes: 60),
      Task(id: 'q1_b', title: 'B', quadrant: Quadrant.q1, priority: 5, minutes: 30),
      Task(id: 'q1_c', title: 'C', quadrant: Quadrant.q1, priority: 3, minutes: 45),
      // Q2
      Task(id: 'q2_a', title: 'A', quadrant: Quadrant.q2, priority: 9, minutes: 90),
      Task(id: 'q2_b', title: 'B', quadrant: Quadrant.q2, priority: 6, minutes: 45),
      // Q3
      Task(id: 'q3_a', title: 'A', quadrant: Quadrant.q3, priority: 4, minutes: 30),
      Task(id: 'q3_b', title: 'B', quadrant: Quadrant.q3, priority: 7, minutes: 30),
      // Q4
      Task(id: 'q4_a', title: 'A', quadrant: Quadrant.q4, priority: 2, minutes: 20),
      Task(id: 'q4_b', title: 'B', quadrant: Quadrant.q4, priority: 3, minutes: 40),
      Task(id: 'q4_c', title: 'C', quadrant: Quadrant.q4, priority: 5, minutes: 25),
    ];

    final layout = computeStableLayout(tasks);
    expect(layout, isNotEmpty);

    for (final q in Quadrant.values) {
      final tiles = layout.where((t) => t.task.quadrant == q).toList();
      if (tiles.isEmpty) continue;
      final sum = tiles.fold<double>(0, (a, r) => a + r.rect01.width * r.rect01.height);
      // Quadrant occupies 0.5 x 0.5 = 0.25 of full area
      const quadArea = 0.25;
      final relErr = ((sum - quadArea).abs()) / quadArea;
      expect(relErr, lessThan(0.01), reason: 'Area drift in $q beyond 1%: sum=$sum');
    }
  });
}

