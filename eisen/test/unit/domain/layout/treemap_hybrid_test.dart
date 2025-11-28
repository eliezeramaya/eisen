import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:flutter_test/flutter_test.dart';

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

    const cfg = LayoutConfig(
        topKPerQuadrant: 10, minAreaNormalized: 0.00000001, gamma: 1.0);
    final engine = EisenTreemapHybrid(cfg);
    final layout = engine.layout(tasks);
    final q1Rects =
        layout.where((e) => e.task.quadrant == Quadrant.q1).toList();
    final clusters = q1Rects.where((e) => e.stackChildren.isNotEmpty).toList();
    // Debug counts to help diagnose on CI
    // ignore: avoid_print
    print(
        'layout total: \\${layout.length}, q1 rects: \\${q1Rects.length}, clusters: \\${clusters.length}');

    expect(q1Rects.where((e) => e.stackChildren.isEmpty).length,
        inInclusiveRange(1, 10));
    expect(clusters.length, 1);
    expect(clusters.first.stackChildren.length, 20);
    final area = clusters.first.rect01.width * clusters.first.rect01.height;
    expect(area, greaterThan(0));
  });

  test('Quadrant bounds and padded area are respected', () {
    final tasks = <Task>[];
    for (final q in Quadrant.values) {
      for (int i = 0; i < 4; i++) {
        tasks.add(Task(
          id: '${q.name}_$i',
          title: 'T$q$i',
          quadrant: q,
          priority: 5 + i,
          minutes: 30 + i * 5,
        ));
      }
    }

    const cfg = LayoutConfig(
      topKPerQuadrant: 6,
      minAreaNormalized: 0.000001,
      gamma: 1.0,
      quadrantPadding: 0.012,
    );
    final engine = EisenTreemapHybrid(cfg);
    final layout = engine.layout(tasks);

    double areaFor(Quadrant q) {
      return layout
          .where((e) => e.task.quadrant == q)
          .fold<double>(0, (a, e) => a + e.rect01.width * e.rect01.height);
    }

    const quadSide = 0.5;
    final paddedSide = quadSide - (cfg.quadrantPadding * 2);
    final expectedArea = paddedSide * paddedSide;

    for (final tr in layout) {
      final r = tr.rect01;
      switch (tr.task.quadrant) {
        case Quadrant.q1:
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(quadSide + 1e-6));
          expect(r.bottom, lessThanOrEqualTo(quadSide + 1e-6));
          break;
        case Quadrant.q2:
          expect(r.left, greaterThanOrEqualTo(quadSide - 1e-6));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(1.000001));
          expect(r.bottom, lessThanOrEqualTo(quadSide + 1e-6));
          break;
        case Quadrant.q3:
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.top, greaterThanOrEqualTo(quadSide - 1e-6));
          expect(r.right, lessThanOrEqualTo(quadSide + 1e-6));
          expect(r.bottom, lessThanOrEqualTo(1.000001));
          break;
        case Quadrant.q4:
          expect(r.left, greaterThanOrEqualTo(quadSide - 1e-6));
          expect(r.top, greaterThanOrEqualTo(quadSide - 1e-6));
          expect(r.right, lessThanOrEqualTo(1.000001));
          expect(r.bottom, lessThanOrEqualTo(1.000001));
          break;
      }
    }

    for (final q in Quadrant.values) {
      final sum = areaFor(q);
      expect(
        sum,
        closeTo(expectedArea, 0.01),
        reason: 'Area for $q should roughly fill padded quadrant',
      );
    }
  });

  test('only parameter uses full canvas for a single quadrant', () {
    final tasks = <Task>[
      for (int i = 0; i < 5; i++)
        Task(
          id: 'q3_$i',
          title: 'Q3 $i',
          quadrant: Quadrant.q3,
          priority: 5 + i,
          minutes: 10 + i * 5,
        ),
      Task(
        id: 'q1_ignore',
        title: 'Ignore',
        quadrant: Quadrant.q1,
        priority: 3,
        minutes: 15,
      ),
    ];

    const cfg = LayoutConfig(
      topKPerQuadrant: 10,
      minAreaNormalized: 0.000001,
      gamma: 1.0,
      quadrantPadding: 0.0,
    );
    final engine = EisenTreemapHybrid(cfg);
    final layout = engine.layout(tasks, only: Quadrant.q3);

    expect(layout.every((e) => e.task.quadrant == Quadrant.q3), isTrue);
    expect(layout.length, greaterThan(0));

    final area = layout
        .fold<double>(0, (a, e) => a + e.rect01.width * e.rect01.height);
    expect(
      area,
      closeTo(1.0, 0.001),
      reason: 'When zooming, padded area should cover the full canvas',
    );
  });
}
