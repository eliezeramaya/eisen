import 'package:eisen/features/atlas/domain/atlas_color_resolver.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class AtlasVisualEncoding {
  const AtlasVisualEncoding({
    required this.fillColor,
    required this.borderColor,
    required this.opacity,
    required this.labelColor,
    required this.showConfidenceBorder,
    required this.showFocusGlow,
  });

  final Color fillColor;
  final Color borderColor;
  final double opacity;
  final Color labelColor;
  final bool showConfidenceBorder;
  final bool showFocusGlow;
}

AtlasVisualEncoding resolveAtlasVisualEncoding({
  required Task task,
  required ThemeData theme,
  required bool isFocused,
}) {
  final brightness = theme.brightness;
  final base = atlasMutedColorForQuadrant(task.quadrant, brightness);
  final lowConfidence = task.classificationConfidence == ConfidenceLevel.low ||
      task.classificationConfidence == null;
  final isArchive = task.quadrant == Quadrant.q4 || task.isArchived;
  final opacity = task.isArchived ? 0.35 : (isArchive ? 0.68 : 0.92);
  final borderAlpha = lowConfidence ? 0.92 : 0.42;
  final labelColor =
      ThemeData.estimateBrightnessForColor(base) == Brightness.dark
          ? Colors.white
          : Colors.black.withValues(alpha: 0.82);

  return AtlasVisualEncoding(
    fillColor: base,
    borderColor: lowConfidence
        ? theme.colorScheme.outline
        : base.withValues(alpha: borderAlpha),
    opacity: opacity,
    labelColor: labelColor,
    showConfidenceBorder: lowConfidence,
    showFocusGlow: isFocused,
  );
}
