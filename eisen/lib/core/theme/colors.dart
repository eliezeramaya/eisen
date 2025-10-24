import 'package:flutter/material.dart';

/// Semantic quadrant palette for Eisenhower Matrix.
///
/// Use these colors to keep a consistent emotional tone per quadrant.
class EisenColors {
  EisenColors._();

  // Base (light) palette
  static const q1 = Color(0xFFF04438); // Urgente + Importante
  static const q2 = Color(0xFF12B76A); // Importante no urgente
  static const q3 = Color(0xFFF79009); // Urgente no importante
  static const q4 = Color(0xFF98A2B3); // No urgente + No importante

  // Suggested dark counterparts (same hue, tuned for dark bg)
  static const q1Dark = Color(0xFFFF5C53);
  static const q2Dark = Color(0xFF34D399);
  static const q3Dark = Color(0xFFFFB020);
  static const q4Dark = Color(0xFFB0B8C4);
}

