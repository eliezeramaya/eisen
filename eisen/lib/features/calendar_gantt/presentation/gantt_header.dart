import 'package:flutter/material.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';

/// Fixed header for the Gantt chart (ticks + labels).
class GanttHeader extends StatelessWidget {
  final TimeScale scale;
  final TimelineProjector projector;
  final DateTime viewStart;
  final DateTime viewEnd;
  final double width;
  final bool workweekOnly;
  const GanttHeader({
    super.key,
    required this.scale,
    required this.projector,
    required this.viewStart,
    required this.viewEnd,
    required this.width,
    this.workweekOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, UiTokens.headerHeight),
  painter: _GanttHeaderPainter(scale: scale, projector: projector, start: viewStart, end: viewEnd, workweekOnly: workweekOnly),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _GanttHeaderPainter extends CustomPainter {
  final TimeScale scale;
  final TimelineProjector projector;
  final DateTime start;
  final DateTime end;
  final bool workweekOnly;
  _GanttHeaderPainter({required this.scale, required this.projector, required this.start, required this.end, required this.workweekOnly});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bg = Paint()..color = UiTokens.panelDark;
    canvas.drawRect(Offset.zero & size, bg);

    // Divider baseline
    final divider = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = UiTokens.divider;
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), divider);

    // Label style
    const baseText = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70);

    // Tick paint
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(.08);

    DateTime cursor = _alignToScale(start, scale);
    // Label density control to avoid overlaps when zoomed out
    final pxPerDay = projector.pxPerDay;
    int dayStep = 1;
    if (scale == TimeScale.days) {
      if (pxPerDay < 22) {
        dayStep = 3;
      } else if (pxPerDay < 28) {
        dayStep = 2;
      }
    }
    int dayCounter = 0;
    while (!cursor.isAfter(end)) {
      final x = projector.dx(cursor);
      // Tick
      canvas.drawLine(Offset(x, size.height - 16), Offset(x, 0), tick);
      // Label
      if (!(workweekOnly && scale == TimeScale.days && (cursor.weekday == DateTime.saturday || cursor.weekday == DateTime.sunday))) {
        bool draw = true;
        if (scale == TimeScale.days) {
          draw = (dayCounter % dayStep) == 0;
        }
        if (draw) {
          final label = _labelFor(cursor, scale);
          final tp = TextPainter(text: TextSpan(text: label, style: baseText), textDirection: TextDirection.ltr)
            ..layout(maxWidth: 200);
          tp.paint(canvas, Offset(x + 6, (size.height - tp.height) / 2));
        }
      }
      // Next
      cursor = _increment(cursor, scale, dayStep: dayStep);
      if (scale == TimeScale.days) dayCounter += dayStep;
    }
  }

  @override
  bool shouldRepaint(covariant _GanttHeaderPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.projector.pxPerDay != projector.pxPerDay ||
  oldDelegate.projector.viewStart != projector.viewStart ||
        oldDelegate.start != start ||
  oldDelegate.end != end ||
  oldDelegate.workweekOnly != workweekOnly;
  }

  static DateTime _alignToScale(DateTime t, TimeScale s) {
    switch (s) {
      case TimeScale.days:
        return DateTime(t.year, t.month, t.day);
      case TimeScale.weeks:
        // Align to Monday
        final weekday = t.weekday; // Monday=1..Sunday=7
        final delta = weekday - DateTime.monday;
        final aligned = DateTime(t.year, t.month, t.day).subtract(Duration(days: delta));
        return DateTime(aligned.year, aligned.month, aligned.day);
      case TimeScale.months:
        return DateTime(t.year, t.month);
    }
  }

  static DateTime _increment(DateTime t, TimeScale s, {int dayStep = 1}) {
    switch (s) {
      case TimeScale.days:
        return t.add(Duration(days: dayStep));
      case TimeScale.weeks:
        return t.add(const Duration(days: 7));
      case TimeScale.months:
        final month = t.month == 12 ? 1 : t.month + 1;
        final year = t.month == 12 ? t.year + 1 : t.year;
        return DateTime(year, month);
    }
  }

  static String _labelFor(DateTime t, TimeScale s) {
    switch (s) {
      case TimeScale.days:
        return '${t.month}/${t.day}';
      case TimeScale.weeks:
        return 'W${_weekOfYear(t)}';
      case TimeScale.months:
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return months[t.month - 1];
    }
  }

  static int _weekOfYear(DateTime date) {
    // Simple week-of-year calc (not ISO exact); good enough for header labeling.
    final firstDay = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDay).inDays;
    return (diff / 7).floor() + 1;
  }
}
