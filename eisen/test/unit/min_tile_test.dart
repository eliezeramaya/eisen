import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  test('tiles smaller than 44x44 become stack tiles', () {
    final tasks = <Task>[];
    // One big + many tiny tasks in Q1
    tasks.add(Task(id: 'big', title: 'Big', quadrant: Quadrant.q1, priority: 10, minutes: 240));
    for (var i = 0; i < 20; i++) {
      tasks.add(Task(id: 't$i', title: 't$i', quadrant: Quadrant.q1, priority: 1, minutes: 5));
    }
    // Assume a medium viewport so that 44x44 threshold matters
    // Translate 44x44 px to normalized area with a 600x600 viewport
    final viewportW = 600.0, viewportH = 600.0;
    final minPx = 44.0 * 44.0;
    final minArea01 = minPx / (viewportW * viewportH);

    final layout = computeStableLayout(tasks, zoom: Quadrant.q1, minTileArea01: minArea01);
    // Expect exactly one stack tile in Q1
    final stacks = layout.where((e) => e.task.quadrant == Quadrant.q1 && e.stackChildren.isNotEmpty).toList();
    expect(stacks.length, 1);
    expect(stacks.first.stackChildren.length, greaterThanOrEqualTo(1));
    // Non-stack tiles should be interactive-size or larger
    final nonStacks = layout.where((e) => e.stackChildren.isEmpty).toList();
    expect(nonStacks.any((e) => e.rect01.width * e.rect01.height < minArea01), isFalse);
  });
}

