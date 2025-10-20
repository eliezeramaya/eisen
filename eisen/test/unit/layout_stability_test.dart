import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

double _area(TreemapRect r) => r.rect01.width * r.rect01.height;

void main() {
  test('small changes cause minimal reorder and small rect deltas', () {
    final tasks = <Task>[];
    for (int i = 0; i < 10; i++) {
      tasks.add(Task(id: 'q2_$i', title: 'T$i', quadrant: Quadrant.q2, priority: 5 + (i % 3), minutes: 30 + i * 5));
    }
    final cache = LayoutCache();
    final a = computeStableLayout(tasks, zoom: Quadrant.q2, cache: cache);

    // Apply a small change to one task
    final tasks2 = tasks.map((t) => t.id == 'q2_5' ? t.copyWith(minutes: t.minutes + 5) : t).toList();
    final b = computeStableLayout(tasks2, zoom: Quadrant.q2, cache: cache);

    // Rank by area
    List<String> rank(List<TreemapRect> l) {
      final s = [...l]..sort((x,y)=>_area(y).compareTo(_area(x)));
      return s.map((e)=>e.task.id).toList();
    }

    final ra = rank(a);
    final rb = rank(b);
    int moved = 0;
    for (final id in ra) {
      final ia = ra.indexOf(id);
      final ib = rb.indexOf(id);
      if (ia != ib) moved++;
    }
    // Allow small number of moves at most
    expect(moved <= 2, isTrue);

    // Rect deltas should be small overall
    final mapA = {for (final r in a) r.task.id: r.rect01};
    final mapB = {for (final r in b) r.task.id: r.rect01};
    double sumDelta = 0;
    for (final id in mapA.keys) {
      final r1 = mapA[id]!;
      final r2 = mapB[id]!;
      sumDelta += (r1.left - r2.left).abs() + (r1.top - r2.top).abs() + (r1.width - r2.width).abs() + (r1.height - r2.height).abs();
    }
    expect(sumDelta < 0.5, isTrue); // heuristic threshold in normalized space
  });
}

