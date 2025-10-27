import 'package:flutter/material.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

/// Stage 0 scaffold for GanttChart; structure will be implemented in Stage 2.
class GanttChart extends StatelessWidget {
  final List<CalendarSpan> spans;
  final TimeScale scale;
  final DateTime viewStart;
  const GanttChart({
    super.key,
    required this.spans,
    required this.scale,
    required this.viewStart,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
