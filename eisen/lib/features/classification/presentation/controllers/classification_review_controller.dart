import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ClassificationReviewState {
  const ClassificationReviewState({
    this.corrections = const <ClassificationCorrectionEvent>[],
    this.suggestions = const <RuleSuggestion>[],
    this.isLoading = false,
  });

  final List<ClassificationCorrectionEvent> corrections;
  final List<RuleSuggestion> suggestions;
  final bool isLoading;

  ClassificationReviewState copyWith({
    List<ClassificationCorrectionEvent>? corrections,
    List<RuleSuggestion>? suggestions,
    bool? isLoading,
  }) {
    return ClassificationReviewState(
      corrections: corrections ?? this.corrections,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ClassificationReviewController
    extends Notifier<ClassificationReviewState> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  ClassificationReviewState build() {
    _load();
    return const ClassificationReviewState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final corrections = await _repository.loadCorrections();
    final suggestions = await _repository.suggestRules();
    state = ClassificationReviewState(
      corrections: corrections,
      suggestions: suggestions,
      isLoading: false,
    );
  }

  Future<void> refresh() => _load();

  List<Task> getLowConfidenceTasks() {
    return ref
        .read(matrixTasksProvider)
        .where(
          (task) => task.classificationConfidence == ConfidenceLevel.low,
        )
        .toList(growable: false);
  }

  Future<List<RuleSuggestion>> getSuggestedRules() async {
    return _repository.suggestRules();
  }

  Future<void> approveSuggestion(RuleSuggestion suggestion) async {
    await ref.read(classificationRulesControllerProvider.notifier).createRule(
          suggestion.suggestedRule.copyWith(
            isUserCreated: true,
            updatedAt: DateTime.now(),
          ),
        );
    await _repository.updateRuleSuggestionStatus(
      suggestion.id,
      SuggestionStatus.accepted,
    );
    await _load();
  }

  Future<void> dismissSuggestion(String suggestionId) async {
    await _repository.updateRuleSuggestionStatus(
      suggestionId,
      SuggestionStatus.dismissed,
    );
    await _load();
  }

  Future<void> recordCorrection({
    required String inputText,
    required ClassificationMetadata original,
    required ClassificationMetadata corrected,
    String? note,
  }) async {
    final event = ClassificationCorrectionEvent(
      id: 'correction-${DateTime.now().microsecondsSinceEpoch}',
      rawText: inputText,
      originalCategoryId: original.categoryId,
      correctedCategoryId: corrected.categoryId,
      originalKind: original.entryKind,
      correctedKind: corrected.entryKind,
      originalHorizon: original.timeHorizon,
      correctedHorizon: corrected.timeHorizon,
      originalEnergy: original.energyLevel,
      correctedEnergy: corrected.energyLevel,
      confidenceBefore: original.confidenceLevel,
      source: CorrectionSource.reviewCenter,
      detectedKeyword: corrected.matchedKeywords.isEmpty
          ? null
          : corrected.matchedKeywords.first,
      originalClassification: original,
      correctedClassification: corrected.copyWith(
        confidenceScore: 0.96,
        confidenceLevel: ConfidenceLevel.high,
        source: ClassificationSource.userCorrection,
        signals: <String>[
          ...corrected.signals,
          'user-correction',
        ],
        isUserConfirmed: true,
        wasUserCorrected: true,
        isAutoClassified: false,
        updatedAt: DateTime.now(),
      ),
      createdAt: DateTime.now(),
      correctionNote: note,
    );
    await _repository.recordCorrection(event);
    await _load();
  }
}

final classificationReviewControllerProvider =
    NotifierProvider<ClassificationReviewController, ClassificationReviewState>(
  ClassificationReviewController.new,
);
