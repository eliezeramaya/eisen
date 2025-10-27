import 'package:flutter/material.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

class GanttPalette {
  final Color gradStart;
  final Color gradEnd;
  final Color badgeBg;
  final Color text;
  const GanttPalette({
    required this.gradStart,
    required this.gradEnd,
    required this.badgeBg,
    required this.text,
  });
}

GanttPalette paletteFor(GanttKind k) {
  switch (k) {
    case GanttKind.design:
      // Teal → aqua gradient, high contrast on dark
      return const GanttPalette(
        gradStart: Color(0xFF12CBC4),
        gradEnd: Color(0xFF17D3B0),
        badgeBg: Color(0xE61ED9C3),
        text: Colors.white,
      );
    case GanttKind.dev:
      // Indigo → blue gradient
      return const GanttPalette(
        gradStart: Color(0xFF4C6FFF),
        gradEnd: Color(0xFF2E90FA),
        badgeBg: Color(0xE63374F7),
        text: Colors.white,
      );
    case GanttKind.feedback:
      // Purple-pink → magenta gradient
      return const GanttPalette(
        gradStart: Color(0xFFB35CFF),
        gradEnd: Color(0xFFFF6BD5),
        badgeBg: Color(0xE6D16FFF),
        text: Colors.white,
      );
    case GanttKind.research:
      return const GanttPalette(
        gradStart: Color(0xFF5EEAD4),
        gradEnd: Color(0xFF34D399),
        badgeBg: Color(0xE634D399),
        text: Colors.white,
      );
    case GanttKind.analysis:
      return const GanttPalette(
        gradStart: Color(0xFF93C5FD),
        gradEnd: Color(0xFF60A5FA),
        badgeBg: Color(0xE660A5FA),
        text: Colors.white,
      );
    case GanttKind.qa:
      return const GanttPalette(
        gradStart: Color(0xFFFDE68A),
        gradEnd: Color(0xFFF59E0B),
        badgeBg: Color(0xE6F59E0B),
        text: Colors.black,
      );
    case GanttKind.sync:
      return const GanttPalette(
        gradStart: Color(0xFFA5B4FC),
        gradEnd: Color(0xFF818CF8),
        badgeBg: Color(0xE6818CF8),
        text: Colors.white,
      );
  }
}
