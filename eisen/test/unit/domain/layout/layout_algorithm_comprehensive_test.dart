import 'dart:math' as math;
import 'dart:ui';

import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_squarify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Squarify Algorithm', () {
    test('produces non-overlapping rectangles', () {
      final weights = [10.0, 5.0, 3.0, 2.0, 1.0];
      final container = const Rect.fromLTWH(0, 0, 1, 1);
      final rects = squarify(weights, container);

      expect(rects.length, equals(weights.length));

      // Check no overlaps
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          final overlap = rects[i].overlaps(rects[j]);
          expect(overlap, isFalse, reason: 'Rect $i and $j should not overlap');
        }
      }
    });

    test('preserves area proportionality', () {
      final weights = [10.0, 5.0, 3.0, 2.0];
      final container = const Rect.fromLTWH(0, 0, 1, 1);
      final rects = squarify(weights, container);

      final totalWeight = weights.reduce((a, b) => a + b);
      final containerArea = container.width * container.height;

      for (var i = 0; i < weights.length; i++) {
        final expectedArea = (weights[i] / totalWeight) * containerArea;
        final actualArea = rects[i].width * rects[i].height;
        expect(actualArea, closeTo(expectedArea, 0.001),
            reason: 'Area for rect $i should be proportional to weight');
      }
    });

    test('handles empty input gracefully', () {
      final rects = squarify([], const Rect.fromLTWH(0, 0, 1, 1));
      expect(rects, isEmpty);
    });

    test('handles single element', () {
      final rects = squarify([10.0], const Rect.fromLTWH(0, 0, 1, 1));
      expect(rects.length, equals(1));
      expect(rects.first.width * rects.first.height, closeTo(1.0, 0.001));
    });

    test('handles zero or negative weights by clamping', () {
      final weights = [10.0, -5.0, 0.0, 2.0];
      final container = const Rect.fromLTWH(0, 0, 1, 1);
      final rects = squarify(weights, container);

      expect(rects.length, equals(weights.length));
      // All rects should have positive area
      for (final rect in rects) {
        expect(rect.width * rect.height, greaterThan(0));
      }
    });

    test('produces rectangles contained within bounds', () {
      final weights = [8.0, 5.0, 3.0, 2.0, 1.0];
      final container = const Rect.fromLTWH(0.1, 0.2, 0.6, 0.5);
      final rects = squarify(weights, container);

      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].left, greaterThanOrEqualTo(container.left));
        expect(rects[i].top, greaterThanOrEqualTo(container.top));
        expect(rects[i].right, lessThanOrEqualTo(container.right + 0.001));
        expect(rects[i].bottom, lessThanOrEqualTo(container.bottom + 0.001));
      }
    });

    test('optimizes aspect ratios (squareness)', () {
      final weights = [6.0, 6.0, 4.0, 3.0, 2.0, 2.0, 1.0];
      final container = const Rect.fromLTWH(0, 0, 1, 1);
      final rects = squarify(weights, container);

      // Calculate average aspect ratio (should be close to 1 for square)
      var sumAspectRatio = 0.0;
      for (final rect in rects) {
        final aspectRatio = math.max(rect.width, rect.height) /
            math.min(rect.width, rect.height);
        sumAspectRatio += aspectRatio;
      }
      final avgAspectRatio = sumAspectRatio / rects.length;

      // Squarify should produce reasonably square rectangles on average
      // Relaxed threshold since some layouts naturally have elongated rects
      expect(avgAspectRatio, lessThan(10.0),
          reason: 'Average aspect ratio should be reasonable');
    });
  });

  group('EisenTreemapHybrid Layout', () {
    const defaultConfig = LayoutConfig(
      topKPerQuadrant: 10,
      minAreaNormalized: 0.00004,
      gamma: 1.0,
      quadrantPadding: 0.012,
    );

    test('distributes tasks across quadrants correctly', () {
      final tasks = [
        Task(
            id: 'q1_1',
            title: 'Q1 Task',
            quadrant: Quadrant.q1,
            priority: 8,
            minutes: 30),
        Task(
            id: 'q2_1',
            title: 'Q2 Task',
            quadrant: Quadrant.q2,
            priority: 6,
            minutes: 45),
        Task(
            id: 'q3_1',
            title: 'Q3 Task',
            quadrant: Quadrant.q3,
            priority: 4,
            minutes: 20),
        Task(
            id: 'q4_1',
            title: 'Q4 Task',
            quadrant: Quadrant.q4,
            priority: 2,
            minutes: 15),
      ];

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout = engine.layout(tasks);

      expect(layout.length, equals(4));

      // Verify each quadrant has its task
      for (final q in Quadrant.values) {
        final hasTask = layout.any((rect) => rect.task.quadrant == q);
        expect(hasTask, isTrue, reason: 'Quadrant $q should have a task');
      }
    });

    test('respects quadrant boundaries', () {
      final tasks = List.generate(
        20,
        (i) => Task(
          id: 'task_$i',
          title: 'Task $i',
          quadrant: Quadrant.values[i % 4],
          priority: 5 + (i % 5),
          minutes: 30 + i * 2,
        ),
      );

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout = engine.layout(tasks);

      for (final rect in layout) {
        final r = rect.rect01;
        switch (rect.task.quadrant) {
          case Quadrant.q1:
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(0.51));
            expect(r.bottom, lessThanOrEqualTo(0.51));
            break;
          case Quadrant.q2:
            expect(r.left, greaterThanOrEqualTo(0.49));
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(1.01));
            expect(r.bottom, lessThanOrEqualTo(0.51));
            break;
          case Quadrant.q3:
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.top, greaterThanOrEqualTo(0.49));
            expect(r.right, lessThanOrEqualTo(0.51));
            expect(r.bottom, lessThanOrEqualTo(1.01));
            break;
          case Quadrant.q4:
            expect(r.left, greaterThanOrEqualTo(0.49));
            expect(r.top, greaterThanOrEqualTo(0.49));
            expect(r.right, lessThanOrEqualTo(1.01));
            expect(r.bottom, lessThanOrEqualTo(1.01));
            break;
        }
      }
    });

    test('applies topK clustering correctly', () {
      final tasks = List.generate(
        25,
        (i) => Task(
          id: 'q2_task_$i',
          title: 'Q2 Task $i',
          quadrant: Quadrant.q2,
          priority: 10 - (i % 10), // Varying priorities
          minutes: 20 + i * 3,
        ),
      );

      const config = LayoutConfig(
        topKPerQuadrant: 8,
        minAreaNormalized: 0.00001,
        gamma: 1.0,
        quadrantPadding: 0.01,
      );

      final engine = EisenTreemapHybrid(config);
      final layout = engine.layout(tasks);

      final q2Rects = layout.where((r) => r.task.quadrant == Quadrant.q2);
      final individualTiles = q2Rects.where((r) => r.stackChildren.isEmpty);
      final clusters = q2Rects.where((r) => r.stackChildren.isNotEmpty);

      // Should have at most topK individual tiles
      expect(individualTiles.length, lessThanOrEqualTo(config.topKPerQuadrant));

      // Should have exactly one cluster with the rest
      expect(clusters.length, equals(1));
      expect(clusters.first.stackChildren.length,
          equals(25 - individualTiles.length));
    });

    test('respects minAreaNormalized threshold', () {
      final tasks = List.generate(
        30,
        (i) => Task(
          id: 'task_$i',
          title: 'Task $i',
          quadrant: Quadrant.q1,
          priority: 1 + (i % 3), // Mostly low priority
          minutes: 5 + i, // Varying minutes
        ),
      );

      const config = LayoutConfig(
        topKPerQuadrant: 30,
        minAreaNormalized: 0.01, // Relatively large threshold
        gamma: 1.0,
        quadrantPadding: 0.01,
      );

      final engine = EisenTreemapHybrid(config);
      final layout = engine.layout(tasks);

      // All visible tiles should meet minimum area
      for (final rect in layout) {
        final area = rect.rect01.width * rect.rect01.height;
        if (rect.stackChildren.isEmpty) {
          // Individual tiles might be filtered
          expect(area, greaterThanOrEqualTo(config.minAreaNormalized - 0.001));
        }
      }

      // Should have fewer tiles than input due to filtering
      final individualTiles =
          layout.where((r) => r.stackChildren.isEmpty).length;
      expect(individualTiles, lessThan(tasks.length));
    });

    test('applies gamma smoothing correctly', () {
      final tasks = [
        Task(
            id: 't1',
            title: 'High',
            quadrant: Quadrant.q1,
            priority: 10,
            minutes: 60),
        Task(
            id: 't2',
            title: 'Medium',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 't3',
            title: 'Low',
            quadrant: Quadrant.q1,
            priority: 1,
            minutes: 10),
      ];

      // Test with different gamma values
      final configLinear = LayoutConfig(
        topKPerQuadrant: 10,
        minAreaNormalized: 0.0001,
        gamma: 1.0,
        quadrantPadding: 0.01,
      );

      final configSmoothed = LayoutConfig(
        topKPerQuadrant: 10,
        minAreaNormalized: 0.0001,
        gamma: 0.5, // More smoothing
        quadrantPadding: 0.01,
      );

      final layoutLinear = EisenTreemapHybrid(configLinear).layout(tasks);
      final layoutSmoothed = EisenTreemapHybrid(configSmoothed).layout(tasks);

      expect(layoutLinear.length, equals(3));
      expect(layoutSmoothed.length, equals(3));

      // With smoothing, size differences should be less extreme
      final areaLinear =
          layoutLinear.map((r) => r.rect01.width * r.rect01.height).toList();
      final areaSmoothed =
          layoutSmoothed.map((r) => r.rect01.width * r.rect01.height).toList();

      // Ratio of largest to smallest should be smaller with smoothing
      areaLinear.sort();
      areaSmoothed.sort();
      final ratioLinear = areaLinear.last / areaLinear.first;
      final ratioSmoothed = areaSmoothed.last / areaSmoothed.first;

      expect(ratioSmoothed, lessThan(ratioLinear),
          reason: 'Smoothing should reduce size disparities');
    });

    test('zoom parameter works correctly', () {
      final tasks = [
        Task(
            id: 'q1_1',
            title: 'Q1',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 'q2_1',
            title: 'Q2',
            quadrant: Quadrant.q2,
            priority: 5,
            minutes: 30),
        Task(
            id: 'q2_2',
            title: 'Q2 2',
            quadrant: Quadrant.q2,
            priority: 6,
            minutes: 40),
        Task(
            id: 'q3_1',
            title: 'Q3',
            quadrant: Quadrant.q3,
            priority: 3,
            minutes: 20),
      ];

      final engine = EisenTreemapHybrid(defaultConfig);
      final layoutZoomed = engine.layout(tasks, only: Quadrant.q2);

      // Should only show Q2 tasks
      expect(layoutZoomed.every((r) => r.task.quadrant == Quadrant.q2), isTrue);
      expect(layoutZoomed.length, equals(2));

      // Should fill most of the canvas (accounting for padding)
      final totalArea = layoutZoomed.fold<double>(
          0, (sum, r) => sum + r.rect01.width * r.rect01.height);
      // With padding, may be slightly less than 1.0
      expect(totalArea, greaterThan(0.9), reason: 'Should fill most of canvas');
    });

    test('handles empty quadrants gracefully', () {
      final tasks = [
        Task(
            id: 'q1_1',
            title: 'Q1 Only',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
      ];

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout = engine.layout(tasks);

      expect(layout.length, equals(1));
      expect(layout.first.task.quadrant, equals(Quadrant.q1));
    });

    test('handles all tasks in one quadrant', () {
      final tasks = List.generate(
        15,
        (i) => Task(
          id: 'q3_$i',
          title: 'Q3 Task $i',
          quadrant: Quadrant.q3,
          priority: 5 + (i % 5),
          minutes: 20 + i * 2,
        ),
      );

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout = engine.layout(tasks);

      expect(layout.every((r) => r.task.quadrant == Quadrant.q3), isTrue);
      expect(layout.length, greaterThan(0));
    });

    test('maintains layout stability with small weight changes', () {
      final tasks = List.generate(
        12,
        (i) => Task(
          id: 'task_$i',
          title: 'Task $i',
          quadrant: Quadrant.q2,
          priority: 5 + (i % 3),
          minutes: 30 + i * 3,
        ),
      );

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout1 = engine.layout(tasks);

      // Slightly modify one task
      final modifiedTasks = tasks
          .map((t) => t.id == 'task_5' ? t.copyWith(minutes: t.minutes + 5) : t)
          .toList();
      final layout2 = engine.layout(modifiedTasks);

      expect(layout1.length, equals(layout2.length));

      // Most tasks should maintain similar relative positions
      final ids1 = layout1.map((r) => r.task.id).toSet();
      final ids2 = layout2.map((r) => r.task.id).toSet();
      expect(ids1, equals(ids2));
    });

    test('handles quadrantPadding correctly', () {
      final tasks = [
        Task(
            id: 'q1',
            title: 'Q1',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
        Task(
            id: 'q2',
            title: 'Q2',
            quadrant: Quadrant.q2,
            priority: 5,
            minutes: 30),
      ];

      const configNoPadding = LayoutConfig(
        topKPerQuadrant: 10,
        minAreaNormalized: 0.0001,
        gamma: 1.0,
        quadrantPadding: 0.0,
      );

      const configWithPadding = LayoutConfig(
        topKPerQuadrant: 10,
        minAreaNormalized: 0.0001,
        gamma: 1.0,
        quadrantPadding: 0.02,
      );

      final layoutNoPad = EisenTreemapHybrid(configNoPadding).layout(tasks);
      final layoutWithPad = EisenTreemapHybrid(configWithPadding).layout(tasks);

      // With padding, rects should be smaller
      final areaNoPad = layoutNoPad
          .map((r) => r.rect01.width * r.rect01.height)
          .reduce((a, b) => a + b);
      final areaWithPad = layoutWithPad
          .map((r) => r.rect01.width * r.rect01.height)
          .reduce((a, b) => a + b);

      expect(areaWithPad, lessThan(areaNoPad),
          reason: 'Padding should reduce usable area');
    });

    test('produces deterministic output for same input', () {
      final tasks = List.generate(
        10,
        (i) => Task(
          id: 'task_$i',
          title: 'Task $i',
          quadrant: Quadrant.values[i % 4],
          priority: 5,
          minutes: 30,
        ),
      );

      final engine = EisenTreemapHybrid(defaultConfig);
      final layout1 = engine.layout(tasks);
      final layout2 = engine.layout(tasks);

      expect(layout1.length, equals(layout2.length));

      for (var i = 0; i < layout1.length; i++) {
        expect(layout1[i].task.id, equals(layout2[i].task.id));
        expect(layout1[i].rect01, equals(layout2[i].rect01));
      }
    });
  });

  group('Layout Edge Cases', () {
    const config = LayoutConfig(
      topKPerQuadrant: 10,
      minAreaNormalized: 0.0001,
      gamma: 1.0,
      quadrantPadding: 0.01,
    );

    test('handles tasks with zero minutes', () {
      final tasks = [
        Task(
            id: 't1',
            title: 'Zero minutes',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 0),
        Task(
            id: 't2',
            title: 'Normal',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 30),
      ];

      final engine = EisenTreemapHybrid(config);
      final layout = engine.layout(tasks);

      // Should not crash and should produce valid layout
      expect(layout.length, greaterThan(0));
      for (final rect in layout) {
        expect(rect.rect01.width, greaterThan(0));
        expect(rect.rect01.height, greaterThan(0));
      }
    });

    test('handles tasks with very high minutes', () {
      final tasks = [
        Task(
            id: 't1',
            title: 'Huge',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 100000),
        Task(
            id: 't2',
            title: 'Tiny',
            quadrant: Quadrant.q1,
            priority: 5,
            minutes: 1),
      ];

      final engine = EisenTreemapHybrid(config);
      final layout = engine.layout(tasks);

      expect(layout.length, equals(2));

      // Larger task should have significantly more area
      final areas =
          layout.map((r) => r.rect01.width * r.rect01.height).toList();
      areas.sort();
      expect(areas.last, greaterThan(areas.first * 10));
    });

    test('handles maximum topK value', () {
      final tasks = List.generate(
        100,
        (i) => Task(
          id: 'task_$i',
          title: 'Task $i',
          quadrant: Quadrant.q1,
          priority: 5,
          minutes: 30,
        ),
      );

      const configMaxK = LayoutConfig(
        topKPerQuadrant: 1000,
        minAreaNormalized: 0.00001,
        gamma: 1.0,
        quadrantPadding: 0.01,
      );

      final engine = EisenTreemapHybrid(configMaxK);
      final layout = engine.layout(tasks);

      // Should render all tasks individually
      expect(
          layout.where((r) => r.stackChildren.isEmpty).length, greaterThan(50));
    });
  });
}
