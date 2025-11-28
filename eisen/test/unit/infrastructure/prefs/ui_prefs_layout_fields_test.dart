import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UiPrefsData layout fields roundtrip', () {
    final a = UiPrefsData(
      topKPerQuadrant: 33,
      gamma: 0.91,
      minAreaNormalized: 0.00007,
      quadrantPadding: 0.015,
    );
    final json = a.toJson();
    final b = UiPrefsData.fromJson(json);
    expect(b.topKPerQuadrant, 33);
    expect(b.gamma, closeTo(0.91, 0.0001));
    expect(b.minAreaNormalized, closeTo(0.00007, 1e-7));
    expect(b.quadrantPadding, closeTo(0.015, 0.0001));
  });
}
