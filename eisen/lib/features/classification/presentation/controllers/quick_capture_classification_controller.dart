import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class QuickCaptureClassificationState {
  const QuickCaptureClassificationState({
    this.inputText = '',
    this.preview,
    this.isLoading = false,
  });

  final String inputText;
  final ClassificationMetadata? preview;
  final bool isLoading;

  QuickCaptureClassificationState copyWith({
    String? inputText,
    ClassificationMetadata? preview,
    bool? isLoading,
    bool clearPreview = false,
  }) {
    return QuickCaptureClassificationState(
      inputText: inputText ?? this.inputText,
      preview: clearPreview ? null : (preview ?? this.preview),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class QuickCaptureClassificationController
    extends Notifier<QuickCaptureClassificationState> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  QuickCaptureClassificationState build() {
    return const QuickCaptureClassificationState();
  }

  void setInput(String value) {
    state = state.copyWith(
      inputText: value,
      clearPreview: value.trim().isEmpty,
    );
  }

  Future<void> classifyNow() async {
    await classifyInput(state.inputText);
  }

  Future<ClassificationMetadata?> classifyInput(String rawText) async {
    setInput(rawText);
    final input = state.inputText.trim();
    if (input.isEmpty) {
      state = state.copyWith(clearPreview: true);
      return null;
    }

    state = state.copyWith(isLoading: true);
    final preview = await _repository.previewClassification(input: input);
    state = state.copyWith(
      preview: preview,
      isLoading: false,
    );
    return preview;
  }

  void applyOverride(ClassificationMetadata metadata) {
    state = state.copyWith(preview: metadata, isLoading: false);
  }

  Future<void> applyUserCorrection({
    required ClassificationMetadata corrected,
    ClassificationMetadata? original,
    bool rememberDecision = false,
    String? note,
  }) async {
    final source = original ?? state.preview ?? corrected;
    applyOverride(corrected);
    if (!rememberDecision) return;

    final event = ClassificationCorrectionEvent(
      id: 'correction-${DateTime.now().microsecondsSinceEpoch}',
      rawText: corrected.inputText,
      originalCategoryId: source.categoryId,
      correctedCategoryId: corrected.categoryId,
      originalKind: source.entryKind,
      correctedKind: corrected.entryKind,
      originalHorizon: source.timeHorizon,
      correctedHorizon: corrected.timeHorizon,
      originalEnergy: source.energyLevel,
      correctedEnergy: corrected.energyLevel,
      confidenceBefore: source.confidenceLevel,
      source: CorrectionSource.quickCapture,
      detectedKeyword: corrected.matchedKeywords.isEmpty
          ? null
          : corrected.matchedKeywords.first,
      originalClassification: source,
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
  }

  Future<String> persistTaskWithClassification({
    required String rawText,
    Quadrant quadrant = Quadrant.q2,
    int priority = 5,
    int minutes = 30,
    String? manualCategoryLabel,
  }) async {
    final metadata = state.preview?.inputText.trim() == rawText.trim()
        ? state.preview
        : await classifyInput(rawText);
    final matrixController = ref.read(matrixControllerProvider.notifier);
    final id = matrixController.createTask(
      quadrant: quadrant,
      title: rawText.trim(),
    );
    final categories = ref.read(categoryConfigControllerProvider);
    matrixController.updateTask(id, (task) {
      var updated = task.copyWith(priority: priority, minutes: minutes);
      if (metadata != null) {
        updated = applyClassificationToTask(
          task: updated,
          metadata: metadata,
          categories: categories,
        );
      }
      final category = manualCategoryLabel?.trim();
      if (category != null && category.isNotEmpty) {
        updated = updated.copyWith(
          category: category,
          categories: <String>{...updated.categories, category}.toList(),
        );
      }
      return updated;
    });
    return id;
  }
}

final quickCaptureClassificationControllerProvider = NotifierProvider<
    QuickCaptureClassificationController, QuickCaptureClassificationState>(
  QuickCaptureClassificationController.new,
);
