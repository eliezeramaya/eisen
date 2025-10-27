import 'package:flutter/material.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';

/// Painter for Gantt chart body: background and vertical "Now" line.
class GanttPainter extends CustomPainter {
  final TimelineProjector projector;
  final DateTime now;
  const GanttPainter({required this.projector, required this.now});

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
  }

  @override
  bool shouldRepaint(covariant GanttPainter oldDelegate) {
    return oldDelegate.projector.pxPerDay != projector.pxPerDay ||
        oldDelegate.projector.viewStart != projector.viewStart ||
        (oldDelegate.now.difference(now).inMinutes).abs() > 5;
  }
}
