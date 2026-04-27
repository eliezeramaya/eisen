import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/eisen_matrix/application/semantic_treemap_builder.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSemanticTreemapScene', () {
    final categories = CategoryConfigDefaults.values;

    Task buildTask({
      required String id,
      required String title,
      required Quadrant quadrant,
      required String categoryId,
      String? category,
      List<String> tags = const <String>[],
      List<String> autoTags = const <String>[],
      ConfidenceLevel? confidence,
      EntryKind kind = EntryKind.task,
      EnergyLevel? energy,
      String? projectId,
    }) {
      return Task(
        id: id,
        title: title,
        quadrant: quadrant,
        priority: 7,
        minutes: 45,
        categoryId: categoryId,
        category: category,
        tags: tags,
        autoTags: autoTags,
        classificationConfidence: confidence,
        kind: kind,
        energy: energy,
        projectId: projectId,
      );
    }

    test('builds category nodes inside the selected quadrant', () {
      final tasks = [
        buildTask(
          id: 'w1',
          title: 'Preparar brief',
          quadrant: Quadrant.q2,
          categoryId: 'work',
          category: 'Trabajo',
        ),
        buildTask(
          id: 'w2',
          title: 'Enviar propuesta',
          quadrant: Quadrant.q2,
          categoryId: 'work',
          category: 'Trabajo',
        ),
        buildTask(
          id: 'h1',
          title: 'Comprar focos',
          quadrant: Quadrant.q2,
          categoryId: 'errands',
          category: 'Mandados',
        ),
        buildTask(
          id: 'q1',
          title: 'Urgencia externa',
          quadrant: Quadrant.q1,
          categoryId: 'work',
          category: 'Trabajo',
        ),
      ];

      final scene = buildSemanticTreemapScene(
        tasks: tasks,
        categories: categories,
        viewport: const TreemapViewportState(
          zoomLevel: TreemapZoomLevel.category,
          selectedQuadrant: Quadrant.q2,
          breadcrumbPath: ['Todo', 'Q2'],
        ),
        searchQuery: '',
      );

      expect(scene.scopedTasks.length, 3);
      expect(scene.nodes.length, 2);
      expect(scene.nodes.first.label, 'Trabajo');
      expect(scene.nodes.first.taskCount, 2);
    });

    test('builds task nodes and detects exact search match', () {
      final tasks = [
        buildTask(
          id: 't1',
          title: 'Llamar a Rosario',
          quadrant: Quadrant.q2,
          categoryId: 'work',
          category: 'Trabajo',
          tags: const ['seguimiento'],
          autoTags: const ['cliente'],
          confidence: ConfidenceLevel.low,
          energy: EnergyLevel.low,
          projectId: 'Cliente Rosario',
        ),
        buildTask(
          id: 't2',
          title: 'Enviar reporte',
          quadrant: Quadrant.q2,
          categoryId: 'work',
          category: 'Trabajo',
          tags: const ['seguimiento'],
          autoTags: const ['cliente'],
          projectId: 'Cliente Rosario',
        ),
      ];

      final scene = buildSemanticTreemapScene(
        tasks: tasks,
        categories: categories,
        viewport: const TreemapViewportState(
          zoomLevel: TreemapZoomLevel.task,
          selectedQuadrant: Quadrant.q2,
          selectedCategoryId: 'work',
          grouping: TreemapGrouping.project,
          selectedSubcategoryId: 'project:cliente-rosario',
          selectedGroupId: 'seguimiento',
          breadcrumbPath: [
            'Todo',
            'Q2',
            'Trabajo',
            'Cliente Rosario',
            'Seguimiento',
          ],
          quickFilter: TreemapQuickFilter.lowConfidence,
        ),
        searchQuery: 'Llamar a Rosario',
      );

      expect(scene.lowConfidenceCount, 1);
      expect(scene.exactTaskMatch?.id, 't1');
      expect(scene.nodes, hasLength(1));
      expect(scene.nodes.single.id, 't1');
    });
  });
}
