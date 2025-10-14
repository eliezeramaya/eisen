import 'package:eisen/features/matrix/domain/entities.dart';
import 'package:eisen/features/matrix/domain/treemap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computeSquarifiedLayout returns normalized rects', () {
    final tasks = [
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 5, minutes: 30),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q1, priority: 8, minutes: 20),
      Task(id: 'c', title: 'C', quadrant: Quadrant.q2, priority: 3, minutes: 60),
    ];
    final layout = computeSquarifiedLayout(tasks);
    expect(layout.length, 3);
    for (final tr in layout) {
      expect(tr.rect01.left >= 0 && tr.rect01.top >= 0, isTrue);
      expect(tr.rect01.right <= 1.0001 && tr.rect01.bottom <= 1.0001, isTrue);
    }
  });

  test('zoom to quadrant fills entire area', () {
    final tasks = [
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 5, minutes: 30),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q2, priority: 8, minutes: 20),
    ];
    final layout = computeSquarifiedLayout(tasks, zoom: Quadrant.q1);
    expect(layout.every((t) => t.task.quadrant == Quadrant.q1), isTrue);
    // Sum of areas approximately equals 1.0
    final area = layout.fold<double>(0, (a, r) => a + r.rect01.width * r.rect01.height);
    expect(area, closeTo(1.0, 0.0001));
  });
}
