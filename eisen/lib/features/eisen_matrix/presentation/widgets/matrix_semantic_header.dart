import 'package:eisen/features/eisen_matrix/application/semantic_treemap_builder.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/treemap_viewport_controller.dart';
import 'package:flutter/material.dart';

void exitSemanticLevel(
  MatrixController matrixCtrl,
  TreemapViewportController viewportCtrl,
  TreemapViewportState viewport,
) {
  if (viewport.zoomLevel == TreemapZoomLevel.global) {
    matrixCtrl.resetHomeView();
    return;
  }
  if (viewport.zoomLevel == TreemapZoomLevel.category) {
    viewportCtrl.reset(
      grouping: viewport.grouping,
      density: viewport.density,
    );
    matrixCtrl.resetHomeView();
    return;
  }
  viewportCtrl.popLevel();
}

void openSemanticNode({
  required BuildContext context,
  required MatrixController ctrl,
  required TreemapViewportController viewportCtrl,
  required TreemapViewportState viewport,
  required TreemapSemanticNode node,
}) {
  switch (viewport.zoomLevel) {
    case TreemapZoomLevel.global:
      return;
    case TreemapZoomLevel.category:
      viewportCtrl.openCategory(
        categoryId: node.id,
        categoryLabel: node.label,
      );
      return;
    case TreemapZoomLevel.subcategory:
      viewportCtrl.openSubcategory(
        subcategoryId: node.id,
        subcategoryLabel: node.label,
      );
      return;
    case TreemapZoomLevel.group:
      viewportCtrl.openGroup(
        groupId: node.id,
        groupLabel: node.label,
      );
      return;
    case TreemapZoomLevel.task:
      if (!node.isTaskLeaf) {
        return;
      }
      final task = node.tasks.single;
      viewportCtrl.focusTask(task);
      ctrl.select(task.id);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Scaffold.maybeOf(context)?.openEndDrawer(),
      );
      return;
  }
}

String quadrantLabel(BuildContext context, Quadrant quadrant) {
  final isEs = Localizations.localeOf(context).languageCode == 'es';
  if (!isEs) {
    return switch (quadrant) {
      Quadrant.q1 => 'Q1 · Do',
      Quadrant.q2 => 'Q2 · Decide',
      Quadrant.q3 => 'Q3 · Delegate',
      Quadrant.q4 => 'Q4 · Eliminate',
    };
  }
  return switch (quadrant) {
    Quadrant.q1 => 'Q1 · Hacer',
    Quadrant.q2 => 'Q2 · Planificar',
    Quadrant.q3 => 'Q3 · Delegar',
    Quadrant.q4 => 'Q4 · Eliminar',
  };
}

class MatrixSemanticHeader extends StatelessWidget {
  const MatrixSemanticHeader({
    required this.viewport,
    required this.scene,
    required this.onJumpToLevel,
    required this.onSelectGrouping,
    required this.onSelectQuickFilter,
    required this.onViewAll,
    required this.onOpenReviewCenter,
    this.onFocusExactTask,
  });

  final TreemapViewportState viewport;
  final TreemapSemanticScene scene;
  final ValueChanged<TreemapZoomLevel> onJumpToLevel;
  final ValueChanged<TreemapGrouping> onSelectGrouping;
  final ValueChanged<TreemapQuickFilter> onSelectQuickFilter;
  final VoidCallback onViewAll;
  final VoidCallback onOpenReviewCenter;
  final VoidCallback? onFocusExactTask;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < viewport.breadcrumbPath.length; i++) ...[
                  TextButton(
                    onPressed: () => onJumpToLevel(
                      TreemapZoomLevel.values[i.clamp(0, TreemapZoomLevel.values.length - 1)],
                    ),
                    child: Text(viewport.breadcrumbPath[i]),
                  ),
                  if (i != viewport.breadcrumbPath.length - 1)
                    Text(
                      '>',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                ],
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Ver todo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final picked = await showMenu<TreemapGrouping>(
                            context: context,
                            position: const RelativeRect.fromLTRB(40, 140, 0, 0),
                            items: [
                              for (final grouping in TreemapGrouping.values)
                                PopupMenuItem<TreemapGrouping>(
                                  value: grouping,
                                  child: Text(_groupingLabel(grouping)),
                                ),
                            ],
                          );
                          if (picked != null) {
                            onSelectGrouping(picked);
                          }
                        },
                        icon: const Icon(Icons.account_tree_outlined),
                        label: Text('Vista: ${_groupingLabel(viewport.grouping)}'),
                      ),
                      if (scene.lowConfidenceCount > 0) ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.rule_folder_outlined, size: 16),
                          label: Text('Revisar ${scene.lowConfidenceCount}'),
                          onPressed: onOpenReviewCenter,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  scene.subtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PopupMenuButton<TreemapQuickFilter>(
                tooltip: 'Filtros rápidos',
                offset: const Offset(0, 44),
                onSelected: onSelectQuickFilter,
                itemBuilder: (_) => [
                  for (final filter in TreemapQuickFilter.values)
                    CheckedPopupMenuItem<TreemapQuickFilter>(
                      value: filter,
                      checked: viewport.quickFilter == filter,
                      child: Text(_quickFilterLabel(filter)),
                    ),
                ],
                child: _QuickFilterPill(
                  activeFilter: viewport.quickFilter,
                  labelFor: _quickFilterLabel,
                ),
              ),
              if (onFocusExactTask != null) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.travel_explore, size: 16),
                  label: const Text('Ir a coincidencia exacta'),
                  onPressed: onFocusExactTask,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _groupingLabel(TreemapGrouping grouping) {
    return switch (grouping) {
      TreemapGrouping.category => 'Categoria',
      TreemapGrouping.kind => 'Tipo',
      TreemapGrouping.horizon => 'Horizonte',
      TreemapGrouping.energy => 'Energia',
      TreemapGrouping.client => 'Cliente',
      TreemapGrouping.project => 'Proyecto',
      TreemapGrouping.tag => 'Tags',
      TreemapGrouping.confidence => 'Confianza',
      TreemapGrouping.context => 'Contexto',
    };
  }

  String _quickFilterLabel(TreemapQuickFilter filter) {
    return switch (filter) {
      TreemapQuickFilter.today => 'Hoy',
      TreemapQuickFilter.week => 'Semana',
      TreemapQuickFilter.highPriority => 'Alta prioridad',
      TreemapQuickFilter.lowConfidence => 'Baja confianza',
      TreemapQuickFilter.lowEnergy => 'Poca energia',
    };
  }
}

class _QuickFilterPill extends StatelessWidget {
  const _QuickFilterPill({
    required this.activeFilter,
    required this.labelFor,
  });

  final TreemapQuickFilter? activeFilter;
  final String Function(TreemapQuickFilter) labelFor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasActive = activeFilter != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: hasActive ? cs.tertiaryContainer : null,
        border: Border.all(
          color: hasActive ? cs.tertiary : cs.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 16),
          const SizedBox(width: 6),
          Text(
            hasActive ? labelFor(activeFilter!) : 'Filtros rápidos',
            style: tt.labelMedium?.copyWith(
              color: hasActive ? cs.onTertiaryContainer : null,
              fontWeight: hasActive ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: hasActive ? cs.onTertiaryContainer : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
