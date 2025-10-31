import 'dart:math' as math;

import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('squarified layout yields acceptable aspect ratios', () {
    // Diverse tasks across all quadrants
    final tasks = <Task>[
      for (int i = 0; i < 8; i++)
        Task(
            id: 'q1_$i',
            title: 'q1_$i',
            quadrant: Quadrant.q1,
            priority: 4 + i % 6,
            minutes: 15 + 5 * i),
      for (int i = 0; i < 6; i++)
        Task(
            id: 'q2_$i',
            title: 'q2_$i',
            quadrant: Quadrant.q2,
            priority: 5 + i % 5,
            minutes: 20 + 7 * i),
      for (int i = 0; i < 7; i++)
        Task(
            id: 'q3_$i',
            title: 'q3_$i',
            quadrant: Quadrant.q3,
            priority: 3 + i % 6,
            minutes: 10 + 9 * i),
      for (int i = 0; i < 9; i++)
        Task(
            id: 'q4_$i',
            title: 'q4_$i',
            quadrant: Quadrant.q4,
            priority: 2 + i % 7,
            minutes: 8 + 4 * i),
    ];

    final layout = computeStableLayout(tasks);
    expect(layout, isNotEmpty);

    final ratios = <double>[];
    for (final tr in layout) {
      final w = tr.rect01.width;
      final h = tr.rect01.height;
      if (w <= 0 || h <= 0) continue;
      final r = w / h;
      ratios.add(r < 1 ? 1 / r : r);
    }
    final avg = ratios.reduce((a, b) => a + b) / ratios.length;
    final worst = ratios.reduce(math.max);
    expect(avg < 8.0, isTrue, reason: 'Average ratio too high: $avg');
    expect(worst < 20.0, isTrue, reason: 'Worst ratio too high: $worst');
  });
}
