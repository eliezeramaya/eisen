import 'package:eisen/features/classification/data/models/model_utils.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/alias_type.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class VocabularyAliasModel extends VocabularyAlias {
  const VocabularyAliasModel({
    required super.id,
    required super.term,
    required super.normalizedTerm,
    super.type,
    super.mappedCategoryId,
    super.mappedKind,
    super.aliases,
    super.timeHorizon,
    super.energyLevel,
    super.priorityLevel,
    super.suggestedQuadrant,
    super.enabled,
    super.createdAt,
    super.updatedAt,
  });

  factory VocabularyAliasModel.fromEntity(VocabularyAlias entity) {
    return VocabularyAliasModel(
      id: entity.id,
      term: entity.term,
      normalizedTerm: entity.normalizedTerm,
      type: entity.type,
      aliases: entity.aliases,
      mappedCategoryId: entity.mappedCategoryId,
      mappedKind: entity.mappedKind,
      timeHorizon: entity.timeHorizon,
      energyLevel: entity.energyLevel,
      priorityLevel: entity.priorityLevel,
      suggestedQuadrant: entity.suggestedQuadrant,
      enabled: entity.enabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory VocabularyAliasModel.fromJson(Map<String, Object?> json) {
    final legacyTerm = json['canonicalValue'] as String?;
    return VocabularyAliasModel(
      id: json['id'] as String,
      term: json['term'] as String? ?? legacyTerm ?? '',
      normalizedTerm: json['normalizedTerm'] as String? ??
          (json['term'] as String? ?? legacyTerm ?? '').toLowerCase(),
      type: enumFromName(
            AliasType.values,
            json['type'] as String?,
            null,
          ) ??
          AliasType.generic,
      aliases: (json['aliases'] as List?)?.cast<String>() ??
          (legacyTerm == null ? const <String>[] : <String>[legacyTerm]),
      mappedCategoryId:
          json['mappedCategoryId'] as String? ?? json['categoryId'] as String?,
      mappedKind: enumFromName(
        EntryKind.values,
        json['mappedKind'] as String? ?? json['entryKind'] as String?,
        null,
      ),
      timeHorizon: enumFromName(
        TimeHorizon.values,
        json['timeHorizon'] as String?,
        null,
      ),
      energyLevel: enumFromName(
        EnergyLevel.values,
        json['energyLevel'] as String?,
        null,
      ),
      priorityLevel: enumFromName(
        PriorityLevel.values,
        json['priorityLevel'] as String?,
        null,
      ),
      suggestedQuadrant: enumFromName(
        Quadrant.values,
        json['suggestedQuadrant'] as String?,
        null,
      ),
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
        'term': term,
        'normalizedTerm': normalizedTerm,
        'type': type.name,
        'aliases': aliases,
        'mappedCategoryId': mappedCategoryId,
        'mappedKind': mappedKind?.name,
        'timeHorizon': timeHorizon?.name,
        'energyLevel': energyLevel?.name,
        'priorityLevel': priorityLevel?.name,
        'suggestedQuadrant': suggestedQuadrant?.name,
        'enabled': enabled,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
