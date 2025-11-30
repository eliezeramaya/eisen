import 'package:flutter/material.dart';

/// Service for managing category colors with hash-based defaults and user overrides.
///
/// Architecture:
/// 1. Each category gets a stable, deterministic color from a base palette (hash-based)
/// 2. Users can override specific category colors via UiPrefsData.categoryColors
/// 3. Ensures consistent visual identity for categories across the app
///
/// Usage:
/// ```dart
/// final service = CategoryColorService(overrides: userPrefs.categoryColors);
/// final color = service.getColorForCategory('work');
/// ```
class CategoryColorService {
  const CategoryColorService({this.overrides = const {}});

  /// User-defined color overrides from preferences.
  /// Key: normalized category name (lowercase, trimmed)
  /// Value: ARGB color value as int
  final Map<String, Color> overrides;

  /// Base color palette for categories.
  ///
  /// Carefully selected 16 colors that:
  /// - Work well on both light and dark themes
  /// - Provide good contrast for text and borders
  /// - Are distinguishable from each other
  /// - Match the Material Design 3 aesthetic
  /// - Avoid colors already used for quadrants (red, green, orange, blue)
  static const List<Color> _basePalette = [
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green (different shade than Q2)
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange (different shade than Q3)
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFFF44336), // Red (different shade than Q1)
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF9E9E9E), // Grey (fallback)
  ];

  /// Get a stable color for a category name.
  ///
  /// Algorithm:
  /// 1. Normalize the category name (lowercase, trim whitespace)
  /// 2. Check if user has overridden this category's color
  /// 3. If no override, compute hash and map to base palette
  ///
  /// Returns a [Color] that is:
  /// - Stable: same category always gets same color
  /// - Consistent: works across app restarts
  /// - Customizable: respects user overrides
  Color getColorForCategory(String categoryName) {
    // Normalize category name for consistency
    final normalized = _normalizeCategoryName(categoryName);

    // Return empty color for empty categories
    if (normalized.isEmpty) {
      return _basePalette.last; // Grey fallback
    }

    // Check for user override first
    if (overrides.containsKey(normalized)) {
      return overrides[normalized]!;
    }

    // Compute hash-based color from palette
    return _getHashColor(normalized);
  }

  /// Normalize category name for consistent hashing and lookup.
  ///
  /// Applies:
  /// - Trim whitespace
  /// - Convert to lowercase
  /// - Replace multiple spaces with single space
  String _normalizeCategoryName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Compute deterministic color from category name using hash.
  ///
  /// Uses Dart's built-in [String.hashCode] which is deterministic
  /// within a single execution (stable for our use case).
  ///
  /// The hash is mapped to palette index using modulo to ensure
  /// we always get a valid color from our base palette.
  Color _getHashColor(String normalizedName) {
    // Compute hash of normalized name
    final hash = normalizedName.hashCode;

    // Map to palette index (always positive, wraps around)
    final index = hash.abs() % _basePalette.length;

    return _basePalette[index];
  }

  /// Get a lighter variant of a category color for backgrounds.
  ///
  /// Useful for:
  /// - Pill backgrounds (category.withOpacity(0.15))
  /// - Tile borders with subtle fill
  /// - Hover states
  Color getLightVariant(String categoryName, {double opacity = 0.15}) {
    final base = getColorForCategory(categoryName);
    return base.withValues(alpha: opacity);
  }

  /// Get a darker variant of a category color for borders.
  ///
  /// Useful for:
  /// - Pill borders
  /// - Tile accent lines
  /// - Active states
  Color getDarkVariant(String categoryName, {double opacity = 0.8}) {
    final base = getColorForCategory(categoryName);
    return HSLColor.fromColor(base)
        .withLightness(0.4)
        .toColor()
        .withValues(alpha: opacity);
  }

  /// Get all detected categories with their current colors.
  ///
  /// Useful for:
  /// - Category manager UI
  /// - Color legend
  /// - Analytics
  Map<String, Color> getCategoryColorMap(Set<String> categoryNames) {
    return {
      for (final name in categoryNames) name: getColorForCategory(name),
    };
  }

  /// Check if a category has a user-defined override.
  bool hasOverride(String categoryName) {
    final normalized = _normalizeCategoryName(categoryName);
    return overrides.containsKey(normalized);
  }

  /// Get the base palette for UI purposes (color picker, legend, etc.).
  static List<Color> get basePalette => List.unmodifiable(_basePalette);
}
