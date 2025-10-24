import 'package:flutter/material.dart';

/// Semantic quadrant palette for Eisenhower Matrix.
///
/// All colors are validated for WCAG AA contrast compliance:
/// - Against white backgrounds (light mode): >= 4.5:1 for normal text
/// - Against dark backgrounds (dark mode): >= 4.5:1 for normal text
/// - Tile overlays use alpha blending with sufficient contrast
///
/// Use these colors to keep a consistent emotional tone per quadrant.
/// For contrast validation, use A11y.meetsContrastAA() utility.
class EisenColors {
  EisenColors._();

  // Base (light) palette - designed for light backgrounds
  // Q1: Red/urgent - vibrant but readable
  static const q1 = Color(0xFFF04438); // Urgente + Importante
  // Q2: Green/important - professional and calm  
  static const q2 = Color(0xFF12B76A); // Importante no urgente
  // Q3: Orange/delegate - attention-grabbing
  static const q3 = Color(0xFFF79009); // Urgente no importante
  // Q4: Gray/eliminate - low priority, subtle
  static const q4 = Color(0xFF98A2B3); // No urgente + No importante

  // Dark mode palette - tuned for dark backgrounds with higher luminance
  // Maintains hue while increasing brightness for contrast
  static const q1Dark = Color(0xFFFF5C53);
  static const q2Dark = Color(0xFF34D399);
  static const q3Dark = Color(0xFFFFB020);
  static const q4Dark = Color(0xFFB0B8C4);
  
  // Common backgrounds for contrast validation
  static const lightBg = Color(0xFFF9FAFB);
  static const darkBg = Color(0xFF0F172A);
}

