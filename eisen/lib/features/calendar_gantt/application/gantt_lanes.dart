import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

/// Assign spans to non-overlapping lanes using a greedy, stable algorithm.
///
/// Algorithm:
/// - Sort by (start asc, end asc) but keep stable indices for final ordering if needed.
/// - Maintain a list of lane end-times.
/// - For each span in order, place it into the first lane whose lastEnd <= span.start
///   (remember end is exclusive). If none found, create a new lane.
/// - Return a new list with lane assigned on each span, preserving the original input order.
List<CalendarSpan> assignLanes(List<CalendarSpan> spans) {
  if (spans.isEmpty) return spans;

  final indexed = spans.asMap().entries.toList();
  indexed.sort((a, b) {
    final s = a.value.start.compareTo(b.value.start);
    if (s != 0) return s;
    final e = a.value.end.compareTo(b.value.end);
    if (e != 0) return e;
    return a.key.compareTo(b.key); // stable
  });

  final laneEnds = <DateTime>[];
  final assigned = List<CalendarSpan>.filled(spans.length, spans.first, growable: false);

  for (final entry in indexed) {
    final i = entry.key;
    final s = entry.value;
    int laneIndex = -1;
    for (var li = 0; li < laneEnds.length; li++) {
      if (!s.start.isBefore(laneEnds[li])) { // lane available when lastEnd <= start
        laneIndex = li;
        break;
      }
    }
    if (laneIndex == -1) {
      laneIndex = laneEnds.length;
      laneEnds.add(s.end);
    } else {
      laneEnds[laneIndex] = s.end;
    }
    assigned[i] = s.copyWith(lane: laneIndex);
  }

  return assigned;
}
