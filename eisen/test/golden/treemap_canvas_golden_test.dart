import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';

Future<ui.Image> _capture(WidgetTester tester, Key key) async {
  final boundary = tester.firstWidget<RepaintBoundary>(find.byKey(key));
  return await boundary.toImage(pixelRatio: 1.0);
}

int _diffPixels(ui.Image a, ui.Image b) {
  final w = a.width;
  final h = a.height;
  assert(w == b.width && h == b.height);
  int diffs = 0;
  // Warning: This reads image bytes synchronously; fine for small sizes
  // Use RGBA
  // ignore: deprecated_member_use
  final ba = a.toByteData(format: ui.ImageByteFormat.rawRgba)!;
  // ignore: deprecated_member_use
  final bb = b.toByteData(format: ui.ImageByteFormat.rawRgba)!;
  final da = ba.buffer.asUint8List();
  final db = bb.buffer.asUint8List();
  for (int i = 0; i < da.length; i += 4) {
    if (da[i] != db[i] || da[i + 1] != db[i + 1] || da[i + 2] != db[i + 2]) {
      diffs++;
    }
  }
  return diffs;
}

void main() {
  testWidgets('treemap canvas small change has minimal pixel delta', (tester) async {
    final tasks = <Task>[
      Task(id: 'a', title: 'A', quadrant: Quadrant.q1, priority: 6, minutes: 60),
      Task(id: 'b', title: 'B', quadrant: Quadrant.q1, priority: 5, minutes: 45),
      Task(id: 'c', title: 'C', quadrant: Quadrant.q2, priority: 4, minutes: 30),
      Task(id: 'd', title: 'D', quadrant: Quadrant.q3, priority: 7, minutes: 90),
    ];
    final cache = LayoutCache();
    final layout1 = computeStableLayout(tasks, cache: cache);

    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 300,
              height: 220,
              child: TreemapCanvas(tasks: tasks, layout: layout1, minimal: true),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final img1 = await _capture(tester, key);

    // Apply a small change
    final tasks2 = tasks.map((t) => t.id == 'b' ? t.copyWith(minutes: t.minutes + 5) : t).toList();
    final layout2 = computeStableLayout(tasks2, cache: cache);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 300,
              height: 220,
              child: TreemapCanvas(tasks: tasks2, layout: layout2, minimal: true),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final img2 = await _capture(tester, key);

    final diffs = _diffPixels(img1, img2);
    // On a 300x220 canvas ~ 66000 pixels. Allow small delta threshold.
    expect(diffs < 2000, isTrue);
  });
}

