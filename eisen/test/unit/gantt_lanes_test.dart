import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assignLanes', () {
    CalendarSpan s(String id, String a, String b, {int lane = -1}) =>
        CalendarSpan(
          id: id,
          title: id,
          start: DateTime.parse(a),
          end: DateTime.parse(b),
          kind: GanttKind.dev,
          lane: lane,
        );

    test('no overlaps within each lane and minimal lanes', () {
      final spans = [
        s('A', '2025-03-01', '2025-03-05'),
        s('B', '2025-03-02', '2025-03-03'),
        s('C', '2025-03-05',
            '2025-03-07'), // touches A end (exclusive), allowed in same lane
        s('D', '2025-03-03', '2025-03-06'),
      ];

      final out = assignLanes(spans);

      // Preserve input order
      expect(out.map((e) => e.id).toList(), spans.map((e) => e.id).toList());

      // Build lanes map
      final byLane = <int, List<CalendarSpan>>{};
      for (final s in out) {
        expect(s.lane, isNonNegative);
        byLane.putIfAbsent(s.lane, () => []).add(s);
      }

      // No overlaps in each lane (end is exclusive)
      for (final laneSpans in byLane.values) {
        laneSpans.sort((a, b) => a.start.compareTo(b.start));
        for (var i = 1; i < laneSpans.length; i++) {
          expect(!laneSpans[i].start.isBefore(laneSpans[i - 1].end), isTrue,
              reason:
                  'Overlap in lane ${laneSpans[i].lane} between ${laneSpans[i - 1].id} and ${laneSpans[i].id}');
        }
      }

      // Minimal lanes: with given inputs, should be 2 lanes
      final laneCount = byLane.keys.length;
      expect(laneCount,
          anyOf(1, 2)); // Depending on greedy order, but should not exceed 2
    });
  });
}
