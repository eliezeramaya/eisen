import 'package:eisen/features/classification/domain/entities/category_config.dart';

class CategoryConfigModel extends CategoryConfig {
  const CategoryConfigModel({
    required super.id,
    required super.name,
    required super.colorValue,
    required super.iconKey,
    super.description,
    super.keywords,
    super.aliases,
    super.parentCategoryId,
    super.isHidden,
    super.isArchived,
    super.sortOrder,
    super.isSystem,
    super.createdAt,
    super.updatedAt,
  });

  factory CategoryConfigModel.fromEntity(CategoryConfig entity) {
    return CategoryConfigModel(
      id: entity.id,
      name: entity.name,
      colorValue: entity.colorValue,
      iconKey: entity.iconKey,
      description: entity.description,
      keywords: entity.keywords,
      aliases: entity.aliases,
      parentCategoryId: entity.parentCategoryId,
      isHidden: entity.isHidden,
      isArchived: entity.isArchived,
      sortOrder: entity.sortOrder,
      isSystem: entity.isSystem,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory CategoryConfigModel.fromJson(Map<String, Object?> json) {
    final legacyEnabled = json['isEnabled'] as bool?;
    return CategoryConfigModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['label'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF0891B2,
      iconKey:
          json['iconKey'] as String? ?? json['iconName'] as String? ?? 'label',
      description: json['description'] as String? ?? '',
      keywords: (json['keywords'] as List?)?.cast<String>() ?? const [],
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      parentCategoryId: json['parentCategoryId'] as String?,
      isHidden: json['isHidden'] as bool? ??
          (legacyEnabled == null ? false : !legacyEnabled),
      isArchived: json['isArchived'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isSystem:
          json['isSystem'] as bool? ?? json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'description': description,
        'keywords': keywords,
        'aliases': aliases,
        'parentCategoryId': parentCategoryId,
        'isHidden': isHidden,
        'isArchived': isArchived,
        'sortOrder': sortOrder,
        'isSystem': isSystem,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
