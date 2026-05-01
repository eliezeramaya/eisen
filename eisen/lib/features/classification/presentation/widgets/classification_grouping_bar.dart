import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationGroupingBar extends ConsumerWidget {
  const ClassificationGroupingBar({
    super.key,
    required this.tasks,
    required this.categories,
    required this.settings,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final List<Task> tasks;
  final List<CategoryConfig> categories;
  final ClassificationSettings settings;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <_GroupSummary>[
      if (settings.allowGroupingByCategory) ..._categoryGroups(tasks, categories),
      if (settings.allowGroupingByKind)
        ..._enumGroups(
          'Tipo',
          tasks,
          (task) => task.kind.label,
        ),
      if (settings.allowGroupingByHorizon)
        ..._enumGroups(
          'Horizonte',
          tasks,
          (task) => task.horizon?.label ?? 'Sin horizonte',
        ),
      if (settings.allowGroupingByEnergy)
        ..._enumGroups(
          'Energía',
          tasks,
          (task) => task.energy?.label ?? 'Sin energía',
        ),
    ];
    final lowConfidenceCount = tasks.where((task) => task.classificationConfidence == ConfidenceLevel.low).length;

    if (groups.isEmpty && lowConfidenceCount == 0) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lowConfidenceCount > 0) ...[
            ActionChip(
              avatar: const Icon(Icons.circle, size: 9),
              label: Text('Revisar $lowConfidenceCount'),
              onPressed: () {
                final current = ref.read(activeConfidenceFiltersProvider);
                final next = current.contains(ConfidenceLevel.low)
                    ? current.where((item) => item != ConfidenceLevel.low)
                    : <ConfidenceLevel>{...current, ConfidenceLevel.low};
                ref.read(activeConfidenceFiltersProvider.notifier).update(next.toList());
              },
            ),
            const SizedBox(width: 8),
          ],
          if (groups.isNotEmpty)
            PopupMenuButton<void>(
              tooltip: 'Ver distribución',
              offset: const Offset(0, 44),
              itemBuilder: (_) => [
                for (final group in groups.take(16))
                  PopupMenuItem<void>(
                    enabled: false,
                    height: 36,
                    child: Row(
                      children: [
                        Text(
                          '${group.dimension}: ',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          group.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${group.count}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: _GroupSummaryPill(groups: groups.take(16).toList()),
            ),
        ],
      ),
    );
  }
}

List<_GroupSummary> _categoryGroups(
  List<Task> tasks,
  List<CategoryConfig> categories,
) {
  final counts = <String, int>{};
  for (final task in tasks) {
    final category = categoryForTask(categories, task);
    final label = category?.name ?? task.category ?? 'Sin categoría';
    counts.update(label, (value) => value + 1, ifAbsent: () => 1);
  }
  return _sortedGroups('Categoría', counts);
}

List<_GroupSummary> _enumGroups(
  String dimension,
  List<Task> tasks,
  String Function(Task task) labelFor,
) {
  final counts = <String, int>{};
  for (final task in tasks) {
    counts.update(labelFor(task), (value) => value + 1, ifAbsent: () => 1);
  }
  return _sortedGroups(dimension, counts);
}

List<_GroupSummary> _sortedGroups(String dimension, Map<String, int> counts) {
  final groups = [
    for (final entry in counts.entries)
      _GroupSummary(
        dimension: dimension,
        label: entry.key,
        count: entry.value,
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
  return groups;
}

class _GroupSummary {
  const _GroupSummary({
    required this.dimension,
    required this.label,
    required this.count,
  });

  final String dimension;
  final String label;
  final int count;
}

class _GroupSummaryPill extends StatelessWidget {
  const _GroupSummaryPill({required this.groups});

  final List<_GroupSummary> groups;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final first = groups.first;
    final extra = groups.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${first.dimension} ',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            '${first.label} ${first.count}',
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (extra > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$extra',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 14, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
