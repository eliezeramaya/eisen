import 'package:eisen/features/classification/data/models/model_utils.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';

class ClassificationRuleModel extends ClassificationRule {
  const ClassificationRuleModel({
    required super.id,
    required super.name,
    required super.keywords,
    required super.matchType,
    super.targetCategoryId,
    super.targetKind,
    super.targetHorizon,
    super.targetEnergy,
    super.targetPriority,
    super.targetTags,
    super.description,
    super.priority,
    super.scoreBoost,
    super.isUserCreated,
    super.enabled,
    super.createdAt,
    super.updatedAt,
  });

  factory ClassificationRuleModel.fromEntity(ClassificationRule entity) {
    return ClassificationRuleModel(
      id: entity.id,
      name: entity.name,
      keywords: entity.keywords,
      matchType: entity.matchType,
      targetCategoryId: entity.targetCategoryId,
      targetKind: entity.targetKind,
      targetHorizon: entity.targetHorizon,
      targetEnergy: entity.targetEnergy,
      targetPriority: entity.targetPriority,
      targetTags: entity.targetTags,
      description: entity.description,
      priority: entity.priority,
      scoreBoost: entity.scoreBoost,
      isUserCreated: entity.isUserCreated,
      enabled: entity.enabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ClassificationRuleModel.fromJson(Map<String, Object?> json) {
    final legacyPattern = json['pattern'] as String?;
    return ClassificationRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      keywords: (json['keywords'] as List?)?.cast<String>() ??
          (legacyPattern == null ? const <String>[] : <String>[legacyPattern]),
      matchType: enumFromName(
        RuleMatchType.values,
        json['matchType'] as String?,
        RuleMatchType.contains,
      )!,
      targetCategoryId:
          json['targetCategoryId'] as String? ?? json['categoryId'] as String?,
      targetKind: enumFromName(
        EntryKind.values,
        json['targetKind'] as String? ?? json['entryKind'] as String?,
        null,
      ),
      targetHorizon: enumFromName(
        TimeHorizon.values,
        json['targetHorizon'] as String? ?? json['timeHorizon'] as String?,
        null,
      ),
      targetEnergy: enumFromName(
        EnergyLevel.values,
        json['targetEnergy'] as String? ?? json['energyLevel'] as String?,
        null,
      ),
      targetPriority: enumFromName(
        PriorityLevel.values,
        json['targetPriority'] as String? ?? json['priorityLevel'] as String?,
        null,
      ),
      targetTags: (json['targetTags'] as List?)?.cast<String>() ?? const [],
      description: json['description'] as String?,
      priority: enumFromName(
        RulePriority.values,
        json['priority'] as String?,
        RulePriority.normal,
      )!,
      scoreBoost: (json['scoreBoost'] as num?)?.toDouble() ?? 0.2,
      isUserCreated: json['isUserCreated'] as bool? ??
          json['createdByUser'] as bool? ??
          false,
      enabled: json['enabled'] as bool? ?? json['isEnabled'] as bool? ?? true,
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
        'keywords': keywords,
        'matchType': matchType.name,
        'targetCategoryId': targetCategoryId,
        'targetKind': targetKind?.name,
        'targetHorizon': targetHorizon?.name,
        'targetEnergy': targetEnergy?.name,
        'targetPriority': targetPriority?.name,
        'targetTags': targetTags,
        'description': description,
        'priority': priority.name,
        'scoreBoost': scoreBoost,
        'isUserCreated': isUserCreated,
        'enabled': enabled,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
