import 'package:flutter/material.dart';
import 'package:eisen/core/services/ui_prefs.dart';

/// Top-level user preferences model for the Settings feature.
///
/// This wraps [UiPrefsData] so the feature can evolve independently from
/// the low-level storage format while remaining backward compatible.
@immutable
class UserPrefs {
  const UserPrefs({
    required this.ui,
    required this.categoryUsage,
  });

  final UiPrefsData ui;
  final List<CategoryUsage> categoryUsage;

  UserPrefs copyWith({
    UiPrefsData? ui,
    List<CategoryUsage>? categoryUsage,
  }) {
    return UserPrefs(
      ui: ui ?? this.ui,
      categoryUsage: categoryUsage ?? this.categoryUsage,
    );
  }
}

/// Simple usage tracker for Settings categories (General, Appearance, etc.).
class CategoryUsage {
  const CategoryUsage({required this.id, required this.openCount});

  final String id; // e.g. 'general', 'appearance', 'layout'
  final int openCount;

  CategoryUsage copyWith({int? openCount}) =>
      CategoryUsage(id: id, openCount: openCount ?? this.openCount);
}

/// Default preferences used by "Reset to defaults" (domain-level source of truth).
class UserPrefsDefaults {
  const UserPrefsDefaults._();

  static const UserPrefs value = UserPrefs(
    ui: UiPrefsData(),
    categoryUsage: <CategoryUsage>[],
  );
}

