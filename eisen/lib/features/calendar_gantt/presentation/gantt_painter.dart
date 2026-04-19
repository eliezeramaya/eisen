import 'dart:math' as math;

import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_cache.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_palette.dart';
import 'package:flutter/material.dart';

/// Painter for Gantt chart body: background and vertical "Now" line.
class GanttPainter extends CustomPainter {
  const GanttPainter({
    required this.projector,
    required this.now,
    required this.spans,
    required this.hScroll,
    required this.viewportWidth,
    this.showBadges = true,
    this.showTodayLine = true,
    this.laneHeight = UiTokens.laneHeight,
    this.laneGap = UiTokens.laneGap,
    this.milestones = const <(DateTime, String)>[],
  }) : super(repaint: hScroll);
  final TimelineProjector projector;
  final DateTime now;
  final List<CalendarSpan> spans;
  final ScrollController hScroll;
  final double viewportWidth;
  final bool showBadges;
  final bool showTodayLine;
  final double laneHeight;
  final double laneGap;
  final List<(DateTime, String)> milestones;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bg = Paint()..color = UiTokens.bgDark;
    canvas.drawRect(Offset.zero & size, bg);

    // "Now" line
    if (showTodayLine) {
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
        ..color = UiTokens.now.withValues(alpha: 0.12);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), glow);
    }

    // Bars (Stage 3) + Stage 5: viewport culling & caches
    final barHeight = laneHeight - laneGap;
    final yPad = laneGap / 2;
    final r = Radius.circular(UiTokens.barRadius);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = UiTokens.barStroke
      ..color = Colors.white.withValues(alpha: 0.06);

    // Text baseline style with subtle shadow for contrast (AA aid on gradients)
    final titleStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.1,
      shadows: const [
        Shadow(color: Color(0x99000000), blurRadius: 1.5, offset: Offset(0, 0)),
      ],
    );
    final badgeTextStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.0,
      shadows: [
        Shadow(color: Color(0x80000000), blurRadius: 1.0, offset: Offset(0, 0)),
      ],
    );

    // Viewport (content coordinates)
    final viewLeft = hScroll.hasClients ? hScroll.offset : 0.0;
    final viewRight = viewLeft + viewportWidth;
    const cullPad = 50.0; // tolerance

    for (final s in spans) {
      if (s.lane < 0) continue; // skip unassigned
      // Geometry cache
      final gKey = GeometryKey(
        id: s.id,
        viewStartMs: projector.viewStart.millisecondsSinceEpoch,
        startMs: s.start.millisecondsSinceEpoch,
        endMs: s.end.millisecondsSinceEpoch,
        pxPerDay: projector.pxPerDay,
        lane: s.lane,
      );
      Rect? rect = GanttCaches.geometry.get(gKey);
      if (rect == null) {
        final left = projector.dx(s.start);
        final right = projector.dx(s.end);
        final w = (right - left).toDouble();
        final y = s.lane * UiTokens.laneHeight + yPad;
        rect = Rect.fromLTWH(left, y.toDouble(), w, barHeight);
        GanttCaches.geometry.set(gKey, rect);
      }
      final left = rect.left;
      final right = rect.right;
      final double w = rect.width;
      if (w < 0.5) continue; // nothing to draw

      // Cull if fully outside viewport (small tolerance)
      if (right < viewLeft - cullPad || left > viewRight + cullPad) continue;

      final rr = RRect.fromRectAndCorners(rect,
          topLeft: r, topRight: r, bottomLeft: r, bottomRight: r);

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
        final tKey = TextKey(
            text: s.title,
            fontSize: titleStyle.fontSize!,
            maxWidth: maxTextWidth,
            colorValue: palette.text.toARGB32());
        var tp = GanttCaches.text.get(tKey);
        if (tp == null) {
          tp = TextPainter(
            text: TextSpan(
                text: s.title, style: titleStyle.copyWith(color: palette.text)),
            maxLines: 1,
            ellipsis: '…',
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxTextWidth);
          GanttCaches.text.set(tKey, tp);
        }
        final textOffset =
            Offset(rect.left + 8, rect.top + (rect.height - tp.height) / 2);
        tp.paint(canvas, textOffset);
      }

      // Duration badge (e.g., 3d) when enough width
      final days = s.end.difference(s.start).inDays.clamp(1, 999);
      final badgeLabel = '${days}d';
      if (showBadges && w > 88) {
        final tKey = TextKey(
            text: badgeLabel,
            fontSize: badgeTextStyle.fontSize!,
            maxWidth: 48,
            colorValue: palette.text.toARGB32());
        var tp = GanttCaches.text.get(tKey);
        if (tp == null) {
          tp = TextPainter(
            text: TextSpan(
                text: badgeLabel,
                style: badgeTextStyle.copyWith(color: palette.text)),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 48);
          GanttCaches.text.set(tKey, tp);
        }
        final padH = 6.0;
        final padV = 4.0;
        final bw = tp.width + padH * 2;
        final bh = tp.height + padV * 2;
        final bx = rect.right - bw - 8; // right aligned inside bar
        final by = rect.top + (rect.height - bh) / 2;
        final bRect = Rect.fromLTWH(bx, by, bw, bh);
        final bRRect =
            RRect.fromRectAndRadius(bRect, const Radius.circular(10));
        final badgePaint = Paint()..color = palette.badgeBg;
        canvas.drawRRect(bRRect, badgePaint);
        tp.paint(canvas, Offset(bRect.left + padH, bRect.top + padV - 0.5));
      }
    }

    // Milestones (simple diamond + label) — demo only
    if (milestones.isNotEmpty) {
      final y = math.min(size.height - 24, laneHeight * 2 + yPad);
      for (final m in milestones) {
        final x = projector.dx(m.$1);
        final dSize = 14.0;
        final rect =
            Rect.fromCenter(center: Offset(x, y), width: dSize, height: dSize);
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
        final fill = Paint()..color = const Color(0xFF2EE6B8);
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.20)
          ..strokeWidth = 1;
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);

        // Label
        final tp = TextPainter(
          text: TextSpan(
              text: m.$2,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 200);
        tp.paint(canvas, Offset(x + 10, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GanttPainter oldDelegate) {
    if (oldDelegate.projector.pxPerDay != projector.pxPerDay) return true;
    if (oldDelegate.projector.viewStart != projector.viewStart) return true;
    if (oldDelegate.now.difference(now).inMinutes.abs() > 5) return true;
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
