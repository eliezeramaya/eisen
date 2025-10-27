import 'package:flutter/material.dart';
import 'package:eisen/core/ui/ui_tokens.dart';

/// Custom painter placeholder for Gantt chart body.
class GanttPainter extends CustomPainter {
  const GanttPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Fill dark background
    final bg = Paint()..color = UiTokens.bgDark;
    canvas.drawRect(Offset.zero & size, bg);
  }

  @override
  bool shouldRepaint(covariant GanttPainter oldDelegate) => false;
}
