import 'package:flutter/material.dart';

/// Debug overlay helpers for the treemap. Lightweight and pure static.
/// Use together with `debugTreemap` flag from domain layer.
class TreemapDebugOverlay {
  TreemapDebugOverlay._();

  static void drawQuadrantBounds(Canvas c, Rect quad) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blueAccent.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    c.drawRect(quad.deflate(0.5), paint);
  }

  static void drawShelf(Canvas c, Rect shelfBounds) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withValues(alpha: 0.08);
    c.drawRect(shelfBounds, paint);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.blue.withValues(alpha: 0.25);
    c.drawRect(shelfBounds.deflate(0.5), border);
  }

  static void labelTile(
    Canvas c,
    Rect r,
    String id,
    double area,
    double ratio,
  ) {
    final short = id.length <= 6 ? id : id.substring(id.length - 6);
    final text =
        '$short  ${area.toStringAsFixed(3)}  r=${ratio.toStringAsFixed(2)}';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: r.width - 4);
    final bg = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.yellow.withValues(alpha: 0.75);
    final pad = const EdgeInsets.symmetric(horizontal: 2, vertical: 1);
    final rect = Rect.fromLTWH(
      r.left + 2,
      r.top + 2,
      tp.width + pad.horizontal,
      tp.height + pad.vertical,
    );
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), bg);
    tp.paint(c, Offset(rect.left + pad.left, rect.top + pad.top));
  }
}
