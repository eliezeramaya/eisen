import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:eisen/features/classification/domain/services/classification_correction_builder.dart';
import 'package:eisen/features/classification/domain/services/quadrant_learning_engine.dart';
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
    this.learningProfile = QuadrantLearningProfile.neutral,
    this.isLoading = false,
  });

  final List<ClassificationCorrectionEvent> corrections;
  final List<RuleSuggestion> suggestions;
  final QuadrantLearningProfile learningProfile;
  final bool isLoading;

  ClassificationReviewState copyWith({
    List<ClassificationCorrectionEvent>? corrections,
    List<RuleSuggestion>? suggestions,
    QuadrantLearningProfile? learningProfile,
    bool? isLoading,
  }) {
    return ClassificationReviewState(
      corrections: corrections ?? this.corrections,
      suggestions: suggestions ?? this.suggestions,
      learningProfile: learningProfile ?? this.learningProfile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ClassificationReviewController
    extends Notifier<ClassificationReviewState> {
  late final _repository = ref.read(classificationRepositoryProvider);
  final _learningEngine = const QuadrantLearningEngine();

  @override
  ClassificationReviewState build() {
    _load();
    return const ClassificationReviewState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final corrections = await _repository.loadCorrections();
    final suggestions = await _repository.suggestRules();
    final learningProfile = _learningEngine.learnFromCorrections(corrections);
    state = ClassificationReviewState(
      corrections: corrections,
      suggestions: suggestions,
      learningProfile: learningProfile,
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
    String? taskId,
    String? note,
  }) async {
    final event = buildClassificationCorrectionEvent(
      original: original,
      corrected: corrected,
      inputText: inputText,
      source: CorrectionSource.reviewCenter,
      taskId: taskId,
      correctionNote: note,
    );
    await _repository.recordCorrection(event);
    ref.invalidate(quadrantLearningProfileProvider);
    await _load();
  }
}

final classificationReviewControllerProvider =
    NotifierProvider<ClassificationReviewController, ClassificationReviewState>(
  ClassificationReviewController.new,
);
