import 'package:eisen/features/classification/data/models/model_utils.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class ClassificationMetadataModel extends ClassificationMetadata {
  ClassificationMetadataModel({
    super.inputText,
    super.normalizedText,
    super.categoryId,
    required super.entryKind,
    required super.timeHorizon,
    required super.energyLevel,
    required super.priorityLevel,
    required super.confidenceScore,
    required super.confidenceLevel,
    super.classifierVersion,
    super.source,
    super.matchedRuleId,
    super.matchedAliasId,
    super.matchedKeywords,
    super.signals,
    super.appliedRuleIds,
    super.suggestedCategoryId,
    super.confidenceReason,
    super.reasons,
    super.suggestedQuadrant,
    super.urgencyScore,
    super.importanceScore,
    super.quadrantReason,
    super.isAutoClassified,
    super.wasUserCorrected,
    super.isUserConfirmed,
    super.classifiedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory ClassificationMetadataModel.fromEntity(
    ClassificationMetadata entity,
  ) {
    return ClassificationMetadataModel(
      inputText: entity.inputText,
      normalizedText: entity.normalizedText,
      categoryId: entity.categoryId,
      entryKind: entity.entryKind,
      timeHorizon: entity.timeHorizon,
      energyLevel: entity.energyLevel,
      priorityLevel: entity.priorityLevel,
      confidenceScore: entity.confidenceScore,
      confidenceLevel: entity.confidenceLevel,
      classifierVersion: entity.classifierVersion,
      source: entity.source,
      matchedRuleId: entity.matchedRuleId,
      matchedAliasId: entity.matchedAliasId,
      matchedKeywords: entity.matchedKeywords,
      signals: entity.signals,
      appliedRuleIds: entity.appliedRuleIds,
      suggestedCategoryId: entity.suggestedCategoryId,
      confidenceReason: entity.confidenceReason,
      reasons: entity.reasons,
      suggestedQuadrant: entity.suggestedQuadrant,
      urgencyScore: entity.urgencyScore,
      importanceScore: entity.importanceScore,
      quadrantReason: entity.quadrantReason,
      isAutoClassified: entity.isAutoClassified,
      wasUserCorrected: entity.wasUserCorrected,
      isUserConfirmed: entity.isUserConfirmed,
      classifiedAt: entity.classifiedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ClassificationMetadataModel.fromJson(Map<String, Object?> json) {
    final legacyRuleIds =
        (json['matchedRuleIds'] as List?)?.cast<String>() ?? const <String>[];
    final legacyReasons =
        (json['reasons'] as List?)?.cast<String>() ?? const <String>[];
    return ClassificationMetadataModel(
      inputText: json['inputText'] as String? ?? '',
      normalizedText: json['normalizedText'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      entryKind: enumFromName(
        EntryKind.values,
        json['entryKind'] as String?,
        EntryKind.task,
      )!,
      timeHorizon: enumFromName(
        TimeHorizon.values,
        json['timeHorizon'] as String?,
        TimeHorizon.thisWeek,
      )!,
      energyLevel: enumFromName(
        EnergyLevel.values,
        json['energyLevel'] as String?,
        EnergyLevel.medium,
      )!,
      priorityLevel: enumFromName(
        PriorityLevel.values,
        json['priorityLevel'] as String?,
        PriorityLevel.medium,
      )!,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: enumFromName(
        ConfidenceLevel.values,
        json['confidenceLevel'] as String?,
        ConfidenceLevel.low,
      )!,
      classifierVersion: json['classifierVersion'] as String? ?? 'heuristic-v1',
      source: enumFromName(
            ClassificationSource.values,
            json['source'] as String?,
            null,
          ) ??
          ((json['wasUserCorrected'] as bool? ?? false)
              ? ClassificationSource.userCorrection
              : ClassificationSource.fallback),
      matchedRuleId: json['matchedRuleId'] as String? ??
          (legacyRuleIds.isEmpty ? null : legacyRuleIds.first),
      matchedAliasId: json['matchedAliasId'] as String?,
      matchedKeywords:
          (json['matchedKeywords'] as List?)?.cast<String>() ?? const [],
      signals: (json['signals'] as List?)?.cast<String>() ?? const [],
      appliedRuleIds:
          (json['appliedRuleIds'] as List?)?.cast<String>() ?? legacyRuleIds,
      suggestedCategoryId: json['suggestedCategoryId'] as String?,
      confidenceReason:
          json['confidenceReason'] as String? ?? legacyReasons.join(' '),
      reasons: legacyReasons,
      suggestedQuadrant: enumFromName(
        Quadrant.values,
        json['suggestedQuadrant'] as String?,
        null,
      ),
      urgencyScore: (json['urgencyScore'] as num?)?.toDouble() ?? 0.0,
      importanceScore: (json['importanceScore'] as num?)?.toDouble() ?? 0.0,
      quadrantReason: json['quadrantReason'] as String? ?? '',
      isAutoClassified: json['isAutoClassified'] as bool? ?? true,
      wasUserCorrected: json['wasUserCorrected'] as bool? ??
          json['isUserConfirmed'] as bool? ??
          false,
      isUserConfirmed: json['isUserConfirmed'] as bool? ?? false,
      classifiedAt: json['classifiedAt'] != null
          ? DateTime.tryParse(json['classifiedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'inputText': inputText,
        'normalizedText': normalizedText,
        'categoryId': categoryId,
        'entryKind': entryKind.name,
        'timeHorizon': timeHorizon.name,
        'energyLevel': energyLevel.name,
        'priorityLevel': priorityLevel.name,
        'confidenceScore': confidenceScore,
        'confidenceLevel': confidenceLevel.name,
        'classifierVersion': classifierVersion,
        'source': source.name,
        'matchedRuleId': matchedRuleId,
        'matchedAliasId': matchedAliasId,
        'matchedKeywords': matchedKeywords,
        'signals': signals,
        'appliedRuleIds': appliedRuleIds,
        'suggestedCategoryId': suggestedCategoryId,
        'confidenceReason': confidenceReason,
        'reasons': reasons,
        'suggestedQuadrant': suggestedQuadrant?.name,
        'urgencyScore': urgencyScore,
        'importanceScore': importanceScore,
        'quadrantReason': quadrantReason,
        'isAutoClassified': isAutoClassified,
        'wasUserCorrected': wasUserCorrected,
        'isUserConfirmed': isUserConfirmed,
        'classifiedAt': classifiedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
