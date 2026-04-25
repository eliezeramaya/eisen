import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationRule {
  const ClassificationRule({
    required this.id,
    required this.name,
    required this.keywords,
    required this.matchType,
    this.targetCategoryId,
    this.targetKind,
    this.targetHorizon,
    this.targetEnergy,
    this.targetPriority,
    this.targetTags = const <String>[],
    this.description,
    this.priority = RulePriority.normal,
    this.scoreBoost = 0.2,
    this.isUserCreated = false,
    this.enabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> keywords;
  final RuleMatchType matchType;
  final String? targetCategoryId;
  final EntryKind? targetKind;
  final TimeHorizon? targetHorizon;
  final EnergyLevel? targetEnergy;
  final PriorityLevel? targetPriority;
  final List<String> targetTags;
  final String? description;
  final RulePriority priority;
  final double scoreBoost;
  final bool isUserCreated;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get pattern => keywords.isEmpty ? '' : keywords.first;
  String? get categoryId => targetCategoryId;
  EntryKind? get entryKind => targetKind;
  TimeHorizon? get timeHorizon => targetHorizon;
  EnergyLevel? get energyLevel => targetEnergy;
  PriorityLevel? get priorityLevel => targetPriority;
  bool get isEnabled => enabled;

  ClassificationRule copyWith({
    String? id,
    String? name,
    List<String>? keywords,
    RuleMatchType? matchType,
    String? targetCategoryId,
    EntryKind? targetKind,
    TimeHorizon? targetHorizon,
    EnergyLevel? targetEnergy,
    PriorityLevel? targetPriority,
    List<String>? targetTags,
    String? description,
    RulePriority? priority,
    double? scoreBoost,
    bool? isUserCreated,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassificationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      keywords: keywords ?? this.keywords,
      matchType: matchType ?? this.matchType,
      targetCategoryId: targetCategoryId ?? this.targetCategoryId,
      targetKind: targetKind ?? this.targetKind,
      targetHorizon: targetHorizon ?? this.targetHorizon,
      targetEnergy: targetEnergy ?? this.targetEnergy,
      targetPriority: targetPriority ?? this.targetPriority,
      targetTags: targetTags ?? this.targetTags,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      scoreBoost: scoreBoost ?? this.scoreBoost,
      isUserCreated: isUserCreated ?? this.isUserCreated,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
