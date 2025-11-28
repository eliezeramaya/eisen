import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:eisen/features/calendar_gantt/presentation/widgets/dependency_arrows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDependencyArrows', () {
    test('builds arrows using span rectangles', () {
      final dependencies = [
        const TaskDependency(prerequisiteId: 'a', dependentId: 'b'),
      ];

      final rects = <String, Rect>{
        'a': const Rect.fromLTWH(10, 20, 30, 10),
        'b': const Rect.fromLTWH(80, 40, 20, 10),
      };

      final arrows =
          computeDependencyArrows(dependencies: dependencies, spanRects: rects);

      expect(arrows, hasLength(1));
      final arrow = arrows.first;
      expect(arrow.fromTaskId, 'a');
      expect(arrow.toTaskId, 'b');
      expect(arrow.dependencyType, DependencyType.finishToStart);
      expect(arrow.startPoint, const Offset(40, 25));
      expect(arrow.endPoint, const Offset(80, 45));
    });

    test('skips dependencies when spans are missing', () {
      final dependencies = [
        const TaskDependency(prerequisiteId: 'a', dependentId: 'b'),
        const TaskDependency(prerequisiteId: 'c', dependentId: 'd'),
      ];

      final rects = <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 20, 10),
        // Missing b
        'c': const Rect.fromLTWH(40, 0, 20, 10),
        'd': const Rect.fromLTWH(80, 0, 20, 10),
      };

      final arrows =
          computeDependencyArrows(dependencies: dependencies, spanRects: rects);

      expect(arrows, hasLength(1));
      expect(arrows.first.fromTaskId, 'c');
      expect(arrows.first.toTaskId, 'd');
    });
  });
}
