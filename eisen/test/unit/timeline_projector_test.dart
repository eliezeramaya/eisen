import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimelineProjector', () {
    test('dx and timeAt are inverses within 1ms', () {
      final viewStart = DateTime(2025, 2, 15);
      final p = TimelineProjector(viewStart: viewStart, pxPerDay: 32);

      final ts = [
        DateTime(2025, 2, 15),
        DateTime(2025, 2, 16, 12),
        DateTime(2025, 3, 1, 0, 0, 1),
        DateTime(2026, 1, 1),
      ];

      for (final t in ts) {
        final x = p.dx(t);
        final back = p.timeAt(x);
        expect((back.millisecondsSinceEpoch - t.millisecondsSinceEpoch).abs(),
            lessThanOrEqualTo(1));
      }
    });

    test('widthBetween is symmetric and matches dx diff', () {
      final viewStart = DateTime(2025, 2, 15);
      final p = TimelineProjector(viewStart: viewStart, pxPerDay: 20);
      final a = DateTime(2025, 2, 20);
      final b = DateTime(2025, 3, 5);
      expect(p.widthBetween(a, b), closeTo(p.dx(b) - p.dx(a), 1e-6));
      expect(p.widthBetween(b, a), p.widthBetween(a, b));
    });
  });
}
