import 'package:eisen/features/calendar_gantt/application/gantt_snap.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snap utilities', () {
    test('snapFloor days aligns to midnight', () {
      final t = DateTime(2025, 3, 10, 15, 30, 10);
      final s = snapFloor(t, TimeScale.days);
      expect(s, DateTime(2025, 3, 10));
    });

    test('snapFloor weeks aligns to Monday', () {
      // Wed 2025-03-12 → Monday 2025-03-10
      final t = DateTime(2025, 3, 12, 8);
      final s = snapFloor(t, TimeScale.weeks);
      expect(s.weekday, DateTime.monday);
      expect(s, DateTime(2025, 3, 10));
    });

    test('stepDaysForScale', () {
      expect(stepDaysForScale(TimeScale.days), 1);
      expect(stepDaysForScale(TimeScale.weeks), 7);
    });
  });
}
