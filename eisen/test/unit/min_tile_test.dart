import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/compute_layout_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';

void main() {
  test('tiles smaller than 44x44 are stacked into +N', () {
    // Create many small-equal tasks in Q1 so each individual tile would be < 44x44 px
    final tasks = <Task>[];
    for (int i = 0; i < 80; i++) {
      tasks.add(Task(id: 's$i', title: 's$i', quadrant: Quadrant.q1, priority: 1, minutes: 5));
    }
    // Add a couple tasks in other quadrants to avoid empty edges
    tasks.addAll([
      Task(id: 'b1', title: 'b1', quadrant: Quadrant.q2, priority: 8, minutes: 60),
      Task(id: 'b2', title: 'b2', quadrant: Quadrant.q3, priority: 6, minutes: 45),
    ]);

    final cache = LayoutCache();
    final bandit = BanditService();
    final usecase = ComputeLayoutUseCase(cache: cache, bandit: bandit);

    // Use a fixed viewport so min area threshold is deterministic
    const viewport = Size(800, 600); // total px = 480k; min area = 1936 px
    final layout = usecase.execute(tasks: tasks, zoom: null, viewport: viewport);

    // Find stack tile in Q1 and ensure it groups the tiny tasks
    final stack = layout.where((e) => e.task.quadrant == Quadrant.q1 && e.stackChildren.isNotEmpty).toList();
    expect(stack.length, 1, reason: 'Expected a single +N tile for small tasks');
    expect(stack.first.stackChildren.length, 80);

    // Ensure no other tile in Q1 is smaller than 44x44 in pixels
    final others = layout.where((e) => e.task.quadrant == Quadrant.q1 && e.stackChildren.isEmpty).toList();
    for (final tr in others) {
      final w = tr.rect01.width * viewport.width;
      final h = tr.rect01.height * viewport.height;
      expect(w >= 44 || h >= 44, isTrue, reason: 'Non-stacked tile too small in one dimension');
      expect(w * h >= 44 * 44, isTrue, reason: 'Non-stacked tile area too small');
    }
  });
}

