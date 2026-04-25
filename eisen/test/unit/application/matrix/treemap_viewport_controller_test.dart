import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/treemap_viewport_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('navigates through semantic levels and keeps breadcrumb path', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final controller =
        container.read(treemapViewportControllerProvider.notifier);

    controller.enterQuadrant(Quadrant.q2, label: 'Q2 · Planificar');
    controller.openCategory(categoryId: 'work', categoryLabel: 'Trabajo');
    controller.openSubcategory(
      subcategoryId: 'project:cliente-rosario',
      subcategoryLabel: 'Cliente Rosario',
    );
    controller.openGroup(groupId: 'seguimiento', groupLabel: 'Seguimiento');

    final state = container.read(treemapViewportControllerProvider);
    expect(state.zoomLevel, TreemapZoomLevel.task);
    expect(
      state.breadcrumbPath,
      ['Todo', 'Q2 · Planificar', 'Trabajo', 'Cliente Rosario', 'Seguimiento'],
    );

    controller.popLevel();
    final previous = container.read(treemapViewportControllerProvider);
    expect(previous.zoomLevel, TreemapZoomLevel.group);
    expect(previous.selectedGroupId, isNull);
  });
}
