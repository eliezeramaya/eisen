import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
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

  test('LocalPrefsMatrixRepository saves and loads tasks', () async {
    final repo = LocalPrefsMatrixRepository(StoragePrefs());

    // Initially empty
    var loaded = await repo.load();
    expect(loaded, isEmpty);

    final tasks = [
      const Task(
          id: '1', title: 'A', quadrant: Quadrant.q2, priority: 5, minutes: 30),
      const Task(
          id: '2', title: 'B', quadrant: Quadrant.q1, priority: 7, minutes: 45),
    ];

    await repo.save(tasks);

    loaded = await repo.load();
    expect(loaded.length, 2);
    expect(loaded[0].id, '1');
    expect(loaded[1].quadrant, Quadrant.q1);
  });

  test('migrates legacy tasks with safe treemap and classification defaults',
      () async {
    SharedPreferences.setMockInitialValues({
      'eisen.tasks.v1':
          '{"tasks":[{"id":"legacy-1","title":"Comprar pintura","quadrant":1,"priority":4,"minutes":20}]}',
    });

    final repo = LocalPrefsMatrixRepository(StoragePrefs());
    final loaded = await repo.load();

    expect(loaded, hasLength(1));
    final task = loaded.single;
    expect(task.categoryId, 'inbox');
    expect(task.category, 'Inbox');
    expect(task.horizon, TimeHorizon.someday);
    expect(task.energy, EnergyLevel.medium);
    expect(task.classificationConfidence, ConfidenceLevel.low);
    expect(task.classificationMetadata, isNotNull);
    expect(
      task.classificationMetadata?.source,
      ClassificationSource.fallback,
    );
  });

  test('preserves manual corrections as high confidence during migration',
      () async {
    SharedPreferences.setMockInitialValues({
      'eisen.tasks.v1':
          '{"tasks":[{"id":"legacy-2","title":"Llamar a Rosario","quadrant":1,"priority":6,"minutes":30,"categoryId":"work","classificationConfidence":"medium","classificationMetadata":{"inputText":"Llamar a Rosario","normalizedText":"llamar a rosario","categoryId":"work","entryKind":"task","timeHorizon":"today","energyLevel":"low","priorityLevel":"high","confidenceScore":0.62,"confidenceLevel":"medium","classifierVersion":"local-heuristic-v1","source":"heuristic","matchedKeywords":["rosario"],"signals":["cliente"],"appliedRuleIds":[],"confidenceReason":"Confianza media.","reasons":["Coincidencia por cliente."],"isAutoClassified":true,"wasUserCorrected":true,"isUserConfirmed":true,"classifiedAt":"2026-04-24T10:00:00.000","createdAt":"2026-04-24T10:00:00.000","updatedAt":"2026-04-24T10:00:00.000"}}]}',
    });

    final repo = LocalPrefsMatrixRepository(StoragePrefs());
    final loaded = await repo.load();

    expect(loaded, hasLength(1));
    final task = loaded.single;
    expect(task.classificationConfidence, ConfidenceLevel.high);
    expect(task.classificationMetadata?.source,
        ClassificationSource.userCorrection);
    expect(task.classificationMetadata?.wasUserCorrected, isTrue);
  });
}
