import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

/// Assign spans to non-overlapping lanes using a simple greedy, stable algorithm.
///
/// For Stage 0 we provide a placeholder that returns the input list unchanged.
/// Stage 1 will implement the full lane packing.
List<CalendarSpan> assignLanes(List<CalendarSpan> spans) {
  return spans;
}
