import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips all classification fields through save/load', () async {
    final repo = LocalPrefsMatrixRepository(StoragePrefs());
    final now = DateTime(2026, 5, 1, 12, 0, 0);

    final meta = ClassificationMetadata(
      inputText: 'Comprar pan',
      normalizedText: 'comprar pan',
      categoryId: 'errands',
      entryKind: EntryKind.shoppingItem,
      timeHorizon: TimeHorizon.thisWeek,
      energyLevel: EnergyLevel.low,
      priorityLevel: PriorityLevel.medium,
      confidenceScore: 0.9,
      confidenceLevel: ConfidenceLevel.high,
      classifierVersion: 'heuristic-v3',
      source: ClassificationSource.heuristic,
      matchedKeywords: ['comprar'],
      signals: ['shopping'],
      confidenceReason: 'Vocabulario de compras.',
      reasons: ['keyword: comprar'],
      isAutoClassified: true,
      wasUserCorrected: false,
      isUserConfirmed: false,
      classifiedAt: now,
      createdAt: now,
    );

    final task = Task(
      id: 'cls-1',
      title: 'Comprar pan',
      quadrant: Quadrant.q4,
      priority: 4,
      minutes: 15,
      kind: EntryKind.shoppingItem,
      categoryId: 'errands',
      category: 'Compras',
      horizon: TimeHorizon.thisWeek,
      energy: EnergyLevel.low,
      classificationConfidence: ConfidenceLevel.high,
      autoTags: ['compras', 'recado'],
      classificationMetadata: meta,
    );

    await repo.save([task]);
    final loaded = await repo.load();

    expect(loaded, hasLength(1));
    final t = loaded.first;

    // Basic fields
    expect(t.id, 'cls-1');
    expect(t.title, 'Comprar pan');

    // Classification enum fields
    expect(t.kind, EntryKind.shoppingItem);
    expect(t.categoryId, 'errands');
    expect(t.horizon, TimeHorizon.thisWeek);
    expect(t.energy, EnergyLevel.low);
    expect(t.classificationConfidence, ConfidenceLevel.high);

    // Auto-tags
    expect(t.autoTags, containsAll(['compras', 'recado']));

    // Metadata
    expect(t.classificationMetadata, isNotNull);
    final m = t.classificationMetadata!;
    expect(m.categoryId, 'errands');
    expect(m.entryKind, EntryKind.shoppingItem);
    expect(m.timeHorizon, TimeHorizon.thisWeek);
    expect(m.energyLevel, EnergyLevel.low);
    expect(m.confidenceLevel, ConfidenceLevel.high);
    expect(m.classifierVersion, 'heuristic-v3');
    expect(m.source, ClassificationSource.heuristic);
    expect(m.matchedKeywords, contains('comprar'));
    expect(m.isAutoClassified, isTrue);
    expect(m.wasUserCorrected, isFalse);
  });

  test('task without classificationMetadata loads without crash', () async {
    // Simulate old-format task that never had metadata
    SharedPreferences.setMockInitialValues({
      'eisen.tasks.v1': '{"tasks":[{"id":"old-1","title":"Tarea vieja","quadrant":2,"priority":5,"minutes":30}]}',
    });

    final repo = LocalPrefsMatrixRepository(StoragePrefs());
    final loaded = await repo.load();

    expect(loaded, hasLength(1));
    final task = loaded.first;

    // Should not crash, and should have fallback values
    expect(task.id, 'old-1');
    expect(task.title, 'Tarea vieja');
    expect(task.kind, EntryKind.task);
    // Metadata is auto-generated for migrated tasks
    expect(task.classificationMetadata, isNotNull);
  });
}
