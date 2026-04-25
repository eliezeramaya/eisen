import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/classification/data/models/classification_metadata_model.dart';
import 'package:eisen/features/classification/data/models/model_utils.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/services/classification_engine.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

abstract class MatrixRepository {
  Future<List<Task>> load();
  Future<void> save(List<Task> tasks);
}

class LocalPrefsMatrixRepository implements MatrixRepository {
  LocalPrefsMatrixRepository(this.storage);
  final StoragePrefs storage;

  @override
  Future<List<Task>> load() async {
    final map = await storage.loadJson();
    final list = (map['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return list.map(_fromJson).toList();
  }

  @override
  Future<void> save(List<Task> tasks) async {
    final data = {
      'tasks': tasks.map(_toJson).toList(),
    };
    await storage.saveJson(data);
  }

  static Task _fromJson(Map<String, dynamic> j) {
    final parsedKind = enumFromName(
          EntryKind.values,
          j['kind'] as String?,
          EntryKind.task,
        ) ??
        EntryKind.task;
    final parsedCategoryId =
        j['categoryId'] as String? ?? j['category'] as String? ?? 'inbox';
    final parsedHorizon = enumFromName(
          TimeHorizon.values,
          j['horizon'] as String?,
          TimeHorizon.someday,
        ) ??
        TimeHorizon.someday;
    final parsedEnergy = enumFromName(
          EnergyLevel.values,
          j['energy'] as String?,
          EnergyLevel.medium,
        ) ??
        EnergyLevel.medium;
    final parsedPriority = enumFromName(
          PriorityLevel.values,
          j['inferredPriority'] as String?,
          PriorityLevel.medium,
        ) ??
        PriorityLevel.medium;
    final storedConfidence = enumFromName<ConfidenceLevel>(
      ConfidenceLevel.values,
      j['classificationConfidence'] as String?,
      null,
    );
    final rawMetadata = j['classificationMetadata'] is Map
        ? ClassificationMetadataModel.fromJson(
            (j['classificationMetadata'] as Map).cast<String, Object?>(),
          )
        : null;
    final wasCorrected = rawMetadata?.wasUserCorrected == true ||
        rawMetadata?.isUserConfirmed == true;
    final parsedConfidence = wasCorrected
        ? ConfidenceLevel.high
        : (storedConfidence ??
            rawMetadata?.confidenceLevel ??
            ConfidenceLevel.low);
    final now = DateTime.now();
    final migratedMetadata = rawMetadata?.copyWith(
          categoryId: rawMetadata.categoryId ?? parsedCategoryId,
          entryKind: rawMetadata.entryKind,
          timeHorizon: rawMetadata.timeHorizon,
          energyLevel: rawMetadata.energyLevel,
          priorityLevel: rawMetadata.priorityLevel,
          confidenceLevel:
              wasCorrected ? ConfidenceLevel.high : rawMetadata.confidenceLevel,
          confidenceScore: wasCorrected ? 0.98 : rawMetadata.confidenceScore,
          source: wasCorrected
              ? ClassificationSource.userCorrection
              : rawMetadata.source,
          updatedAt: now,
        ) ??
        ClassificationMetadataModel(
          inputText: j['title'] as String? ?? '',
          normalizedText: normalizeClassificationText(
            j['title'] as String? ?? '',
          ),
          categoryId: parsedCategoryId,
          entryKind: parsedKind,
          timeHorizon: parsedHorizon,
          energyLevel: parsedEnergy,
          priorityLevel: parsedPriority,
          confidenceScore: _confidenceScoreFor(parsedConfidence),
          confidenceLevel: parsedConfidence,
          classifierVersion: 'local-heuristic-v2',
          source: parsedCategoryId == 'inbox'
              ? ClassificationSource.fallback
              : ClassificationSource.heuristic,
          signals: const <String>['migrated-task'],
          reasons: const <String>[
            'Tarea migrada desde almacenamiento previo.',
          ],
          isAutoClassified: false,
          wasUserCorrected: false,
          isUserConfirmed: false,
          classifiedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    return Task(
      id: j['id'] as String,
      title: j['title'] as String,
      quadrant: Quadrant.values[j['quadrant'] as int],
      priority: j['priority'] as int,
      minutes: j['minutes'] as int,
      due: j['due'] != null ? DateTime.tryParse(j['due'] as String) : null,
      tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      categories: (j['categories'] as List?)?.cast<String>() ?? const [],
      notes: j['notes'] as String?,
      category: (j['category'] as String?) ??
          (parsedCategoryId == 'inbox' ? 'Inbox' : null),
      locationTag: j['locationTag'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      radiusMeters: (j['radiusMeters'] as num?)?.toDouble(),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'] as String)
          : null,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'] as String)
          : null,
      completedAt: j['completedAt'] != null
          ? DateTime.tryParse(j['completedAt'] as String)
          : null,
      kind: parsedKind,
      categoryId: parsedCategoryId,
      subcategoryId: j['subcategoryId'] as String?,
      groupId: j['groupId'] as String?,
      horizon: rawMetadata?.timeHorizon ?? parsedHorizon,
      energy: rawMetadata?.energyLevel ?? parsedEnergy,
      inferredPriority: rawMetadata?.priorityLevel ?? parsedPriority,
      classificationConfidence: parsedConfidence,
      autoTags: (j['autoTags'] as List?)?.cast<String>() ?? const [],
      classificationMetadata: migratedMetadata,
    );
  }

  static Map<String, Object?> _toJson(Task t) => {
        'id': t.id,
        'title': t.title,
        'quadrant': t.quadrant.index,
        'priority': t.priority,
        'minutes': t.minutes,
        'due': t.due?.toIso8601String(),
        'tags': t.tags,
        'categories': t.categories,
        'notes': t.notes,
        'category': t.category,
        'locationTag': t.locationTag,
        'latitude': t.latitude,
        'longitude': t.longitude,
        'radiusMeters': t.radiusMeters,
        'createdAt': t.createdAt?.toIso8601String(),
        'updatedAt': t.updatedAt?.toIso8601String(),
        'completedAt': t.completedAt?.toIso8601String(),
        'kind': t.kind.name,
        'categoryId': t.categoryId,
        'subcategoryId': t.subcategoryId,
        'groupId': t.groupId,
        'horizon': t.horizon?.name,
        'energy': t.energy?.name,
        'inferredPriority': t.inferredPriority?.name,
        'classificationConfidence': t.classificationConfidence?.name,
        'autoTags': t.autoTags,
        'classificationMetadata': t.classificationMetadata == null
            ? null
            : ClassificationMetadataModel.fromEntity(t.classificationMetadata!)
                .toJson(),
      };

  static double _confidenceScoreFor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 0.9;
      case ConfidenceLevel.medium:
        return 0.56;
      case ConfidenceLevel.low:
        return 0.24;
    }
  }
}
