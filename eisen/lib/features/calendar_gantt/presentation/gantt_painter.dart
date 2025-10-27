import 'package:flutter/material.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_palette.dart';

/// Painter for Gantt chart body: background and vertical "Now" line.
class GanttPainter extends CustomPainter {
  final TimelineProjector projector;
  final DateTime now;
  final List<CalendarSpan> spans;
  const GanttPainter({required this.projector, required this.now, required this.spans});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bg = Paint()..color = UiTokens.bgDark;
    canvas.drawRect(Offset.zero & size, bg);

    // "Now" line
    final x = projector.dx(now).clamp(0.0, size.width);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = UiTokens.now;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);

    // Subtle glow
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = UiTokens.now.withOpacity(.12);
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), glow);

    // Bars (Stage 3)
    final barHeight = UiTokens.laneHeight - UiTokens.laneGap;
    final yPad = UiTokens.laneGap / 2;
    final r = Radius.circular(UiTokens.barRadius);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = UiTokens.barStroke
      ..color = Colors.white.withOpacity(.06);

    // Text baseline style
    const titleStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.1,
    );
    const badgeTextStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

    for (final s in spans) {
      if (s.lane < 0) continue; // skip unassigned
      final left = projector.dx(s.start);
      final right = projector.dx(s.end);
      double w = (right - left).toDouble();
      if (w < 0.5) continue; // nothing to draw

      // Cull if fully outside viewport (small tolerance)
      if (right < -50 || left > size.width + 50) continue;

      final y = s.lane * UiTokens.laneHeight + yPad;
      final rect = Rect.fromLTWH(left, y.toDouble(), w, barHeight);
      final rr = RRect.fromRectAndCorners(rect, topLeft: r, topRight: r, bottomLeft: r, bottomRight: r);

      // Gradient fill
      final palette = paletteFor(s.kind);
      final shader = LinearGradient(
        colors: [palette.gradStart, palette.gradEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);
      final fill = Paint()..shader = shader;
      canvas.drawRRect(rr, fill);

      // Border
      canvas.drawRRect(rr.deflate(UiTokens.painterDeflateAA), borderPaint);

      // Title text (only when enough width)
      if (w > 56) {
        final maxTextWidth = w - 16; // padding inside bar
        final tp = TextPainter(
          text: TextSpan(text: s.title, style: titleStyle.copyWith(color: palette.text)),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxTextWidth);
        final textOffset = Offset(rect.left + 8, rect.top + (rect.height - tp.height) / 2);
        tp.paint(canvas, textOffset);
      }

      // Duration badge (e.g., 3d) when enough width
      final days = (s.end.difference(s.start).inDays).clamp(1, 999);
      final badgeLabel = '${days}d';
      if (w > 88) {
        final tp = TextPainter(
          text: TextSpan(text: badgeLabel, style: badgeTextStyle.copyWith(color: palette.text)),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 48);
        final padH = 6.0;
        final padV = 4.0;
        final bw = tp.width + padH * 2;
        final bh = tp.height + padV * 2;
        final bx = rect.right - bw - 8; // right aligned inside bar
        final by = rect.top + (rect.height - bh) / 2;
        final bRect = Rect.fromLTWH(bx, by, bw, bh);
        final bRRect = RRect.fromRectAndRadius(bRect, const Radius.circular(10));
        final badgePaint = Paint()..color = palette.badgeBg;
        canvas.drawRRect(bRRect, badgePaint);
        tp.paint(canvas, Offset(bRect.left + padH, bRect.top + padV - 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GanttPainter oldDelegate) {
    if (oldDelegate.projector.pxPerDay != projector.pxPerDay) return true;
    if (oldDelegate.projector.viewStart != projector.viewStart) return true;
    if ((oldDelegate.now.difference(now).inMinutes).abs() > 5) return true;
    if (oldDelegate.spans.length != spans.length) return true;
    // Cheap check: if any lane or start/end changed
    for (var i = 0; i < spans.length && i < oldDelegate.spans.length; i++) {
      final a = spans[i];
      final b = oldDelegate.spans[i];
      if (a.lane != b.lane || a.start != b.start || a.end != b.end) return true;
    }
    return false;
  }
}
