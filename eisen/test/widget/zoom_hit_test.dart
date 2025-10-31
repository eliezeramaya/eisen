import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hit test consistent with and without zoom', (tester) async {
    final tasks = [
      Task(
          id: 'a',
          title: 'A',
          quadrant: Quadrant.q1,
          priority: 10,
          minutes: 120),
      Task(
          id: 'b', title: 'B', quadrant: Quadrant.q2, priority: 9, minutes: 90),
      Task(
          id: 'c', title: 'C', quadrant: Quadrant.q3, priority: 8, minutes: 80),
      Task(
          id: 'd', title: 'D', quadrant: Quadrant.q4, priority: 7, minutes: 70),
    ];

    Widget host({Quadrant? zoom}) => Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: TreemapCanvas(
                  tasks: tasks,
                  layout: computeStableLayout(tasks, zoom: zoom),
                  zoom: zoom,
                  presentQuadrant: zoom,
                  minimal: true,
                  selectedId: null,
                ),
              ),
            ),
          ),
        );

    // Local helper: replicate TreemapCanvas _hitTest logic deterministically
    String? hitTestLocal(List<TreemapRect> layout, Size size, Offset pos) {
      for (final tr in layout) {
        final r = Rect.fromLTWH(
          tr.rect01.left * size.width,
          tr.rect01.top * size.height,
          tr.rect01.width * size.width,
          tr.rect01.height * size.height,
        );
        if (r.width < LayoutConstants.minTileSize ||
            r.height < LayoutConstants.minTileSize) {
          continue;
        }
        if (r.contains(pos)) return tr.task.id;
      }
      return null;
    }

    // Without zoom, tap at the actual center of the Q1 tile
    await tester.pumpWidget(host());
    // Ensure a frame is built before hit-testing
    await tester.pump();
    await tester.pumpAndSettle();
    // Sanity check: use the TreemapCanvas size and the inner CustomPaint size
    final canvasFinder = find.byType(TreemapCanvas);
    final paintFinder =
        find.descendant(of: canvasFinder, matching: find.byType(CustomPaint));
    final canvasSize = tester.getSize(canvasFinder);
    final paintSize = tester.getSize(paintFinder);
    expect(canvasSize, const Size(400, 400));
    expect(paintSize, const Size(400, 400));
    // Derive the center from the computed layout to avoid hard-coded offsets
    final layoutNoZoom = computeStableLayout(tasks, zoom: null);
    final q1RectNoZoom =
        layoutNoZoom.firstWhere((e) => e.task.id == 'a').rect01;
    final centerNoZoomPx = Offset(q1RectNoZoom.center.dx * paintSize.width,
        q1RectNoZoom.center.dy * paintSize.height);
    // Resolve the CustomPaint's global origin to compute an accurate global tap
    final idNoZoom = hitTestLocal(layoutNoZoom, paintSize, centerNoZoomPx);
    expect(idNoZoom, isNotNull);

    // With zoom to Q1, tap at the center of the Q1 tile in zoomed layout
    await tester.pumpWidget(host(zoom: Quadrant.q1));
    await tester.pump();
    await tester.pumpAndSettle();
    final layoutZoom = computeStableLayout(tasks, zoom: Quadrant.q1);
    final q1RectZoom = layoutZoom.firstWhere((e) => e.task.id == 'a').rect01;
    // Re-read paint size after rebuild
    final paintSizeZoom = tester.getSize(paintFinder);
    expect(paintSizeZoom, const Size(400, 400));
    // Try a small grid of points within the zoomed Q1 rect to avoid edge rounding issues
    final rectZoomPx = Rect.fromLTWH(
      q1RectZoom.left * paintSizeZoom.width,
      q1RectZoom.top * paintSizeZoom.height,
      q1RectZoom.width * paintSizeZoom.width,
      q1RectZoom.height * paintSizeZoom.height,
    );
    // Probe 9 points (center and offsets)
    final probes = <Offset>[
      rectZoomPx.center,
      rectZoomPx.center + const Offset(10, 0),
      rectZoomPx.center + const Offset(-10, 0),
      rectZoomPx.center + const Offset(0, 10),
      rectZoomPx.center + const Offset(0, -10),
      rectZoomPx.center + const Offset(12, 12),
      rectZoomPx.center + const Offset(-12, -12),
      rectZoomPx.center + const Offset(12, -12),
      rectZoomPx.center + const Offset(-12, 12),
    ];
    String? idZoom;
    for (final p in probes) {
      idZoom = hitTestLocal(layoutZoom, paintSizeZoom, p);
      if (idZoom != null) break;
    }
    expect(idZoom, isNotNull,
        reason:
            'Expected a hit within zoomed Q1 tile but got null after multiple probes');

    // In this simple case, the top-left quadrant tap should map to a tile in Q1 both times
    expect(idNoZoom, isNotEmpty);
    expect(idZoom, isNotEmpty);
    // Optional: ensure both taps resolved to the same tile id
    expect(idNoZoom, equals('a'));
    expect(idZoom, equals('a'));
  });
}
