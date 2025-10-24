import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/compute_layout_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';

void main() {
  test('incremental recompute keeps unaffected quadrants identical', () {
    final cache = LayoutCache();
    final bandit = BanditService();
    final usecase = ComputeLayoutUseCase(cache: cache, bandit: bandit);
    const viewport = Size(800, 600);

    // Base tasks across quadrants
    var tasks = <Task>[
      Task(id: 'q1_a', title: 'A', quadrant: Quadrant.q1, priority: 8, minutes: 60),
      Task(id: 'q1_b', title: 'B', quadrant: Quadrant.q1, priority: 6, minutes: 45),
      Task(id: 'q2_a', title: 'A', quadrant: Quadrant.q2, priority: 9, minutes: 80),
      Task(id: 'q3_a', title: 'A', quadrant: Quadrant.q3, priority: 5, minutes: 50),
      Task(id: 'q4_a', title: 'A', quadrant: Quadrant.q4, priority: 4, minutes: 40),
    ];

    final first = usecase.execute(tasks: tasks, viewport: viewport);
    // Capture a rect from Q2 to verify it stays identical
    final q2RectBefore = first.firstWhere((e) => e.task.id == 'q2_a').rect01;

    // Change a task only in Q1 and mark only Q1 dirty
    tasks = tasks.map((t) => t.id == 'q1_a' ? t.copyWith(minutes: 200) : t).toList();
    final second = usecase.execute(tasks: tasks, viewport: viewport, only: Quadrant.q1);

    final q2RectAfter = second.firstWhere((e) => e.task.id == 'q2_a').rect01;

    expect(q2RectAfter, equals(q2RectBefore), reason: 'Unaffected quadrant layout should be reused as-is');
  });
}

