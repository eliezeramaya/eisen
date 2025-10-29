import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

double _area(ui.Rect r) => r.width * r.height;

void main() {
  test('treemap layout small change has minimal area delta', () async {
    final tasks = <Task>[
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 6, minutes: 60),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q1, priority: 5, minutes: 45),
      Task(id: 'c', title: 'C', quadrant: Quadrant.q2, priority: 4, minutes: 30),
      Task(id: 'd', title: 'D', quadrant: Quadrant.q3, priority: 7, minutes: 90),
    ];
    final cache = LayoutCache();
    final layout1 = computeStableLayout(tasks, cache: cache);
    // Small change in one task's minutes
    final tasks2 = tasks.map((t) => t.id == 'b' ? t.copyWith(minutes: t.minutes + 5) : t).toList();
    final layout2 = computeStableLayout(tasks2, cache: cache);

    // Compare normalized area deltas per-task
    final map1 = {for (final tr in layout1) tr.task.id: tr.rect01};
    final map2 = {for (final tr in layout2) tr.task.id: tr.rect01};
    double totalDelta = 0.0;
    for (final id in map1.keys) {
      if (!map2.containsKey(id)) continue;
      final a1 = _area(map1[id]!);
      final a2 = _area(map2[id]!);
      totalDelta += (a1 - a2).abs();
    }
    // Expect less than 3% total area shift across all tiles
    expect(totalDelta < 0.03, isTrue);
  });
}
