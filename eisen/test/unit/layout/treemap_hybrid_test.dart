import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';

void main() {
  test('Top-K assigns tiles and rest forms a +N cluster with area > 0', () {
    final tasks = <Task>[];
    for (int i = 0; i < 30; i++) {
      tasks.add(Task(
        id: 't$i',
        title: 'T$i',
        quadrant: Quadrant.q1,
        priority: (i % 10) + 1,
        minutes: 30,
      ));
    }

    const cfg = LayoutConfig(topKPerQuadrant: 10, minAreaNormalized: 0.00000001, gamma: 1.0);
    final engine = EisenTreemapHybrid(cfg);
    final layout = engine.layout(tasks);
    final q1Rects = layout.where((e) => e.task.quadrant == Quadrant.q1).toList();
    final clusters = q1Rects.where((e) => e.stackChildren.isNotEmpty).toList();
    // Debug counts to help diagnose on CI
    // ignore: avoid_print
    print('layout total: \\${layout.length}, q1 rects: \\${q1Rects.length}, clusters: \\${clusters.length}');

    expect(q1Rects.where((e) => e.stackChildren.isEmpty).length, inInclusiveRange(1, 10));
    expect(clusters.length, 1);
    expect(clusters.first.stackChildren.length, 20);
    final area = clusters.first.rect01.width * clusters.first.rect01.height;
    expect(area, greaterThan(0));
  });
}
