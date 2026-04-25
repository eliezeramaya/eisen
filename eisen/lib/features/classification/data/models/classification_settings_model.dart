import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/automation_mode.dart';

class ClassificationSettingsModel extends ClassificationSettings {
  const ClassificationSettingsModel({
    super.autoClassifyEnabled,
    super.automationMode,
    super.learnFromCorrections,
    super.suggestRules,
    super.detectHabits,
    super.useVocabularyAliases,
    super.colorByCategory,
    super.showConfidenceIndicators,
    super.showAutoTags,
    super.allowGroupingByCategory,
    super.allowGroupingByKind,
    super.allowGroupingByHorizon,
    super.allowGroupingByEnergy,
    super.defaultCategoryId,
    super.reviewLowConfidenceEntries,
    super.lowConfidenceThreshold,
    super.mediumConfidenceThreshold,
    super.autoApplyHighConfidence,
    super.showEnergyIndicator,
    super.showTimeHorizonChip,
    super.classifierVersion,
    super.updatedAt,
  });

  factory ClassificationSettingsModel.fromEntity(
    ClassificationSettings entity,
  ) {
    return ClassificationSettingsModel(
      autoClassifyEnabled: entity.autoClassifyEnabled,
      automationMode: entity.automationMode,
      learnFromCorrections: entity.learnFromCorrections,
      suggestRules: entity.suggestRules,
      detectHabits: entity.detectHabits,
      useVocabularyAliases: entity.useVocabularyAliases,
      colorByCategory: entity.colorByCategory,
      showConfidenceIndicators: entity.showConfidenceIndicators,
      showAutoTags: entity.showAutoTags,
      allowGroupingByCategory: entity.allowGroupingByCategory,
      allowGroupingByKind: entity.allowGroupingByKind,
      allowGroupingByHorizon: entity.allowGroupingByHorizon,
      allowGroupingByEnergy: entity.allowGroupingByEnergy,
      defaultCategoryId: entity.defaultCategoryId,
      reviewLowConfidenceEntries: entity.reviewLowConfidenceEntries,
      lowConfidenceThreshold: entity.lowConfidenceThreshold,
      mediumConfidenceThreshold: entity.mediumConfidenceThreshold,
      autoApplyHighConfidence: entity.autoApplyHighConfidence,
      showEnergyIndicator: entity.showEnergyIndicator,
      showTimeHorizonChip: entity.showTimeHorizonChip,
      classifierVersion: entity.classifierVersion,
      updatedAt: entity.updatedAt,
    );
  }

  factory ClassificationSettingsModel.fromJson(Map<String, Object?> json) {
    return ClassificationSettingsModel(
      autoClassifyEnabled: json['autoClassifyEnabled'] as bool? ?? true,
      automationMode: _automationModeFromName(
        json['automationMode'] as String?,
      ),
      learnFromCorrections: json['learnFromCorrections'] as bool? ?? true,
      suggestRules: json['suggestRules'] as bool? ??
          json['enableRuleSuggestions'] as bool? ??
          true,
      detectHabits: json['detectHabits'] as bool? ?? true,
      useVocabularyAliases: json['useVocabularyAliases'] as bool? ??
          json['enableAliasLearning'] as bool? ??
          true,
      colorByCategory: json['colorByCategory'] as bool? ?? true,
      showConfidenceIndicators: json['showConfidenceIndicators'] as bool? ??
          json['showConfidenceBadge'] as bool? ??
          true,
      showAutoTags: json['showAutoTags'] as bool? ?? true,
      allowGroupingByCategory: json['allowGroupingByCategory'] as bool? ?? true,
      allowGroupingByKind: json['allowGroupingByKind'] as bool? ?? true,
      allowGroupingByHorizon: json['allowGroupingByHorizon'] as bool? ?? true,
      allowGroupingByEnergy: json['allowGroupingByEnergy'] as bool? ?? true,
      defaultCategoryId: json['defaultCategoryId'] as String?,
      reviewLowConfidenceEntries:
          json['reviewLowConfidenceEntries'] as bool? ?? true,
      lowConfidenceThreshold:
          (json['lowConfidenceThreshold'] as num?)?.toDouble() ?? 0.35,
      mediumConfidenceThreshold:
          (json['mediumConfidenceThreshold'] as num?)?.toDouble() ?? 0.65,
      autoApplyHighConfidence: json['autoApplyHighConfidence'] as bool? ?? true,
      showEnergyIndicator: json['showEnergyIndicator'] as bool? ?? true,
      showTimeHorizonChip: json['showTimeHorizonChip'] as bool? ?? true,
      classifierVersion:
          json['classifierVersion'] as String? ?? 'local-heuristic-v2',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'autoClassifyEnabled': autoClassifyEnabled,
        'automationMode': automationMode.name,
        'learnFromCorrections': learnFromCorrections,
        'suggestRules': suggestRules,
        'detectHabits': detectHabits,
        'useVocabularyAliases': useVocabularyAliases,
        'colorByCategory': colorByCategory,
        'showConfidenceIndicators': showConfidenceIndicators,
        'showAutoTags': showAutoTags,
        'allowGroupingByCategory': allowGroupingByCategory,
        'allowGroupingByKind': allowGroupingByKind,
        'allowGroupingByHorizon': allowGroupingByHorizon,
        'allowGroupingByEnergy': allowGroupingByEnergy,
        'defaultCategoryId': defaultCategoryId,
        'reviewLowConfidenceEntries': reviewLowConfidenceEntries,
        'lowConfidenceThreshold': lowConfidenceThreshold,
        'mediumConfidenceThreshold': mediumConfidenceThreshold,
        'autoApplyHighConfidence': autoApplyHighConfidence,
        'showEnergyIndicator': showEnergyIndicator,
        'showTimeHorizonChip': showTimeHorizonChip,
        'classifierVersion': classifierVersion,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

AutomationMode _automationModeFromName(String? name) {
  for (final mode in AutomationMode.values) {
    if (mode.name == name) return mode;
  }
  return AutomationMode.assisted;
}
