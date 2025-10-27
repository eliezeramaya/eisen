/// Layout constants for treemap rendering and UI spacing.
///
/// These values define minimum tile sizes, spacing, and thresholds
/// used throughout the application for consistent layout behavior.
class LayoutConstants {
  LayoutConstants._();

  /// Minimum tile area in pixels (width × height) for interactive tiles.
  /// Tiles smaller than this are stacked and represented by a "+N" badge.
  static const double minTileAreaPx = 44.0 * 44.0; // 1936 px²

  /// Minimum tile dimension for hit-testing (both width and height).
  static const double minTileSize = 44.0;

  /// Gap between treemap tiles to prevent clipped rounded corners.
  static const double tileGap = 3.0;

  /// Tile border radius for rounded corners.
  static const double tileBorderRadius = 12.0;

  /// Minimum tile area threshold in normalized [0..1] coordinates.
  /// Used by layout algorithm to trigger stacking.
  static const double minTileArea01 = 0.002;

  /// Threshold area (px²) for showing edit/done buttons on tiles.
  static const double minAreaForButtons = 12000.0;

  /// Threshold area (px²) for rendering title text on tiles.
  static const double minAreaForTitle = 16000.0;

  /// Threshold area (px²) for rendering metadata (priority, minutes).
  static const double minAreaForMetadata = 12000.0;

  /// Threshold area (px²) for rendering notes preview.
  static const double minAreaForNotes = 26000.0;

  /// Threshold area (px²) for multi-line title rendering.
  static const double minAreaForMultilineTitle = 18000.0;

  /// Threshold area (px²) for larger title font size.
  static const double minAreaForLargeTitleFont = 30000.0;

  /// Font size for title on medium tiles.
  static const double titleFontSizeMedium = 13.0;

  /// Font size for title on small tiles.
  static const double titleFontSizeSmall = 12.0;

  /// Font size for title on large tiles.
  static const double titleFontSizeLarge = 14.0;

  /// Font size for metadata text.
  static const double metadataFontSize = 12.0;

  /// Font size for stack badge "+N" text.
  static const double stackBadgeFontSize = 14.0;

  /// Edit/done button size.
  static const double buttonSize = 28.0;

  /// Button margin from tile edges.
  static const double buttonMargin = 6.0;

  /// Text padding inside tiles.
  static const double textPadding = 8.0;

  /// Inline editor height.
  static const double inlineEditorHeight = 56.0;

  /// Inline editor deflation from tile bounds.
  static const double inlineEditorDeflate = 6.0;
}
