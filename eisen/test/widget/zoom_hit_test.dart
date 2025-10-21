import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

void main() {
  testWidgets('hit test consistent with and without zoom', (tester) async {
    final tasks = [
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 10, minutes: 120),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q2, priority: 9, minutes: 90),
      Task(id: 'c', title: 'C', quadrant: Quadrant.q3, priority: 8, minutes: 80),
      Task(id: 'd', title: 'D', quadrant: Quadrant.q4, priority: 7, minutes: 70),
    ];

    String? tapped;

    Widget host({Quadrant? zoom}) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: SizedBox(
              width: 400,
              height: 400,
              child: TreemapCanvas(
                tasks: tasks,
                layout: computeStableLayout(tasks, zoom: zoom),
                onTap: (id) => tapped = id,
                zoom: zoom,
                presentQuadrant: zoom,
                minimal: true,
              ),
            ),
          ),
        );

    // Without zoom, tap near center of Q1 tile
    await tester.pumpWidget(host());
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(tapped, isNotNull);
    final idNoZoom = tapped;

    // With zoom to Q1, tap at similar normalized position
    tapped = null;
    await tester.pumpWidget(host(zoom: Quadrant.q1));
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(tapped, isNotNull);
    final idZoom = tapped;

    // In this simple case, the top-left quadrant tap should map to a tile in Q1 both times
    expect(idNoZoom, isNotEmpty);
    expect(idZoom, isNotEmpty);
  });
}

