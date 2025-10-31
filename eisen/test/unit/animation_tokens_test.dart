import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layout animations are 200–300ms easeOutCubic', () {
    expect(AnimTokens.layout.inMilliseconds >= 200, isTrue);
    expect(AnimTokens.layout.inMilliseconds <= 300, isTrue);
    expect(AnimTokens.curve, equals(Curves.easeOutCubic));
  });
}
