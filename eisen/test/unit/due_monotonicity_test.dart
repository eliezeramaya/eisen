import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  test('weight is monotonic with due proximity (earlier due => >= weight)', () {
    final base = Task(id: 'a', title: 'A', quadrant: Quadrant.q2, priority: 5, minutes: 60);
    final now = DateTime.now();
    final in3d = base.copyWith(due: now.add(const Duration(days: 3)));
    final in1d = base.copyWith(due: now.add(const Duration(days: 1)));
    expect(weight(in1d) >= weight(in3d), isTrue);
  });

  test('relative area does not decrease when due is closer', () {
    final now = DateTime.now();
    final t1_far = Task(id: 't1', title: 'T1', quadrant: Quadrant.q2, priority: 5, minutes: 60, due: now.add(const Duration(days: 3)));
    final t1_near = t1_far.copyWith(due: now.add(const Duration(days: 1)));
    final others = [
      Task(id: 't2', title: 'T2', quadrant: Quadrant.q2, priority: 5, minutes: 60),
      Task(id: 't3', title: 'T3', quadrant: Quadrant.q2, priority: 5, minutes: 60),
    ];

    final cache = LayoutCache();
    final layoutFar = computeStableLayout([t1_far, ...others], zoom: Quadrant.q2, cache: cache);
  final farSize = layoutFar.firstWhere((e) => e.task.id == 't1').rect01.size;
  final areaFar = farSize.width * farSize.height;
    final layoutNear = computeStableLayout([t1_near, ...others], zoom: Quadrant.q2, cache: cache);
  final nearSize = layoutNear.firstWhere((e) => e.task.id == 't1').rect01.size;
  final areaNear = nearSize.width * nearSize.height;
    expect(areaNear >= areaFar, isTrue);
  });
}

