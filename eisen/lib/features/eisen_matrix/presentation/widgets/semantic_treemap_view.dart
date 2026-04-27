import 'dart:math' as math;

import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/application/semantic_treemap_builder.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class SemanticTreemapView extends StatelessWidget {
  const SemanticTreemapView({
    super.key,
    required this.scene,
    required this.selectedNodeId,
    required this.categoryColorService,
    required this.colorByCategory,
    required this.showConfidenceIndicators,
    required this.showAutoTags,
    required this.onNodeSelected,
    required this.onNodeOpen,
    required this.onOpenTaskInspector,
    required this.onReviewLowConfidence,
  });

  final TreemapSemanticScene scene;
  final String? selectedNodeId;
  final CategoryColorService categoryColorService;
  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final ValueChanged<TreemapSemanticNode> onNodeSelected;
  final ValueChanged<TreemapSemanticNode> onNodeOpen;
  final ValueChanged<Task> onOpenTaskInspector;
  final ValueChanged<TreemapSemanticNode> onReviewLowConfidence;

  @override
  Widget build(BuildContext context) {
    if (scene.isEmpty) {
      return _SemanticEmptyState(
        title: scene.viewport.quickFilter == null
            ? 'Todavia no tienes tareas en esta vista.'
            : 'No hay tareas en este filtro.',
        subtitle: scene.viewport.quickFilter == null
            ? 'Agrega una idea, pendiente o recordatorio y Eisen lo clasificara.'
            : 'Prueba cambiar el filtro rapido o volver a "Ver todo".',
      );
    }

    final rects = _computeRects(scene.nodes);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: 0.35,
              ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                for (var index = 0; index < scene.nodes.length; index++)
                  _SemanticTreemapTile(
                    node: scene.nodes[index],
                    rect01: rects[index],
                    categoryColorService: categoryColorService,
                    colorByCategory: colorByCategory,
                    showConfidenceIndicators: showConfidenceIndicators,
                    showAutoTags: showAutoTags,
                    selected: selectedNodeId == scene.nodes[index].id,
                    onSelected: () => onNodeSelected(scene.nodes[index]),
                    onOpen: () => onNodeOpen(scene.nodes[index]),
                    onOpenTaskInspector: onOpenTaskInspector,
                    onReviewLowConfidence: () =>
                        onReviewLowConfidence(scene.nodes[index]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SemanticTreemapDetailsCard extends StatelessWidget {
  const SemanticTreemapDetailsCard({
    super.key,
    required this.node,
    required this.onOpen,
    required this.onReviewLowConfidence,
    required this.onOpenTaskInspector,
    required this.onMarkDone,
  });

  final TreemapSemanticNode node;
  final VoidCallback onOpen;
  final VoidCallback onReviewLowConfidence;
  final VoidCallback onOpenTaskInspector;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = node.isTaskLeaf ? node.tasks.single : null;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (node.subtitle != null && node.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  node.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaChip(context, '${node.taskCount} tareas'),
                  _metaChip(
                      context, '${(node.loadShare * 100).round()}% carga'),
                  if (node.lowConfidenceCount > 0)
                    _metaChip(
                      context,
                      '${node.lowConfidenceCount} revisar',
                      tint: Colors.orangeAccent,
                    ),
                ],
              ),
              if (node.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in node.tags.take(3))
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (task != null) ...[
                _TaskDetails(task: task),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  'Tareas principales',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in node.tasks.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onOpen,
                    icon: Icon(
                        task == null ? Icons.zoom_in_map : Icons.open_in_new),
                    label: Text(task == null ? 'Expandir' : 'Enfocar'),
                  ),
                  if (node.lowConfidenceCount > 0)
                    OutlinedButton.icon(
                      onPressed: onReviewLowConfidence,
                      icon: const Icon(Icons.rule_folder_outlined),
                      label: const Text('Revisar'),
                    ),
                  if (task != null)
                    OutlinedButton.icon(
                      onPressed: onOpenTaskInspector,
                      icon: const Icon(Icons.tune),
                      label: const Text('Inspector'),
                    ),
                  if (task != null && !task.isCompleted)
                    TextButton.icon(
                      onPressed: onMarkDone,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Completar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context, String label, {Color? tint}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (tint ?? cs.secondaryContainer).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (tint ?? cs.secondary).withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class GlobalSemanticSummaryStrip extends StatelessWidget {
  const GlobalSemanticSummaryStrip({
    super.key,
    required this.tasks,
  });

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaries = [
      for (final quadrant in Quadrant.values) _buildSummary(quadrant),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final summary in summaries) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.$1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.$2,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    summary.$3,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  (String, String, String) _buildSummary(Quadrant quadrant) {
    final scoped = tasks.where((task) => task.quadrant == quadrant).toList();
    if (scoped.isEmpty) {
      return (quadrant.name.toUpperCase(), 'Sin carga', '0 tareas');
    }
    final counts = <String, int>{};
    for (final task in scoped) {
      final key = (task.category ?? task.categoryId ?? 'General').trim();
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    final dominant = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (
      quadrant.name.toUpperCase(),
      dominant.first.key.isEmpty ? 'General' : dominant.first.key,
      '${scoped.length} tareas',
    );
  }
}

class _SemanticTreemapTile extends StatelessWidget {
  const _SemanticTreemapTile({
    required this.node,
    required this.rect01,
    required this.categoryColorService,
    required this.colorByCategory,
    required this.showConfidenceIndicators,
    required this.showAutoTags,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
    required this.onOpenTaskInspector,
    required this.onReviewLowConfidence,
  });

  final TreemapSemanticNode node;
  final Rect rect01;
  final CategoryColorService categoryColorService;
  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onOpen;
  final ValueChanged<Task> onOpenTaskInspector;
  final VoidCallback onReviewLowConfidence;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final rect = Rect.fromLTWH(
          rect01.left * width,
          rect01.top * height,
          rect01.width * width,
          rect01.height * height,
        ).deflate(6);
        final categoryKey = node.categoryLabel ?? node.label;
        final fill = colorByCategory
            ? categoryColorService.getLightVariant(categoryKey, opacity: 0.24)
            : Theme.of(context).colorScheme.secondaryContainer.withValues(
                  alpha: 0.32,
                );
        final border = colorByCategory
            ? categoryColorService.getDarkVariant(categoryKey, opacity: 0.45)
            : Theme.of(context).colorScheme.outlineVariant;
        final area = rect.width * rect.height;
        final compact = area < 18000;
        final tiny = area < 9000;
        final faded = !node.matchedSearch;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: Opacity(
            opacity: faded ? 0.45 : 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelected,
              onDoubleTap: onOpen,
              onLongPress: () => _showNodeActions(context),
              onSecondaryTapDown: (details) =>
                  _showNodeMenu(context, details.globalPosition),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(compact ? 10 : 14),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(compact ? 14 : 18),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : border,
                    width: selected ? 2 : 1.1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : const [],
                ),
                child: tiny
                    ? _TinyTile(node: node)
                    : _RichTile(
                        node: node,
                        compact: compact,
                        showConfidenceIndicators: showConfidenceIndicators,
                        showAutoTags: showAutoTags,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNodeActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final task = node.isTaskLeaf ? node.tasks.single : null;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_full),
                title: Text(task == null ? 'Expandir grupo' : 'Enfocar tarea'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpen();
                },
              ),
              if (node.lowConfidenceCount > 0)
                ListTile(
                  leading: const Icon(Icons.rule_folder_outlined),
                  title: const Text('Revisar clasificacion'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onReviewLowConfidence();
                  },
                ),
              if (task != null)
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Abrir inspector'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onOpenTaskInspector(task);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNodeMenu(BuildContext context, Offset position) async {
    final task = node.isTaskLeaf ? node.tasks.single : null;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'open',
          child: Text(task == null ? 'Expandir' : 'Enfocar tarea'),
        ),
        if (node.lowConfidenceCount > 0)
          const PopupMenuItem<String>(
            value: 'review',
            child: Text('Revisar clasificacion'),
          ),
        if (task != null)
          const PopupMenuItem<String>(
            value: 'inspector',
            child: Text('Abrir inspector'),
          ),
      ],
    );
    switch (value) {
      case 'open':
        onOpen();
        return;
      case 'review':
        onReviewLowConfidence();
        return;
      case 'inspector':
        if (task != null) {
          onOpenTaskInspector(task);
        }
        return;
      default:
        return;
    }
  }
}

class _TinyTile extends StatelessWidget {
  const _TinyTile({required this.node});

  final TreemapSemanticNode node;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        node.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RichTile extends StatelessWidget {
  const _RichTile({
    required this.node,
    required this.compact,
    required this.showConfidenceIndicators,
    required this.showAutoTags,
  });

  final TreemapSemanticNode node;
  final bool compact;
  final bool showConfidenceIndicators;
  final bool showAutoTags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = node.isTaskLeaf ? node.tasks.single : null;
    final titleStyle = compact
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.label,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (node.subtitle != null && node.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            node.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        if (task == null) ...[
          Row(
            children: [
              Text(
                '${node.taskCount} tareas',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(node.loadShare * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (node.lowConfidenceCount > 0 && showConfidenceIndicators) ...[
            const SizedBox(height: 6),
            Text(
              '${node.lowConfidenceCount} con baja confianza',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orangeAccent.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ] else ...[
          if (showAutoTags && node.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in node.tags.take(compact ? 2 : 3))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.66),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text(
                'P${task.priority}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${task.minutes}m',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (showConfidenceIndicators)
                _ConfidenceBadge(level: task.classificationConfidence),
            ],
          ),
        ],
      ],
    );
  }
}

class _TaskDetails extends StatelessWidget {
  const _TaskDetails({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailLine(
            'Categoria', task.category ?? task.categoryId ?? 'Sin categoria'),
        _detailLine('Tipo', task.kind.label),
        _detailLine('Horizonte', task.horizon?.label ?? 'Sin horizonte'),
        _detailLine('Energia', task.energy?.label ?? 'Sin energia'),
        _detailLine('Prioridad', 'P${task.priority} · ${task.minutes}m'),
        if (task.tags.isNotEmpty || task.autoTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in {...task.tags, ...task.autoTags}.take(4))
                  Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        if (task.classificationMetadata != null) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Por que se clasifico asi'),
            children: [
              for (final reason in task.classificationMetadata!.reasons.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.level});

  final ConfidenceLevel? level;

  @override
  Widget build(BuildContext context) {
    if (level == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('Revisar'),
      );
    }
    if (level == ConfidenceLevel.high) {
      return Icon(
        Icons.check_circle,
        size: 16,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      );
    }
    if (level == ConfidenceLevel.medium) {
      return const Icon(Icons.brightness_1, size: 10);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.65),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('Revisar'),
    );
  }
}

class _SemanticEmptyState extends StatelessWidget {
  const _SemanticEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 38,
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.7,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Rect> _computeRects(List<TreemapSemanticNode> nodes) {
  if (nodes.isEmpty) {
    return const <Rect>[];
  }
  final normalized = [...nodes]
    ..sort((a, b) => b.totalWeight.compareTo(a.totalWeight));
  final total = normalized.fold<double>(
    0,
    (sum, node) => sum + math.max(node.totalWeight, 0.0001),
  );
  final items = [
    for (final node in normalized)
      _LayoutItem(
        area: math.max(node.totalWeight, 0.0001) / total,
        node: node,
      ),
  ];
  final out = <Rect>[];
  var cursor = const Rect.fromLTWH(0, 0, 1, 1);
  var row = <_LayoutItem>[];

  double worst(List<_LayoutItem> rowItems, double shortSide) {
    final sum = rowItems.fold<double>(0, (value, item) => value + item.area);
    final maxArea =
        rowItems.fold<double>(0, (value, item) => math.max(value, item.area));
    final minArea = rowItems.fold<double>(
      double.infinity,
      (value, item) => math.min(value, item.area),
    );
    if (sum == 0 || minArea == 0) {
      return double.infinity;
    }
    final sumSq = sum * sum;
    final shortSq = shortSide * shortSide;
    return math.max(
      (shortSq * maxArea) / sumSq,
      sumSq / (shortSq * minArea),
    );
  }

  void layoutRow(List<_LayoutItem> rowItems, Rect rowBounds) {
    if (rowItems.isEmpty) {
      return;
    }
    final rowArea = rowItems.fold<double>(0, (sum, item) => sum + item.area);
    final horizontal = rowBounds.width >= rowBounds.height;
    if (horizontal) {
      final height = rowArea / rowBounds.width;
      var x = rowBounds.left;
      for (final item in rowItems) {
        final width = item.area / height;
        out.add(Rect.fromLTWH(x, rowBounds.top, width, height));
        x += width;
      }
      cursor = Rect.fromLTWH(
        rowBounds.left,
        rowBounds.top + height,
        rowBounds.width,
        math.max(0, rowBounds.height - height),
      );
      return;
    }
    final width = rowArea / rowBounds.height;
    var y = rowBounds.top;
    for (final item in rowItems) {
      final height = item.area / width;
      out.add(Rect.fromLTWH(rowBounds.left, y, width, height));
      y += height;
    }
    cursor = Rect.fromLTWH(
      rowBounds.left + width,
      rowBounds.top,
      math.max(0, rowBounds.width - width),
      rowBounds.height,
    );
  }

  for (final item in items) {
    if (row.isEmpty) {
      row = [item];
      continue;
    }
    final shortSide = math.min(cursor.width, cursor.height);
    final candidate = [...row, item];
    if (worst(candidate, shortSide) <= worst(row, shortSide)) {
      row.add(item);
    } else {
      layoutRow(row, cursor);
      row = [item];
    }
  }
  layoutRow(row, cursor);
  return out;
}

class _LayoutItem {
  const _LayoutItem({
    required this.area,
    required this.node,
  });

  final double area;
  final TreemapSemanticNode node;
}
