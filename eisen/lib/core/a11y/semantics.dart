import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Accessibility utilities for ensuring WCAG compliance and inclusive UX.
///
/// Provides:
/// - Minimum touch target enforcement (44×44 per WCAG 2.1 AA)
/// - Focus ring decoration for keyboard navigation
/// - Contrast ratio validation for WCAG AA compliance
/// - Semantic label helpers for screen readers
class A11y {
  A11y._();

  /// Minimum touch target size per WCAG 2.1 Level AA (Success Criterion 2.5.5).
  static const minTouch = Size(44, 44);

  /// Wraps a widget to enforce minimum touch target size.
  ///
  /// Ensures the widget meets WCAG 2.1 AA requirements for touch targets.
  /// Use this for all interactive elements (buttons, tiles, controls).
  static Widget touchTarget({required Widget child}) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: child,
      );

  /// Creates a focus ring decoration for keyboard navigation.
  ///
  /// Provides a clear visual indicator when an element has focus, meeting
  /// WCAG 2.1 Success Criterion 2.4.7 (Focus Visible).
  ///
  /// Parameters:
  /// - [color]: Ring color (default: blue with high contrast)
  /// - [width]: Ring stroke width (default: 2.0)
  /// - [offset]: Distance from widget edge (default: 2.0)
  /// - [radius]: Border radius to match widget (default: 12.0)
  static BoxDecoration focusRing({
    Color color = const Color(0xFF2E90FA),
    double width = 2.0,
    double offset = 2.0,
    double radius = 12.0,
  }) {
    return BoxDecoration(
      border: Border.all(color: color, width: width),
      borderRadius: BorderRadius.circular(radius),
      // Add slight shadow for visibility on varied backgrounds
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// Validates contrast ratio between two colors for WCAG AA compliance.
  ///
  /// Returns true if contrast meets WCAG AA standards:
  /// - Normal text: >= 4.5:1
  /// - Large text (18pt+): >= 3:1
  ///
  /// Use this during theme development to ensure quadrant colors have
  /// sufficient contrast against backgrounds.
  static bool meetsContrastAA(Color foreground, Color background,
      {bool largeText = false}) {
    final ratio = _contrastRatio(foreground, background);
    final minRatio = largeText ? 3.0 : 4.5;
    return ratio >= minRatio;
  }

  /// Calculates WCAG contrast ratio between two colors.
  ///
  /// Formula: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 is relative luminance of lighter color
  /// and L2 is relative luminance of darker color.
  static double _contrastRatio(Color c1, Color c2) {
    final l1 = _relativeLuminance(c1);
    final l2 = _relativeLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculates relative luminance per WCAG formula.
  static double _relativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearizes an sRGB color component.
  static double _linearize(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Creates a semantic label for a task tile.
  ///
  /// Format: "Task: [title], Priority: [1-10], Duration: [minutes] minutes, Quadrant: [Q1-Q4], [status]"
  ///
  /// This provides complete context for screen reader users.
  static String taskTileLabel({
    required String title,
    required int priority,
    required int minutes,
    required String quadrant,
    bool isSuggested = false,
    int stackSize = 0,
  }) {
    final parts = <String>[
      if (stackSize > 0)
        'Group of $stackSize tasks in $quadrant'
      else ...[
        'Task: $title',
        'Priority: $priority',
        'Duration: $minutes minutes',
        'Quadrant: $quadrant',
        if (isSuggested) 'Suggested task',
      ],
    ];
    return parts.join(', ');
  }
}
