import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A minimal task for filter tests.
Task _task({
  String categoryId = 'work',
  EntryKind kind = EntryKind.task,
  TimeHorizon? horizon,
  EnergyLevel? energy,
  ConfidenceLevel? confidence,
}) =>
    Task(
      id: 'test',
      title: 'Test task',
      quadrant: Quadrant.q2,
      priority: 5,
      minutes: 30,
      categoryId: categoryId,
      kind: kind,
      horizon: horizon,
      energy: energy,
      classificationConfidence: confidence,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActiveCategoryFilters', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeCategoryFiltersProvider), isEmpty);
    });

    test('update() changes state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeCategoryFiltersProvider.notifier)
          .update(['work', 'health']);
      // State updated immediately
      expect(
        container.read(activeCategoryFiltersProvider),
        ['work', 'health'],
      );
    });
  });

  group('ActiveKindFilters', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeKindFiltersProvider), isEmpty);
    });

    test('update() stores EntryKind values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeKindFiltersProvider.notifier)
          .update([EntryKind.task, EntryKind.idea]);
      expect(container.read(activeKindFiltersProvider), [
        EntryKind.task,
        EntryKind.idea,
      ]);
    });
  });

  group('ActiveHorizonFilters', () {
    test('update() stores TimeHorizon values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeHorizonFiltersProvider.notifier)
          .update([TimeHorizon.today, TimeHorizon.thisWeek]);
      expect(container.read(activeHorizonFiltersProvider), [
        TimeHorizon.today,
        TimeHorizon.thisWeek,
      ]);
    });
  });

  group('ActiveEnergyFilters', () {
    test('update() stores EnergyLevel values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeEnergyFiltersProvider.notifier)
          .update([EnergyLevel.low]);
      expect(
        container.read(activeEnergyFiltersProvider),
        [EnergyLevel.low],
      );
    });
  });

  group('ActiveConfidenceFilters', () {
    test('update() stores ConfidenceLevel values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(activeConfidenceFiltersProvider.notifier)
          .update([ConfidenceLevel.low]);
      expect(
        container.read(activeConfidenceFiltersProvider),
        [ConfidenceLevel.low],
      );
    });
  });

  group('matchesTaskClassificationFilters', () {
    test('passes when all filters are empty (no-op)', () {
      expect(
        matchesTaskClassificationFilters(task: _task()),
        isTrue,
      );
    });

    test('filters by category — matching category passes', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(categoryId: 'work'),
          categoryIds: ['work'],
        ),
        isTrue,
      );
    });

    test('filters by category — non-matching category fails', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(categoryId: 'health'),
          categoryIds: ['work'],
        ),
        isFalse,
      );
    });

    test('filters by energy — matching energy passes', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(energy: EnergyLevel.low),
          energies: [EnergyLevel.low],
        ),
        isTrue,
      );
    });

    test('filters by energy — non-matching energy fails', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(energy: EnergyLevel.high),
          energies: [EnergyLevel.low],
        ),
        isFalse,
      );
    });

    test('filters by confidence — non-matching confidence fails', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(confidence: ConfidenceLevel.low),
          confidences: [ConfidenceLevel.high],
        ),
        isFalse,
      );
    });

    test('filters by kind — matching kind passes', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(kind: EntryKind.idea),
          kinds: [EntryKind.idea],
        ),
        isTrue,
      );
    });

    test('filters by horizon — non-matching horizon fails', () {
      expect(
        matchesTaskClassificationFilters(
          task: _task(horizon: TimeHorizon.today),
          horizons: [TimeHorizon.someday],
        ),
        isFalse,
      );
    });
  });
}
