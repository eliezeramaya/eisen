import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/automation_mode.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationSettingsController
    extends Notifier<ClassificationSettings> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  ClassificationSettings build() {
    _load();
    return ClassificationSettingsDefaults.value;
  }

  Future<void> _load() async {
    state = await _repository.loadSettings();
  }

  Future<void> updateAutomationMode(AutomationMode mode) async {
    await save(state.copyWith(automationMode: mode));
  }

  Future<void> updateVisualization({
    bool? colorByCategory,
    bool? showConfidenceIndicators,
    bool? showAutoTags,
    bool? allowGroupingByCategory,
    bool? allowGroupingByKind,
    bool? allowGroupingByHorizon,
    bool? allowGroupingByEnergy,
    bool? showEnergyIndicator,
    bool? showTimeHorizonChip,
  }) async {
    await save(
      state.copyWith(
        colorByCategory: colorByCategory,
        showConfidenceIndicators: showConfidenceIndicators,
        showAutoTags: showAutoTags,
        allowGroupingByCategory: allowGroupingByCategory,
        allowGroupingByKind: allowGroupingByKind,
        allowGroupingByHorizon: allowGroupingByHorizon,
        allowGroupingByEnergy: allowGroupingByEnergy,
        showEnergyIndicator: showEnergyIndicator,
        showTimeHorizonChip: showTimeHorizonChip,
      ),
    );
  }

  Future<void> updateLearning({
    bool? learnFromCorrections,
    bool? suggestRules,
    bool? useVocabularyAliases,
    bool? detectHabits,
  }) async {
    await save(
      state.copyWith(
        learnFromCorrections: learnFromCorrections,
        suggestRules: suggestRules,
        useVocabularyAliases: useVocabularyAliases,
        detectHabits: detectHabits,
      ),
    );
  }

  Future<void> updateThresholds({
    double? lowConfidenceThreshold,
    double? mediumConfidenceThreshold,
    bool? autoApplyHighConfidence,
  }) async {
    await save(
      state.copyWith(
        lowConfidenceThreshold: lowConfidenceThreshold,
        mediumConfidenceThreshold: mediumConfidenceThreshold,
        autoApplyHighConfidence: autoApplyHighConfidence,
      ),
    );
  }

  Future<void> reset() async {
    await save(ClassificationSettingsDefaults.value);
  }

  Future<void> save(ClassificationSettings settings) async {
    final next = settings.copyWith(updatedAt: DateTime.now());
    state = next;
    await _repository.saveSettings(next);
  }
}

final classificationSettingsControllerProvider =
    NotifierProvider<ClassificationSettingsController, ClassificationSettings>(
  ClassificationSettingsController.new,
);
