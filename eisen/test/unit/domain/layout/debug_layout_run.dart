import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug run computeStableLayout with demo tasks', () {
    final now = DateTime.now();
    final demo = [
      Task(id: 't1', title: 'Presentación', quadrant: Quadrant.q1, priority: 10, minutes: 120, due: now.add(const Duration(hours: 4)), createdAt: now.subtract(const Duration(days:1))),
      Task(id: 't2', title: 'Bug', quadrant: Quadrant.q1, priority: 10, minutes: 180, due: now.add(const Duration(hours:2)), createdAt: now.subtract(const Duration(hours:3))),
      Task(id: 't3', title: 'Plan', quadrant: Quadrant.q2, priority: 9, minutes: 240, due: now.add(const Duration(days:7)), createdAt: now.subtract(const Duration(days:5))),
      Task(id: 't4', title: 'Email', quadrant: Quadrant.q3, priority: 5, minutes: 45, createdAt: now.subtract(const Duration(hours:5))),
      Task(id: 't5', title: 'Social', quadrant: Quadrant.q4, priority: 2, minutes: 20, createdAt: now.subtract(const Duration(hours:6))),
    ];
    final layout = computeStableLayout(demo, minTileArea01: (44.0*44.0)/(600.0*600.0), cache: LayoutCache());
    if (kDebugMode) {
      debugPrint('Demo tasks: ${demo.length}, layout tiles: ${layout.length}');
    }
    expect(layout.isNotEmpty, isTrue);
  });
}
