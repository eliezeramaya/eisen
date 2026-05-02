import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/application/atlas_zoom_controller.dart';
import 'package:eisen/features/atlas/data/atlas_saved_views_repository.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('repositorio guarda y carga vistas', () async {
    const repository = AtlasSavedViewsRepository();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final view = await container
        .read(savedAtlasViewsProvider.notifier)
        .saveCurrentView('Mi vista');

    final loaded = await repository.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.id, view.id);
    expect(loaded.single.name, 'Mi vista');
  });

  test('guarda vista actual con filtros, grouping, archived y zoom', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(atlasGroupingProvider.notifier)
        .update(AtlasGrouping.horizon);
    await container
        .read(activeCategoryFiltersProvider.notifier)
        .update(const ['work']);
    await container
        .read(activeKindFiltersProvider.notifier)
        .update(const [EntryKind.project]);
    await container
        .read(activeHorizonFiltersProvider.notifier)
        .update(const [TimeHorizon.thisWeek]);
    await container
        .read(activeEnergyFiltersProvider.notifier)
        .update(const [EnergyLevel.high]);
    await container
        .read(activeConfidenceFiltersProvider.notifier)
        .update(const [ConfidenceLevel.low]);
    container.read(showArchivedProvider.notifier).update(true);
    container.read(atlasZoomProvider.notifier).applySavedZoom(
          scale: 2.4,
          offset: const Offset(10, 12),
          semanticLevel: AtlasSemanticLevel.task,
        );

    final view = await container
        .read(savedAtlasViewsProvider.notifier)
        .saveCurrentView('Semana');

    expect(view.grouping, AtlasGrouping.horizon);
    expect(view.filters.categoryIds, ['work']);
    expect(view.filters.kinds, [EntryKind.project]);
    expect(view.filters.horizons, [TimeHorizon.thisWeek]);
    expect(view.filters.energies, [EnergyLevel.high]);
    expect(view.filters.confidences, [ConfidenceLevel.low]);
    expect(view.showArchived, isTrue);
    expect(view.semanticLevel, AtlasSemanticLevel.task);
    expect(view.zoomScale, 2.4);
    expect(view.zoomOffset, const Offset(10, 12));
  });

  test('aplica filtros, grouping, showArchived y zoom guardados', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(atlasGroupingProvider.notifier).update(AtlasGrouping.energy);
    await container
        .read(activeConfidenceFiltersProvider.notifier)
        .update(const [ConfidenceLevel.low]);
    container.read(showArchivedProvider.notifier).update(true);
    container.read(atlasZoomProvider.notifier).applySavedZoom(
          scale: 3,
          offset: const Offset(5, 9),
          semanticLevel: AtlasSemanticLevel.detail,
        );

    final view = await container
        .read(savedAtlasViewsProvider.notifier)
        .saveCurrentView('Baja confianza');

    container
        .read(atlasGroupingProvider.notifier)
        .update(AtlasGrouping.category);
    await container
        .read(activeConfidenceFiltersProvider.notifier)
        .update(const <ConfidenceLevel>[]);
    container.read(showArchivedProvider.notifier).update(false);
    container.read(atlasZoomProvider.notifier).reset();

    await container.read(savedAtlasViewsProvider.notifier).applyView(view);

    expect(container.read(atlasGroupingProvider), AtlasGrouping.energy);
    expect(
      container.read(activeConfidenceFiltersProvider),
      [ConfidenceLevel.low],
    );
    expect(container.read(showArchivedProvider), isTrue);
    expect(
      container.read(atlasZoomProvider).semanticLevel,
      AtlasSemanticLevel.detail,
    );
    expect(container.read(activeSavedAtlasViewProvider), view.id);
  });

  test('elimina sin romper vista activa', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final view = await container
        .read(savedAtlasViewsProvider.notifier)
        .saveCurrentView('Temporal');

    expect(container.read(activeSavedAtlasViewProvider), view.id);

    await container.read(savedAtlasViewsProvider.notifier).deleteView(view.id);

    expect(container.read(savedAtlasViewsProvider), isEmpty);
    expect(container.read(activeSavedAtlasViewProvider), isNull);
  });
}
