import 'package:eisen/features/classification/data/models/classification_metadata_model.dart';
import 'package:eisen/features/classification/data/models/model_utils.dart';
import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';

class ClassificationCorrectionEventModel extends ClassificationCorrectionEvent {
  const ClassificationCorrectionEventModel({
    required super.id,
    required super.rawText,
    required super.originalCategoryId,
    required super.correctedCategoryId,
    required super.originalKind,
    required super.correctedKind,
    required super.originalHorizon,
    required super.correctedHorizon,
    required super.originalEnergy,
    required super.correctedEnergy,
    required super.confidenceBefore,
    required super.createdAt,
    super.source,
    super.taskId,
    super.detectedKeyword,
    super.originalClassification,
    super.correctedClassification,
    super.correctionNote,
  });

  factory ClassificationCorrectionEventModel.fromEntity(
    ClassificationCorrectionEvent entity,
  ) {
    return ClassificationCorrectionEventModel(
      id: entity.id,
      taskId: entity.taskId,
      rawText: entity.rawText,
      originalCategoryId: entity.originalCategoryId,
      correctedCategoryId: entity.correctedCategoryId,
      originalKind: entity.originalKind,
      correctedKind: entity.correctedKind,
      originalHorizon: entity.originalHorizon,
      correctedHorizon: entity.correctedHorizon,
      originalEnergy: entity.originalEnergy,
      correctedEnergy: entity.correctedEnergy,
      confidenceBefore: entity.confidenceBefore,
      source: entity.source,
      detectedKeyword: entity.detectedKeyword,
      originalClassification: entity.originalClassification,
      correctedClassification: entity.correctedClassification,
      createdAt: entity.createdAt,
      correctionNote: entity.correctionNote,
    );
  }

  factory ClassificationCorrectionEventModel.fromJson(
    Map<String, Object?> json,
  ) {
    return ClassificationCorrectionEventModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      rawText: json['rawText'] as String? ?? json['inputText'] as String? ?? '',
      originalCategoryId: json['originalCategoryId'] as String?,
      correctedCategoryId: json['correctedCategoryId'] as String?,
      originalKind: enumFromName(
        EntryKind.values,
        json['originalKind'] as String?,
        null,
      ),
      correctedKind: enumFromName(
        EntryKind.values,
        json['correctedKind'] as String?,
        null,
      ),
      originalHorizon: enumFromName(
        TimeHorizon.values,
        json['originalHorizon'] as String?,
        null,
      ),
      correctedHorizon: enumFromName(
        TimeHorizon.values,
        json['correctedHorizon'] as String?,
        null,
      ),
      originalEnergy: enumFromName(
        EnergyLevel.values,
        json['originalEnergy'] as String?,
        null,
      ),
      correctedEnergy: enumFromName(
        EnergyLevel.values,
        json['correctedEnergy'] as String?,
        null,
      ),
      confidenceBefore: enumFromName(
            ConfidenceLevel.values,
            json['confidenceBefore'] as String?,
            null,
          ) ??
          ConfidenceLevel.low,
      source: enumFromName(
            CorrectionSource.values,
            json['source'] as String?,
            null,
          ) ??
          CorrectionSource.reviewCenter,
      detectedKeyword: json['detectedKeyword'] as String?,
      originalClassification: json['originalClassification'] is Map
          ? ClassificationMetadataModel.fromJson(
              (json['originalClassification'] as Map).cast<String, Object?>(),
            )
          : null,
      correctedClassification: json['correctedClassification'] is Map
          ? ClassificationMetadataModel.fromJson(
              (json['correctedClassification'] as Map).cast<String, Object?>(),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : json['occurredAt'] != null
              ? DateTime.tryParse(json['occurredAt'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      correctionNote: json['correctionNote'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'taskId': taskId,
        'rawText': rawText,
        'originalCategoryId': originalCategoryId,
        'correctedCategoryId': correctedCategoryId,
        'originalKind': originalKind?.name,
        'correctedKind': correctedKind?.name,
        'originalHorizon': originalHorizon?.name,
        'correctedHorizon': correctedHorizon?.name,
        'originalEnergy': originalEnergy?.name,
        'correctedEnergy': correctedEnergy?.name,
        'confidenceBefore': confidenceBefore.name,
        'source': source.name,
        'detectedKeyword': detectedKeyword,
        'originalClassification': originalClassification == null
            ? null
            : ClassificationMetadataModel.fromEntity(originalClassification!)
                .toJson(),
        'correctedClassification': correctedClassification == null
            ? null
            : ClassificationMetadataModel.fromEntity(correctedClassification!)
                .toJson(),
        'createdAt': createdAt.toIso8601String(),
        'correctionNote': correctionNote,
      };
}
