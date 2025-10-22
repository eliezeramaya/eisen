import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

void main() {
  test('weight clamps and remains finite', () {
    final base = Task(id: 't', title: 't', quadrant: Quadrant.q2, priority: 5, minutes: 30);

    // Extreme values should clamp to safe bounds and remain finite
    final extremeHigh = base.copyWith(priority: 999, minutes: 100000);
    final extremeLow = base.copyWith(priority: -100, minutes: -1);
    final noDue = base.copyWith(due: null);
    final soonDue = base.copyWith(due: DateTime.now().add(const Duration(hours: 1)));

    final wHigh = weight(extremeHigh);
    final wLow = weight(extremeLow);
    final wNoDue = weight(noDue);
    final wSoon = weight(soonDue);

    for (final w in [wHigh, wLow, wNoDue, wSoon]) {
      expect(w.isFinite, isTrue, reason: 'Weight not finite');
      expect(w >= 0, isTrue, reason: 'Weight negative');
    }
    // Due sooner should not decrease weight
    expect(wSoon >= wNoDue, isTrue);
  });
}

