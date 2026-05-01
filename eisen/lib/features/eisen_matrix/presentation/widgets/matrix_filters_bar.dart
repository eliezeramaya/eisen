import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/focus_space_repository.dart';
import '../../data/saved_matrix_views_repository.dart';
import '../../domain/focus_space.dart';
import '../../domain/matrix_view_filter.dart';
import '../../domain/matrix_view_mode.dart';
import '../../domain/saved_matrix_view.dart';
import '../controllers/matrix_controller.dart';
import '../controllers/matrix_view_filter_controller.dart';

class MatrixFiltersBar extends ConsumerWidget {
  const MatrixFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(matrixViewFilterProvider);
    final spacesAsync = ref.watch(focusSpacesStreamProvider);
    final savedViewsAsync = ref.watch(savedMatrixViewsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espacio: ${filter.focusSpace.name}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(filter),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _saveCurrentView(context, ref, filter),
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Guardar vista'),
              ),
              const SizedBox(width: 8),
              savedViewsAsync.when(
                data: (views) =>
                    _SavedViewsMenu(views: views, spacesAsync: spacesAsync),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TimeAndCompletionRow(filter: filter),
          const SizedBox(height: 12),
          const _ViewModeRow(),
        ],
      ),
    );
  }

  String _subtitle(MatrixViewFilter filter) {
    final base = filter.timeFilter.displayName;
    if (filter.onlyCompleted) {
      return '$base · Solo completadas';
    }
    return base;
  }

  Future<void> _saveCurrentView(
    BuildContext context,
    WidgetRef ref,
    MatrixViewFilter filter,
  ) async {
    final defaultName = _buildDefaultViewName(filter);
    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar vista'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                Navigator.of(ctx).pop();
              } else {
                Navigator.of(ctx).pop(value);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final repo = ref.read(savedMatrixViewsRepositoryProvider);
    final view = SavedMatrixView(
      id: id,
      name: name,
      focusSpaceId: filter.focusSpace.id,
      timeFilter: filter.timeFilter,
      referenceDate: filter.referenceDate,
      onlyCompleted: filter.onlyCompleted,
    );
    await repo.addSavedMatrixView(view);
  }

  String _buildDefaultViewName(MatrixViewFilter filter) {
    final base = '${filter.focusSpace.name} – ${filter.timeFilter.displayName}';
    if (filter.onlyCompleted) {
      return '$base completadas';
    }
    return base;
  }
}

class _TimeAndCompletionRow extends ConsumerWidget {
  const _TimeAndCompletionRow({required this.filter});
  final MatrixViewFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(matrixViewFilterProvider.notifier);
    final isCompact = !deviceClassFromContext(context).isExpandedUp;

    final timeSegments = MatrixTimeFilterType.values.map((type) {
      return ButtonSegment<MatrixTimeFilterType>(
        value: type,
        label: Text(type.displayName),
      );
    }).toList();

    final timeSelector = SegmentedButton<MatrixTimeFilterType>(
      segments: timeSegments,
      selected: {filter.timeFilter},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          controller.setTimeFilter(selection.first);
        }
      },
      showSelectedIcon: false,
    );

    final completedChip = FilterChip(
      label: const Text('Solo completadas'),
      selected: filter.onlyCompleted,
      onSelected: controller.setOnlyCompleted,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [timeSelector, const SizedBox(height: 8), completedChip],
      );
    }

    return Row(
      children: [
        Expanded(child: timeSelector),
        const SizedBox(width: 12),
        completedChip,
      ],
    );
  }
}

class _ViewModeRow extends ConsumerWidget {
  const _ViewModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(
      matrixControllerProvider.select((s) => s.viewMode),
    );
    final customLimit = ref.watch(
      matrixControllerProvider.select((s) => s.customTaskLimit),
    );
    final controller = ref.read(matrixControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = !deviceClassFromContext(context).isExpandedUp;
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    String labelFor(MatrixViewMode mode) {
      switch (mode) {
        case MatrixViewMode.top10:
          return 'Top 10';
        case MatrixViewMode.top25:
          return 'Top 25';
        case MatrixViewMode.top50:
          return 'Top 50';
        case MatrixViewMode.top100:
          return 'Top 100';
        case MatrixViewMode.all:
          return isEs ? 'Todas' : 'All';
        case MatrixViewMode.custom:
          return isEs ? 'Personalizado' : 'Custom';
      }
    }

    final segments = MatrixViewMode.values.map((m) {
      return ButtonSegment<MatrixViewMode>(
        value: m,
        label: Text(labelFor(m)),
      );
    }).toList();

    final selector = SegmentedButton<MatrixViewMode>(
      segments: segments,
      selected: {viewMode},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          controller.setViewMode(selection.first);
        }
      },
      showSelectedIcon: false,
    );

    final customControls = viewMode == MatrixViewMode.custom
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs
                    ? 'Mostrando las $customLimit tareas más importantes por cuadrante'
                    : 'Showing top $customLimit tasks per quadrant',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Slider(
                value: customLimit.toDouble().clamp(10, 100),
                min: 10,
                max: 100,
                divisions: 18,
                label: '$customLimit',
                onChanged: (v) => controller.setCustomTaskLimit(v.toInt()),
              ),
            ],
          )
        : const SizedBox.shrink();

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          selector,
          const SizedBox(height: 8),
          customControls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: selector),
        const SizedBox(width: 12),
        if (viewMode == MatrixViewMode.custom)
          SizedBox(
            width: 260,
            child: customControls,
          ),
      ],
    );
  }
}

class _SavedViewsMenu extends ConsumerWidget {
  const _SavedViewsMenu({required this.views, required this.spacesAsync});

  final List<SavedMatrixView> views;
  final AsyncValue<List<FocusSpace>> spacesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final label = isEs ? 'Vistas' : 'Views';

    return PopupMenuButton<String>(
      tooltip: label,
      icon: const Icon(Icons.bookmarks_outlined, size: 20),
      onSelected: (id) => _applyView(context, ref, id),
      itemBuilder: (ctx) => views
          .map(
            (v) => PopupMenuItem<String>(
              value: v.id,
              child: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  void _applyView(BuildContext context, WidgetRef ref, String id) {
    final view = views.firstWhere((v) => v.id == id, orElse: () => views.first);

    List<FocusSpace> spaces = const [FocusSpace.general];
    spacesAsync.whenData((value) {
      if (value.isNotEmpty) {
        spaces = value;
      }
    });

    final space = spaces.firstWhere(
      (s) => s.id == view.focusSpaceId,
      orElse: () => FocusSpace.general,
    );

    final controller = ref.read(matrixViewFilterProvider.notifier);
    controller.setFocusSpace(space);
    controller.setTimeFilter(view.timeFilter);
    controller.updateReferenceDate(view.referenceDate);
    controller.setOnlyCompleted(view.onlyCompleted);
  }
}
