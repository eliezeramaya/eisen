import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/correction_source.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationCorrectionEvent {
  const ClassificationCorrectionEvent({
    required this.id,
    required this.rawText,
    required this.originalCategoryId,
    required this.correctedCategoryId,
    required this.originalKind,
    required this.correctedKind,
    required this.originalHorizon,
    required this.correctedHorizon,
    required this.originalEnergy,
    required this.correctedEnergy,
    this.originalQuadrant,
    this.correctedQuadrant,
    required this.confidenceBefore,
    this.source = CorrectionSource.reviewCenter,
    required this.createdAt,
    this.taskId,
    this.detectedKeyword,
    this.extractedKeywords = const <String>[],
    this.dominantKeyword,
    this.originalClassification,
    this.correctedClassification,
    this.correctionNote,
  });

  final String id;
  final String? taskId;
  final String rawText;
  final String? originalCategoryId;
  final String? correctedCategoryId;
  final EntryKind? originalKind;
  final EntryKind? correctedKind;
  final TimeHorizon? originalHorizon;
  final TimeHorizon? correctedHorizon;
  final EnergyLevel? originalEnergy;
  final EnergyLevel? correctedEnergy;
  final Quadrant? originalQuadrant;
  final Quadrant? correctedQuadrant;
  final ConfidenceLevel confidenceBefore;
  final CorrectionSource source;
  final String? detectedKeyword;
  final List<String> extractedKeywords;
  final String? dominantKeyword;
  final DateTime createdAt;
  final ClassificationMetadata? originalClassification;
  final ClassificationMetadata? correctedClassification;
  final String? correctionNote;

  String get inputText => rawText;
  DateTime get occurredAt => createdAt;

  ClassificationCorrectionEvent copyWith({
    String? id,
    String? taskId,
    String? rawText,
    String? originalCategoryId,
    String? correctedCategoryId,
    EntryKind? originalKind,
    EntryKind? correctedKind,
    TimeHorizon? originalHorizon,
    TimeHorizon? correctedHorizon,
    EnergyLevel? originalEnergy,
    EnergyLevel? correctedEnergy,
    Quadrant? originalQuadrant,
    Quadrant? correctedQuadrant,
    ConfidenceLevel? confidenceBefore,
    CorrectionSource? source,
    String? detectedKeyword,
    List<String>? extractedKeywords,
    String? dominantKeyword,
    DateTime? createdAt,
    ClassificationMetadata? originalClassification,
    ClassificationMetadata? correctedClassification,
    String? correctionNote,
  }) {
    return ClassificationCorrectionEvent(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      rawText: rawText ?? this.rawText,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      correctedCategoryId: correctedCategoryId ?? this.correctedCategoryId,
      originalKind: originalKind ?? this.originalKind,
      correctedKind: correctedKind ?? this.correctedKind,
      originalHorizon: originalHorizon ?? this.originalHorizon,
      correctedHorizon: correctedHorizon ?? this.correctedHorizon,
      originalEnergy: originalEnergy ?? this.originalEnergy,
      correctedEnergy: correctedEnergy ?? this.correctedEnergy,
      originalQuadrant: originalQuadrant ?? this.originalQuadrant,
      correctedQuadrant: correctedQuadrant ?? this.correctedQuadrant,
      confidenceBefore: confidenceBefore ?? this.confidenceBefore,
      source: source ?? this.source,
      detectedKeyword: detectedKeyword ?? this.detectedKeyword,
      extractedKeywords: extractedKeywords ?? this.extractedKeywords,
      dominantKeyword: dominantKeyword ?? this.dominantKeyword,
      createdAt: createdAt ?? this.createdAt,
      originalClassification:
          originalClassification ?? this.originalClassification,
      correctedClassification:
          correctedClassification ?? this.correctedClassification,
      correctionNote: correctionNote ?? this.correctionNote,
    );
  }
}
