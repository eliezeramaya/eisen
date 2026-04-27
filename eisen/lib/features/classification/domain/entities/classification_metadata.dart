import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationMetadata {
  ClassificationMetadata({
    this.inputText = '',
    this.normalizedText = '',
    this.categoryId,
    required this.entryKind,
    required this.timeHorizon,
    required this.energyLevel,
    required this.priorityLevel,
    required this.confidenceScore,
    required this.confidenceLevel,
    this.classifierVersion = 'heuristic-v1',
    this.source = ClassificationSource.fallback,
    this.matchedRuleId,
    this.matchedAliasId,
    this.matchedKeywords = const <String>[],
    this.signals = const <String>[],
    this.appliedRuleIds = const <String>[],
    this.suggestedCategoryId,
    this.confidenceReason = '',
    this.reasons = const <String>[],
    this.isAutoClassified = true,
    this.wasUserCorrected = false,
    this.isUserConfirmed = false,
    DateTime? classifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : classifiedAt = classifiedAt ?? updatedAt ?? createdAt ?? DateTime.now(),
        createdAt = createdAt ?? classifiedAt ?? updatedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? classifiedAt ?? createdAt ?? DateTime.now();

  final String inputText;
  final String normalizedText;
  final String? categoryId;
  final EntryKind entryKind;
  final TimeHorizon timeHorizon;
  final EnergyLevel energyLevel;
  final PriorityLevel priorityLevel;
  final double confidenceScore;
  final ConfidenceLevel confidenceLevel;
  final String classifierVersion;
  final ClassificationSource source;
  final String? matchedRuleId;
  final String? matchedAliasId;
  final List<String> matchedKeywords;
  final List<String> signals;
  final List<String> appliedRuleIds;
  final String? suggestedCategoryId;
  final String confidenceReason;
  final List<String> reasons;
  final bool isAutoClassified;
  final bool wasUserCorrected;
  final bool isUserConfirmed;
  final DateTime classifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get matchedRuleIds => appliedRuleIds.isNotEmpty
      ? appliedRuleIds
      : (matchedRuleId == null ? const <String>[] : <String>[matchedRuleId!]);

  ClassificationMetadata copyWith({
    String? inputText,
    String? normalizedText,
    String? categoryId,
    EntryKind? entryKind,
    TimeHorizon? timeHorizon,
    EnergyLevel? energyLevel,
    PriorityLevel? priorityLevel,
    double? confidenceScore,
    ConfidenceLevel? confidenceLevel,
    String? classifierVersion,
    ClassificationSource? source,
    String? matchedRuleId,
    String? matchedAliasId,
    List<String>? matchedKeywords,
    List<String>? signals,
    List<String>? appliedRuleIds,
    String? suggestedCategoryId,
    String? confidenceReason,
    List<String>? reasons,
    bool? isAutoClassified,
    bool? wasUserCorrected,
    bool? isUserConfirmed,
    DateTime? classifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassificationMetadata(
      inputText: inputText ?? this.inputText,
      normalizedText: normalizedText ?? this.normalizedText,
      categoryId: categoryId ?? this.categoryId,
      entryKind: entryKind ?? this.entryKind,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      energyLevel: energyLevel ?? this.energyLevel,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      classifierVersion: classifierVersion ?? this.classifierVersion,
      source: source ?? this.source,
      matchedRuleId: matchedRuleId ?? this.matchedRuleId,
      matchedAliasId: matchedAliasId ?? this.matchedAliasId,
      matchedKeywords: matchedKeywords ?? this.matchedKeywords,
      signals: signals ?? this.signals,
      appliedRuleIds: appliedRuleIds ?? this.appliedRuleIds,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      confidenceReason: confidenceReason ?? this.confidenceReason,
      reasons: reasons ?? this.reasons,
      isAutoClassified: isAutoClassified ?? this.isAutoClassified,
      wasUserCorrected: wasUserCorrected ?? this.wasUserCorrected,
      isUserConfirmed: isUserConfirmed ?? this.isUserConfirmed,
      classifiedAt: classifiedAt ?? this.classifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
