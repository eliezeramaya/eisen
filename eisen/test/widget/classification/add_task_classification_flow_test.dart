import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/domain/enums/classification_source.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/repositories/classification_repository.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/tasks/presentation/add_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'AddTaskSheet shows subtle classification loading and persists edited classification',
    (tester) async {
      final repository = _FakeClassificationRepository();
      final container = ProviderContainer(
        overrides: [
          classificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    return FilledButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const AddTaskSheet(),
                        );
                      },
                      child: const Text('Abrir'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Comprar leche hoy');
      await tester.pump(const Duration(milliseconds: 280));

      expect(find.text('Analizando entrada…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 160));
      await tester.pumpAndSettle();

      expect(find.text('Mandados'), findsAtLeastNWidgets(1));
      expect(find.text('Compra'), findsAtLeastNWidgets(1));
      expect(find.text('Hoy'), findsAtLeastNWidgets(1));
      expect(find.text('Baja'), findsAtLeastNWidgets(1));
      expect(find.text('Alta'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Idea').last);
      await tester.pumpAndSettle();

      expect(find.text('Idea'), findsAtLeastNWidgets(1));

      await tester.ensureVisible(find.text('Guardar').last);
      await tester.tap(find.text('Guardar').last);
      await tester.pumpAndSettle();

      final tasks = container.read(matrixTasksProvider);
      expect(tasks, hasLength(1));

      final task = tasks.single;
      expect(task.title, 'Comprar leche hoy');
      expect(task.quadrant, Quadrant.q1);
      expect(task.kind, EntryKind.idea);
      expect(task.categoryId, 'errands');
      expect(task.category, 'Mandados');
      expect(task.classificationMetadata, isNotNull);
      expect(task.classificationMetadata!.entryKind, EntryKind.idea);
      expect(
          task.classificationMetadata!.confidenceLevel, ConfidenceLevel.high);
      expect(task.autoTags, contains('comprar'));
    },
  );

  testWidgets('AddTaskSheet respects manual quadrant selection',
      (tester) async {
    final repository = _FakeClassificationRepository();
    final container = ProviderContainer(
      overrides: [
        classificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTaskSheet(),
                    );
                  },
                  child: const Text('Abrir'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Comprar leche hoy');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Crecimiento'));
    await tester.tap(find.text('Crecimiento'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar').last);
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();

    final tasks = container.read(matrixTasksProvider);
    expect(tasks.single.quadrant, Quadrant.q2);
  });
}

class _FakeClassificationRepository implements ClassificationRepository {
  _FakeClassificationRepository();

  final List<ClassificationCorrectionEvent> _corrections =
      <ClassificationCorrectionEvent>[];

  @override
  Future<ClassificationMetadata> classifyEntry(String input) async {
    return _shoppingPreview(input);
  }

  @override
  Future<List<VocabularyAlias>> loadAliases() async {
    return const <VocabularyAlias>[];
  }

  @override
  Future<List<CategoryConfig>> loadCategories() async {
    return CategoryConfigDefaults.values;
  }

  @override
  Future<List<ClassificationCorrectionEvent>> loadCorrections() async {
    return _corrections;
  }

  @override
  Future<List<ClassificationRule>> loadRules() async {
    return const <ClassificationRule>[];
  }

  @override
  Future<ClassificationSettings> loadSettings() async {
    return ClassificationSettingsDefaults.value;
  }

  @override
  Future<ClassificationMetadata> previewClassification({
    required String input,
    ClassificationSettings? settings,
    List<CategoryConfig>? categories,
    List<ClassificationRule>? rules,
    List<VocabularyAlias>? aliases,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _shoppingPreview(input);
  }

  @override
  Future<void> recordCorrection(ClassificationCorrectionEvent event) async {
    _corrections.add(event);
  }

  @override
  Future<void> saveAliases(List<VocabularyAlias> aliases) async {}

  @override
  Future<void> saveCategories(List<CategoryConfig> categories) async {}

  @override
  Future<void> saveRules(List<ClassificationRule> rules) async {}

  @override
  Future<void> saveSettings(ClassificationSettings settings) async {}

  @override
  Future<List<RuleSuggestion>> suggestRules() async {
    return const <RuleSuggestion>[];
  }

  @override
  Future<void> updateRuleSuggestionStatus(
    String suggestionId,
    SuggestionStatus status,
  ) async {}

  ClassificationMetadata _shoppingPreview(String input) {
    return ClassificationMetadata(
      inputText: input,
      normalizedText: input.toLowerCase(),
      categoryId: 'errands',
      entryKind: EntryKind.shoppingItem,
      timeHorizon: TimeHorizon.today,
      energyLevel: EnergyLevel.low,
      priorityLevel: PriorityLevel.medium,
      confidenceScore: 0.84,
      confidenceLevel: ConfidenceLevel.high,
      classifierVersion: 'test-engine-v1',
      source: ClassificationSource.heuristic,
      matchedKeywords: const <String>['comprar', 'leche'],
      signals: const <String>['shopping-keywords'],
      confidenceReason: 'Matched shopping keywords.',
      reasons: const <String>[
        'Keywords detectadas: comprar, leche.',
      ],
      suggestedQuadrant: Quadrant.q1,
      urgencyScore: 0.92,
      importanceScore: 0.72,
      quadrantReason: 'Alta urgencia y alta importancia',
    );
  }
}
