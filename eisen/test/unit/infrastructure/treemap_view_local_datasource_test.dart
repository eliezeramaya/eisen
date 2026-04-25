import 'package:eisen/features/eisen_matrix/data/treemap_view_local_datasource.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_view_preferences.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists treemap preferences and viewport state', () async {
    final datasource = TreemapViewLocalDatasource();
    const preferences = TreemapViewPreferences(
      defaultGrouping: TreemapGrouping.project,
      visualDensity: TreemapVisualDensity.compact,
      showMinimap: true,
    );
    const state = TreemapViewportState(
      zoomLevel: TreemapZoomLevel.category,
      selectedQuadrant: Quadrant.q2,
      grouping: TreemapGrouping.project,
      density: TreemapVisualDensity.compact,
      breadcrumbPath: <String>['Todo', 'Q2'],
      activeSearchQuery: 'Rosario',
    );

    await datasource.savePreferences(preferences);
    await datasource.saveState(state);

    final loadedPreferences = await datasource.loadPreferences();
    final loadedState = await datasource.loadState();

    expect(loadedPreferences.defaultGrouping, TreemapGrouping.project);
    expect(loadedPreferences.visualDensity, TreemapVisualDensity.compact);
    expect(loadedPreferences.showMinimap, isTrue);
    expect(loadedState, isNotNull);
    expect(loadedState?.selectedQuadrant, Quadrant.q2);
    expect(loadedState?.activeSearchQuery, 'Rosario');
  });
}
