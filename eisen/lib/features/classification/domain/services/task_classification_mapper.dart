import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

Task applyClassificationToTask({
  required Task task,
  required ClassificationMetadata metadata,
  required List<CategoryConfig> categories,
}) {
  final category = _findCategory(categories, metadata.categoryId);
  final categoryLabel = category?.name;

  final mergedCategories = <String>{
    ...task.categories,
    if (categoryLabel != null && categoryLabel.isNotEmpty) categoryLabel,
  }.toList();

  final autoTags = <String>{
    ...task.autoTags,
    ...metadata.matchedKeywords.where((item) => item.trim().isNotEmpty),
  }.toList();

  return task.copyWith(
    kind: metadata.entryKind,
    categoryId: metadata.categoryId,
    category: categoryLabel ?? task.category,
    categories: mergedCategories,
    horizon: metadata.timeHorizon,
    energy: metadata.energyLevel,
    inferredPriority: metadata.priorityLevel,
    classificationConfidence: metadata.confidenceLevel,
    autoTags: autoTags,
    classificationMetadata: metadata,
  );
}

CategoryConfig? categoryForTask(
  List<CategoryConfig> categories,
  Task task,
) {
  final categoryId = task.categoryId;
  if (categoryId != null) {
    final match = _findCategory(categories, categoryId);
    if (match != null) return match;
  }

  final categoryLabel = task.category?.trim().toLowerCase();
  if (categoryLabel == null || categoryLabel.isEmpty) return null;
  for (final category in categories) {
    if (category.name.trim().toLowerCase() == categoryLabel) {
      return category;
    }
  }
  return null;
}

CategoryConfig? _findCategory(List<CategoryConfig> categories, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}
