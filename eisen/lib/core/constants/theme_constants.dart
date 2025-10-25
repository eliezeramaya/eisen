// Centralized theme constants; no Flutter imports needed here.

/// Theme constants for glass morphism effects and visual styling.
///
/// Centralizes hardcoded values for blur, opacity, shadows, and colors
/// used in the app's glassmorphic design language.
class ThemeConstants {
  ThemeConstants._();

  // Glass effect properties
  /// Backdrop blur sigma for glassmorphism effect.
  static const double glassBlur = 12.0;

  /// Border radius for glass containers and tiles.
  static const double glassRadius = 20.0;

  /// Glass background opacity (dark mode).
  static const double glassBgOpacityDark = 0xAA / 255;

  /// Glass background opacity (light mode).
  static const double glassBgOpacityLight = 0xCC / 255;

  /// Glass border opacity.
  static const double glassBorderOpacity = 0.08;

  /// Glass border opacity (minimal mode).
  static const double glassBorderOpacityMinimal = 0.25;

  /// Shadow opacity for elevated tiles.
  static const double shadowOpacity = 0.3;

  /// Shadow opacity for dragging tiles.
  static const double shadowOpacityDragging = 0.45;

  /// Halo glow opacity.
  static const double haloOpacity = 0.15;

  // Tile styling
  /// Tile background opacity (glassmorphic fill).
  static const double tileFillOpacity = 0.06;

  /// Tile border opacity.
  static const double tileBorderOpacity = 0.12;

  /// Tile border opacity (minimal mode).
  static const double tileBorderOpacityMinimal = 0.6;

  /// Tile shadow blur radius.
  static const double tileShadowBlur = 8.0;

  /// Tile shadow blur radius (dragging).
  static const double tileShadowBlurDragging = 14.0;

  /// Tile shadow spread.
  static const double tileShadowSpread = 2.0;

  /// Tile scale factor when dragging.
  static const double tileScaleDragging = 1.04;

  /// Tile drag shift bias towards quadrant center.
  static const double tileDragBias = 0.12;

  /// Maximum drag shift in pixels.
  static const double tileDragShiftMax = 6.0;

  /// Magnetic drag shift towards quadrant center.
  static const double tileMagneticShiftMax = 8.0;

  // Text and label opacity
  /// Text opacity for labels (dark mode).
  static const double textOpacityDark = 0.85;

  /// Text opacity for secondary text (dark mode).
  static const double textOpacitySecondaryDark = 0.9;

  /// Text opacity for labels (minimal mode).
  static const double textOpacityMinimal = 0.87;

  /// Text opacity for hint text.
  static const double textOpacityHint = 0.54;

  // Animation and effects
  /// Pulse animation ring max radius.
  static const double pulseRingMaxRadius = 28.0;

  /// Pulse animation ring min radius.
  static const double pulseRingMinRadius = 8.0;

  /// Pulse animation ring opacity.
  static const double pulseRingOpacity = 0.45;

  /// Pulse animation ring opacity (minimal mode).
  static const double pulseRingOpacityMinimal = 0.35;

  /// Hover quadrant overlay opacity.
  static const double hoverOverlayOpacity = 0.08;

  /// Hover quadrant overlay opacity (minimal mode).
  static const double hoverOverlayOpacityMinimal = 0.06;

  /// Hover quadrant border opacity.
  static const double hoverBorderOpacity = 0.25;

  /// Present quadrant glow opacity.
  static const double presentGlowOpacity = 0.06;

  /// Present quadrant glow opacity (minimal mode).
  static const double presentGlowOpacityMinimal = 0.12;

  // Grid and axis
  /// Center crosshair grid line opacity.
  static const double gridLineOpacity = 0.08;

  /// Axis legend opacity.
  static const double axisLabelOpacity = 0.85;

  // Banner and badges
  /// Progress banner background opacity (dark mode).
  static const double bannerBgOpacityDark = 0.28;

  /// Progress banner background opacity (light mode).
  static const double bannerBgOpacityLight = 0.7;

  /// Stack badge background opacity (dark mode).
  static const double stackBadgeBgOpacityDark = 0.35;

  /// Stack badge background opacity (light mode).
  static const double stackBadgeBgOpacityLight = 0.9;

  /// Stack badge border opacity.
  static const double stackBadgeBorderOpacity = 0.18;

  // Quick add buttons
  /// Quick add button background opacity (dark mode).
  static const double quickAddBgOpacityDark = 0.35;

  /// Quick add button background opacity (light mode).
  static const double quickAddBgOpacityLight = 0.85;

  // Inline editor
  /// Inline editor background opacity.
  static const double inlineEditorBgOpacity = 0.45;

  // Edit/Done dots
  /// Edit dot background opacity.
  static const double editDotBgOpacity = 0.45;

  /// Edit dot background opacity (minimal mode).
  static const double editDotBgOpacityMinimal = 0.9;

  /// Edit dot border opacity.
  static const double editDotBorderOpacity = 0.25;

  /// Edit dot border opacity (minimal mode).
  static const double editDotBorderOpacityMinimal = 0.26;

  // Quadrant indicator
  /// Quadrant color indicator opacity.
  static const double quadrantIndicatorOpacity = 0.12;

  /// Suggested task star icon opacity.
  static const double suggestedStarOpacity = 0.9;

  /// Suggested task star icon opacity (minimal mode).
  static const double suggestedStarOpacityMinimal = 0.95;
}
