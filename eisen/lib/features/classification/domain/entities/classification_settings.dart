import 'package:eisen/features/classification/domain/enums/automation_mode.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationSettings {
  const ClassificationSettings({
    this.autoClassifyEnabled = true,
    this.automationMode = AutomationMode.assisted,
    this.learnFromCorrections = true,
    this.suggestRules = true,
    this.detectHabits = true,
    this.useVocabularyAliases = true,
    this.colorByCategory = true,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
    this.allowGroupingByCategory = true,
    this.allowGroupingByKind = true,
    this.allowGroupingByHorizon = true,
    this.allowGroupingByEnergy = true,
    this.defaultCategoryId,
    this.reviewLowConfidenceEntries = true,
    this.lowConfidenceThreshold = 0.35,
    this.mediumConfidenceThreshold = 0.65,
    this.autoApplyHighConfidence = true,
    this.showEnergyIndicator = true,
    this.showTimeHorizonChip = true,
    this.classifierVersion = 'local-heuristic-v3',
    this.updatedAt,
  });

  final bool autoClassifyEnabled;
  final AutomationMode automationMode;
  final bool learnFromCorrections;
  final bool suggestRules;
  final bool detectHabits;
  final bool useVocabularyAliases;
  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final bool allowGroupingByCategory;
  final bool allowGroupingByKind;
  final bool allowGroupingByHorizon;
  final bool allowGroupingByEnergy;
  final String? defaultCategoryId;
  final bool reviewLowConfidenceEntries;
  final double lowConfidenceThreshold;
  final double mediumConfidenceThreshold;
  final bool autoApplyHighConfidence;
  final bool showEnergyIndicator;
  final bool showTimeHorizonChip;
  final String classifierVersion;
  final DateTime? updatedAt;

  bool get showConfidenceBadge => showConfidenceIndicators;
  bool get enableRuleSuggestions => suggestRules;
  bool get enableAliasLearning => useVocabularyAliases;

  ClassificationSettings copyWith({
    bool? autoClassifyEnabled,
    AutomationMode? automationMode,
    bool? learnFromCorrections,
    bool? suggestRules,
    bool? detectHabits,
    bool? useVocabularyAliases,
    bool? colorByCategory,
    bool? showConfidenceIndicators,
    bool? showAutoTags,
    bool? allowGroupingByCategory,
    bool? allowGroupingByKind,
    bool? allowGroupingByHorizon,
    bool? allowGroupingByEnergy,
    String? defaultCategoryId,
    bool? reviewLowConfidenceEntries,
    double? lowConfidenceThreshold,
    double? mediumConfidenceThreshold,
    bool? autoApplyHighConfidence,
    bool? showEnergyIndicator,
    bool? showTimeHorizonChip,
    String? classifierVersion,
    DateTime? updatedAt,
  }) {
    return ClassificationSettings(
      autoClassifyEnabled: autoClassifyEnabled ?? this.autoClassifyEnabled,
      automationMode: automationMode ?? this.automationMode,
      learnFromCorrections: learnFromCorrections ?? this.learnFromCorrections,
      suggestRules: suggestRules ?? this.suggestRules,
      detectHabits: detectHabits ?? this.detectHabits,
      useVocabularyAliases: useVocabularyAliases ?? this.useVocabularyAliases,
      colorByCategory: colorByCategory ?? this.colorByCategory,
      showConfidenceIndicators:
          showConfidenceIndicators ?? this.showConfidenceIndicators,
      showAutoTags: showAutoTags ?? this.showAutoTags,
      allowGroupingByCategory:
          allowGroupingByCategory ?? this.allowGroupingByCategory,
      allowGroupingByKind: allowGroupingByKind ?? this.allowGroupingByKind,
      allowGroupingByHorizon:
          allowGroupingByHorizon ?? this.allowGroupingByHorizon,
      allowGroupingByEnergy:
          allowGroupingByEnergy ?? this.allowGroupingByEnergy,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      reviewLowConfidenceEntries:
          reviewLowConfidenceEntries ?? this.reviewLowConfidenceEntries,
      lowConfidenceThreshold:
          lowConfidenceThreshold ?? this.lowConfidenceThreshold,
      mediumConfidenceThreshold:
          mediumConfidenceThreshold ?? this.mediumConfidenceThreshold,
      autoApplyHighConfidence:
          autoApplyHighConfidence ?? this.autoApplyHighConfidence,
      showEnergyIndicator: showEnergyIndicator ?? this.showEnergyIndicator,
      showTimeHorizonChip: showTimeHorizonChip ?? this.showTimeHorizonChip,
      classifierVersion: classifierVersion ?? this.classifierVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ClassificationSettingsDefaults {
  const ClassificationSettingsDefaults._();

  static const value = ClassificationSettings();
}
