import 'package:eisen/core/theme/colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

Color atlasColorForQuadrant(Quadrant quadrant, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return switch (quadrant) {
    Quadrant.q1 => isDark ? EisenColors.q1Dark : EisenColors.q1,
    Quadrant.q2 => isDark ? EisenColors.q2Dark : EisenColors.q2,
    Quadrant.q3 => isDark ? EisenColors.q3Dark : EisenColors.q3,
    Quadrant.q4 => isDark ? EisenColors.q4Dark : EisenColors.q4,
  };
}

Color atlasMutedColorForQuadrant(Quadrant quadrant, Brightness brightness) {
  final base = atlasColorForQuadrant(quadrant, brightness);
  if (quadrant == Quadrant.q4) {
    return HSLColor.fromColor(base)
        .withSaturation(0.10)
        .withLightness(brightness == Brightness.dark ? 0.54 : 0.68)
        .toColor();
  }
  return base;
}
