import 'package:flutter/foundation.dart';

/// Time scale for the timeline header and projection granularity.
enum TimeScale { days, weeks, months }

/// Visual kind for spans, used to pick palette/gradients.
enum GanttKind { research, analysis, design, dev, qa, sync, feedback }

/// Represents a scheduled span (task window) in the Gantt timeline.
@immutable
class CalendarSpan {
  final String id; // taskId
  final String title;
  final DateTime start; // inclusive
  final DateTime end; // exclusive
  final GanttKind kind; // style bucket
  final int lane; // computed by lane assignment, -1 means unassigned

  const CalendarSpan({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.kind,
    this.lane = -1,
  });

  CalendarSpan copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    GanttKind? kind,
    int? lane,
  }) {
    return CalendarSpan(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      kind: kind ?? this.kind,
      lane: lane ?? this.lane,
    );
  }
}
