import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Eisen brand colors and translucent gradients per quadrant.
class EisenColors {
  static const Color q1UrgentImportant = Color(0xFFE84545);
  static const Color q2Important = Color(0xFFF4996E);
  static const Color q3UrgentNotImportant = Color(0xFFF2B705);
  static const Color q4Neither = Color(0xFF9CA3AF);

  static Color byQuadrant(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return q1UrgentImportant;
      case Quadrant.q2:
        return q2Important;
      case Quadrant.q3:
        return q3UrgentNotImportant;
      case Quadrant.q4:
        return q4Neither;
    }
  }

  static Gradient glow(Quadrant q, {double alpha = 0.28}) {
    final c = byQuadrant(q).withValues(alpha: alpha);
    return RadialGradient(
      colors: [c, c.withValues(alpha: alpha * 0.4), Colors.transparent],
      stops: const [0.0, 0.45, 1.0],
    );
  }
}

