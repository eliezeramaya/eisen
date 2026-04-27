import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';

ClassificationMetadata buildUserCorrectedMetadata(
  ClassificationMetadata metadata,
) {
  return metadata.copyWith(
    confidenceScore: 0.96,
    confidenceLevel: ConfidenceLevel.high,
    source: ClassificationSource.userCorrection,
    signals: <String>[
      ...metadata.signals,
      'user-correction',
    ],
    isUserConfirmed: true,
    wasUserCorrected: true,
    isAutoClassified: false,
    updatedAt: DateTime.now(),
  );
}

ClassificationCorrectionEvent buildClassificationCorrectionEvent({
  required ClassificationMetadata original,
  required ClassificationMetadata corrected,
  required String inputText,
  required CorrectionSource source,
  String? taskId,
  String? correctionNote,
}) {
  final extractedKeywords = <String>{
    ...original.matchedKeywords,
    ...corrected.matchedKeywords,
  }.where((item) => item.trim().isNotEmpty).toList(growable: false);

  return ClassificationCorrectionEvent(
    id: 'correction-${DateTime.now().microsecondsSinceEpoch}',
    taskId: taskId,
    rawText: inputText,
    originalCategoryId: original.categoryId,
    correctedCategoryId: corrected.categoryId,
    originalKind: original.entryKind,
    correctedKind: corrected.entryKind,
    originalHorizon: original.timeHorizon,
    correctedHorizon: corrected.timeHorizon,
    originalEnergy: original.energyLevel,
    correctedEnergy: corrected.energyLevel,
    originalQuadrant: original.suggestedQuadrant,
    correctedQuadrant: corrected.suggestedQuadrant,
    confidenceBefore: original.confidenceLevel,
    source: source,
    detectedKeyword: extractedKeywords.isEmpty ? null : extractedKeywords.first,
    extractedKeywords: extractedKeywords,
    dominantKeyword: extractedKeywords.isEmpty ? null : extractedKeywords.first,
    originalClassification: original,
    correctedClassification: buildUserCorrectedMetadata(corrected),
    createdAt: DateTime.now(),
    correctionNote: correctionNote,
  );
}
