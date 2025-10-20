import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Offset _centerPx(Rect r01, Size size) => Offset(
      r01.left * size.width + r01.width * size.width / 2,
      r01.top * size.height + r01.height * size.height / 2,
    );

void main() {
  testWidgets('tiles < 44x44 are not clickable and are stacked', (tester) async {
    final tasks = [
      Task(id: 'big1', title: 'Big 1', quadrant: Quadrant.q1, priority: 10, minutes: 240),
      Task(id: 'big2', title: 'Big 2', quadrant: Quadrant.q1, priority: 9, minutes: 180),
      Task(id: 'tiny', title: 'Tiny', quadrant: Quadrant.q1, priority: 1, minutes: 5),
    ];
    final layout = computeStableLayout(tasks, zoom: Quadrant.q1, cache: LayoutCache());

    String? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          height: 220,
          child: TreemapCanvas(
            tasks: tasks,
            layout: layout,
            onTap: (id) => tapped = id,
            minimal: false,
          ),
        ),
      ),
    ));

    final size = const Size(220, 220);
    final tinyRect01 = layout.firstWhere((e) => e.task.id == 'tiny').rect01;
    final bigRect01 = layout.firstWhere((e) => e.task.id == 'big1').rect01;

    // Tap inside tiny tile -> should be treated as stacked => onTap gets null
    await tester.tapAt(_centerPx(tinyRect01, size));
    await tester.pump();
    expect(tapped, isNull);

    // Tap inside big tile -> should return id
    await tester.tapAt(_centerPx(bigRect01, size));
    await tester.pump();
    expect(tapped, equals('big1'));
  });
}

