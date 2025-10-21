import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  test('shelf aspect ratios reasonable (avg < 8, max <= 20)', () {
    final tasks = <Task>[];
    // Generate a mix with one outlier and many smalls per quadrant
    for (final q in Quadrant.values) {
      tasks.add(Task(id: '${q.name}_big', title: 'Big', quadrant: q, priority: 10, minutes: 240));
      for (var i = 0; i < 15; i++) {
        tasks.add(Task(id: '${q.name}_s$i', title: 's$i', quadrant: q, priority: 1 + (i % 3), minutes: 5 + (i % 5) * 5));
      }
    }
    final layout = computeStableLayout(tasks);
    final ratios = <double>[];
    for (final r in layout) {
      final w = r.rect01.width, h = r.rect01.height;
      if (w <= 0 || h <= 0) continue;
      final ratio = w >= h ? (w / h) : (h / w);
      ratios.add(ratio);
    }
    final avg = ratios.fold<double>(0, (a, b) => a + b) / math.max(1, ratios.length);
    final maxR = ratios.fold<double>(0, (a, b) => math.max(a, b));
    expect(avg < 8.0, isTrue, reason: 'avg=$avg');
    expect(maxR <= 20.0, isTrue, reason: 'max=$maxR');
  });
}

