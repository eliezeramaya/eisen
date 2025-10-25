import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

void main() {
  group('Drag & Drop and Stack overlays', () {
    testWidgets('Dragging a tile into another quadrant triggers drop callback', (tester) async {
      final tasks = [
        Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 10, minutes: 120),
        Task(id: 'b', title: 'B', quadrant: Quadrant.q2, priority: 9, minutes: 90),
        Task(id: 'c', title: 'C', quadrant: Quadrant.q3, priority: 8, minutes: 80),
        Task(id: 'd', title: 'D', quadrant: Quadrant.q4, priority: 7, minutes: 70),
      ];

  String? droppedId;
  Quadrant? droppedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: TreemapCanvas(
                tasks: tasks,
                layout: computeStableLayout(tasks),
                onDropToQuadrant: (id, q) {
                  droppedId = id;
                  droppedTo = q;
                },
                minimal: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

  // Locate the start zone (Q1) and destination zone (Q2)
  final zoneQ1 = find.byKey(const ValueKey('quadrant_q1_dropzone'));
  final zoneQ2 = find.byKey(const ValueKey('quadrant_q2_dropzone'));

  expect(zoneQ1, findsOneWidget);
      expect(zoneQ2, findsOneWidget);

  final tileCenter = tester.getCenter(zoneQ1);
      final zoneCenter = tester.getCenter(zoneQ2);

      // Sanity: local hit-test at start point should resolve to 'a'
      String? hitTestLocal(List<TreemapRect> layout, Size size, Offset pos) {
        for (final tr in layout) {
          final r = Rect.fromLTWH(
            tr.rect01.left * size.width,
            tr.rect01.top * size.height,
            tr.rect01.width * size.width,
            tr.rect01.height * size.height,
          );
          if (r.contains(pos)) return tr.task.id;
        }
        return null;
      }
    final layout = computeStableLayout(tasks);
    // Validate quadrant mapping assumptions
    final rectA = layout.firstWhere((e) => e.task.id == 'a').rect01;
    final rectB = layout.firstWhere((e) => e.task.id == 'b').rect01;
    expect(rectA.center.dx, lessThan(0.5));
    expect(rectA.center.dy, lessThan(0.5));
    expect(rectB.center.dx, greaterThan(0.5));
    expect(rectB.center.dy, lessThan(0.5));
    // We expect the start point to lie within some tile in Q1
    expect(hitTestLocal(layout, const Size(400, 400), tileCenter.translate(-
      (tester.getTopLeft(find.byType(TreemapCanvas)).dx), -
      (tester.getTopLeft(find.byType(TreemapCanvas)).dy))), isNotNull);

      final gesture = await tester.startGesture(tileCenter);
      await tester.pump();
      await gesture.moveTo(zoneCenter);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

  expect(droppedId, isNotNull);
      expect(droppedTo, Quadrant.q2);
    });

    testWidgets('Stack overlay shows for tiny tiles and opens sheet on tap', (tester) async {
      // Many tiny tasks in Q1 to force +N overlay
      final tasks = <Task>[];
      for (int i = 0; i < 15; i++) {
        tasks.add(Task(id: 't$i', title: 'T$i', quadrant: Quadrant.q1, priority: 1, minutes: 1));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: TreemapCanvas(
                tasks: tasks,
                layout: computeStableLayout(tasks),
                minimal: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stackQ1 = find.byKey(const ValueKey('stack_q1'));
      expect(stackQ1, findsOneWidget);

      await tester.tap(stackQ1);
      await tester.pumpAndSettle();

      // Bottom sheet should open with a list of tasks
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
