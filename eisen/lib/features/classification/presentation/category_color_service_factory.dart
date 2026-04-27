import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:flutter/material.dart';

CategoryColorService buildClassificationCategoryColorService({
  required List<CategoryConfig> categories,
  Map<String, int> userColorOverrides = const {},
}) {
  final overrides = <String, Color>{
    for (final entry in userColorOverrides.entries)
      entry.key: Color(entry.value),
    for (final category in categories)
      if (!category.isHidden)
        category.name.trim().toLowerCase(): Color(category.colorValue),
  };
  return CategoryColorService(overrides: overrides);
}
