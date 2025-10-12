import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities.dart';
import '../../domain/treemap_layout.dart';

class TreemapCanvas extends StatefulWidget {
  final List<Task> tasks;
  final List<TreemapRect> layout;
  final void Function(String? id)? onTap;
  final void Function(String id, Quadrant q)? onDropToQuadrant;
  final void Function(Quadrant q)? onDoubleTapQuadrant;
  final Quadrant? zoom;

  const TreemapCanvas({
    super.key,
    required this.tasks,
    required this.layout,
    this.onTap,
    this.onDropToQuadrant,
    this.onDoubleTapQuadrant,
    this.zoom,
  });

  @override
  State<TreemapCanvas> createState() => _TreemapCanvasState();
}

class _TreemapCanvasState extends State<TreemapCanvas> {
  String? _draggingId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final id = _hitTest(d.localPosition, context.size!);
        widget.onTap?.call(id);
      },
      onDoubleTapDown: (d) {
        final q = _quadrantAt(d.localPosition, context.size!);
        if (q != null) widget.onDoubleTapQuadrant?.call(q);
      },
      onPanStart: (d) {
        _draggingId = _hitTest(d.localPosition, context.size!);
      },
      onPanEnd: (d) {
        if (_draggingId != null && widget.zoom == null) {
          final q = _quadrantAt(_lastPos ?? Offset.zero, context.size!);
          if (q != null) widget.onDropToQuadrant?.call(_draggingId!, q);
        }
        _draggingId = null;
      },
      onPanUpdate: (d) => _lastPos = d.localPosition,
      child: CustomPaint(
        painter: _TreemapPainter(widget.layout),
        isComplex: true,
        willChange: true,
        child: const SizedBox.expand(),
      ),
    );
  }

  Offset? _lastPos;

  String? _hitTest(Offset pos, Size size) {
    for (final tr in widget.layout) {
      final r = _px(tr.rect01, size);
      if (r.contains(pos)) return tr.task.id;
    }
    return null;
  }

  Quadrant? _quadrantAt(Offset pos, Size size) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final left = pos.dx < halfW;
    final top = pos.dy < halfH;
    if (left && top) return Quadrant.q1;
    if (!left && top) return Quadrant.q2;
    if (left && !top) return Quadrant.q3;
    return Quadrant.q4;
  }

  Rect _px(Rect r01, Size size) => Rect.fromLTWH(r01.left * size.width, r01.top * size.height, r01.width * size.width, r01.height * size.height);
}

class _TreemapPainter extends CustomPainter {
  final List<TreemapRect> layout;
  _TreemapPainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final tr in layout) {
      final r = Rect.fromLTWH(tr.rect01.left * size.width, tr.rect01.top * size.height, tr.rect01.width * size.width, tr.rect01.height * size.height);
      final color = _byQuadrant(tr.task.quadrant);
      // Halo shadow
      canvas.drawShadow(Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(12))), color.withOpacity(0.3), 8, false);
      // Glass fill
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.06);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
      canvas.drawRRect(rr, paint);
      // Border
      paint
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 1;
      canvas.drawRRect(rr, paint);

      // Adaptive text
      final area = r.width * r.height;
      final showMeta = area > 12000;
      final tp = _textPainter(tr.task.title, r, 12, FontWeight.w600);
      tp.paint(canvas, Offset(r.left + 8, r.top + 6));
      if (showMeta) {
        final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
        final tp2 = _textPainter(meta, r, 11, FontWeight.w400);
        tp2.paint(canvas, Offset(r.left + 8, r.top + 6 + tp.height + 2));
      }

      // Quadrant color indicator
      paint
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.12);
      final ind = Rect.fromLTWH(r.right - 10, r.top + 4, 6, 6);
      canvas.drawRRect(RRect.fromRectAndRadius(ind, const Radius.circular(2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) => oldDelegate.layout != layout;

  Color _byQuadrant(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return const Color(0xFFEF476F);
      case Quadrant.q2:
        return const Color(0xFF06D6A0);
      case Quadrant.q3:
        return const Color(0xFFFFB300);
      case Quadrant.q4:
        return const Color(0xFF118AB2);
    }
  }

  TextPainter _textPainter(String text, Rect r, double size, FontWeight fw) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: fw, color: Colors.white.withOpacity(0.92))),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: r.width - 16);
    return tp;
  }
}
