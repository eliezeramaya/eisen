import 'package:eisen/features/tasks/context_aware/application/contextual_treemap_layout.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:flutter/material.dart';

class ContextualTreemapPalette {
  const ContextualTreemapPalette._();

  static const background = Color(0xFFF5F3EE);
  static const surface = Color(0xFFE3ECE5);
  static const surfaceElevated = Color(0xFFECF2ED);
  static const surfaceDark = Color(0xFF2F4F46);
  static const border = Color(0xFFCAD8CF);

  static const textPrimary = Color(0xFF24352F);
  static const textSecondary = Color(0xFF6F7C76);
  static const textOnDark = Color(0xFFF7F5F0);
  static const textMutedOnDark = Color(0xFFC9D7CF);

  static const primary = Color(0xFF5E8F7B);
  static const secondary = Color(0xFF7AA6A1);
  static const softSage = Color(0xFFA8C3B0);
  static const mistGreen = Color(0xFFDCE9E2);
  static const warmNeutral = Color(0xFFDCCFBE);
  static const softOlive = Color(0xFF92A66E);
  static const alertSoft = Color(0xFFD88C7A);
  static const alertStrong = Color(0xFFB7746B);

  static const highRelevance = Color(0xFF7FB38A);
  static const mediumRelevance = Color(0xFFA8C3B0);
  static const lowRelevance = Color(0xFFC9D7CF);
  static const outOfContext = Color(0xFFD9DDD9);
  static const completed = Color(0xFFDCE9E2);

  static Color groupBaseColor(
    ContextTreemapGroup group,
    ColorScheme colorScheme,
  ) {
    switch (group) {
      case ContextTreemapGroup.home:
        return softSage;
      case ContextTreemapGroup.office:
        return secondary;
      case ContextTreemapGroup.errands:
        return warmNeutral;
      case ContextTreemapGroup.study:
        return mistGreen;
      case ContextTreemapGroup.wellness:
        return softOlive;
      case ContextTreemapGroup.unknown:
        return Color.lerp(surface, colorScheme.outlineVariant, 0.35)!;
    }
  }

  static Color relevanceColor(double score) {
    if (score >= 0.72) return highRelevance;
    if (score >= 0.48) return mediumRelevance;
    if (score >= 0.25) return lowRelevance;
    return outOfContext;
  }

  static Color tileColor({
    required RankedContextTask rankedTask,
    required ContextTreemapGroup group,
    required ColorScheme colorScheme,
    bool isActiveSection = false,
    bool isSelected = false,
  }) {
    if (rankedTask.task.isCompleted) return completed;

    var color = Color.lerp(
      groupBaseColor(group, colorScheme),
      relevanceColor(rankedTask.score),
      isActiveSection ? 0.46 : 0.34,
    )!;

    if (rankedTask.task.isBlocked) {
      color = Color.lerp(color, alertSoft, 0.52)!;
    } else if (rankedTask.score >= 0.86) {
      color = Color.lerp(color, highRelevance, 0.22)!;
    }

    if (isSelected) {
      color = Color.lerp(color, primary, 0.18)!;
    }

    return color;
  }

  static Color tileBorderColor({
    required RankedContextTask rankedTask,
    required ContextTreemapGroup group,
    required ColorScheme colorScheme,
    bool isSelected = false,
  }) {
    if (rankedTask.task.isBlocked) return alertStrong;
    if (isSelected) return surfaceDark;
    return Color.lerp(groupBaseColor(group, colorScheme), border, 0.45)!;
  }

  static Color textColorFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() < 0.34 ? textOnDark : textPrimary;
  }

  static Color mutedTextColorFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() < 0.34
        ? textMutedOnDark
        : textSecondary;
  }
}
