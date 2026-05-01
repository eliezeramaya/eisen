import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/tasks/context_aware/application/context_aware_tasks_controller.dart';
import 'package:eisen/features/tasks/context_aware/application/contextual_treemap_layout.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:eisen/features/tasks/context_aware/presentation/contextual_treemap_palette.dart';
import 'package:eisen/features/tasks/context_aware/presentation/widgets/context_aware_task_card.dart';
import 'package:eisen/features/tasks/context_aware/presentation/widgets/contextual_treemap_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContextAwareTasksPage extends ConsumerStatefulWidget {
  const ContextAwareTasksPage({super.key});

  @override
  ConsumerState<ContextAwareTasksPage> createState() =>
      _ContextAwareTasksPageState();
}

class _ContextAwareTasksPageState extends ConsumerState<ContextAwareTasksPage> {
  bool _showAll = false;
  String? _selectedTaskId;
  ContextTreemapGroup? _mobileGroupOverride;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(matrixTasksProvider).isEmpty) {
        ref.read(matrixControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';
    final controller = ref.read(contextAwareTasksControllerProvider.notifier);
    final contextState = ref.watch(contextAwareTasksControllerProvider);
    final rankedTasks = ref.watch(rankedContextAwareTasksProvider);
    final filteredTasks = _showAll
        ? rankedTasks
        : rankedTasks.where((task) => task.score >= 0.28).take(12).toList();
    final hasNoTasks = rankedTasks.isEmpty;
    final isCompact = !deviceClassFromContext(context).isExpandedUp;
    final sections = buildContextTreemapSections(
      rankedTasks: filteredTasks,
      context: contextState,
    );
    final focusedGroup =
        isCompact ? _resolveMobileGroup(sections, contextState) : null;
    final layout = buildContextTreemapLayout(
      sections: sections,
      focusedGroup: focusedGroup,
    );
    final visibleTasks = layout.sections
        .expand((section) => section.tiles.map((tile) => tile.seed.rankedTask))
        .toList(growable: false);
    final selectedTask = _resolveSelectedTask(visibleTasks);
    final treemapHeight = isCompact ? 470.0 : 620.0;

    return Scaffold(
      backgroundColor: ContextualTreemapPalette.background,
      appBar: AppBar(
        title: Text(
          isEs ? 'Tareas por contexto' : 'Context-aware tasks',
        ),
        backgroundColor: ContextualTreemapPalette.background,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll
                  ? (isEs ? 'Ver sugeridas' : 'Top matches')
                  : (isEs ? 'Ver todas' : 'See all'),
            ),
          ),
          PopupMenuButton<ContextPermissionState>(
            icon: const Icon(Icons.tune_rounded),
            onSelected: controller.setPermissionState,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ContextPermissionState.granted,
                child: Text(isEs ? 'Permiso otorgado' : 'Permission granted'),
              ),
              PopupMenuItem(
                value: ContextPermissionState.denied,
                child: Text(isEs ? 'Permiso denegado' : 'Permission denied'),
              ),
              PopupMenuItem(
                value: ContextPermissionState.unknown,
                child: Text(isEs ? 'Permiso incierto' : 'Permission unknown'),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _HeroHeader(
                contextState: contextState,
                title: isEs
                    ? 'Mapa contextual de energia y foco'
                    : 'A calm map of focus and energy',
                subtitle: isEs
                    ? 'El treemap agrupa tus tareas por contexto y resalta lo que mejor encaja con este momento.'
                    : 'The treemap groups your tasks by context and highlights what best fits right now.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isEs ? 'Modo automatico' : 'Automatic mode'),
                      subtitle: Text(
                        contextState.isAutoMode
                            ? (isEs
                                ? 'El contexto se ajusta solo'
                                : 'Context updates automatically')
                            : (isEs
                                ? 'Tu decides el contexto activo'
                                : 'You force the active context'),
                      ),
                      value: contextState.isAutoMode,
                      onChanged: controller.setAutoMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: contextState.isAutoMode
                        ? controller.refreshAutomaticContext
                        : null,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(isEs ? 'Actualizar' : 'Refresh'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: contextState.isAutoMode &&
                      contextState.permissionState ==
                          ContextPermissionState.denied
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _PermissionBanner(
                        onSwitchToManual: () => controller.setAutoMode(false),
                        onAllow: () => controller
                            .setPermissionState(ContextPermissionState.granted),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: contextState.isAutoMode
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _ManualContextSelector(
                        selectedTag: contextState.currentLocationTag,
                        onSelected: (tag) {
                          setState(() {
                            _mobileGroupOverride =
                                contextTagToTreemapGroup(tag);
                          });
                          controller.selectManualContext(tag);
                        },
                      ),
                    ),
            ),
          ),
          if (hasNoTasks)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: isEs ? 'Todavia no hay tareas' : 'No tasks yet',
                subtitle: isEs
                    ? 'La pantalla usa las tareas reales del repositorio. Puedes cargar el set demo para probar el ranking contextual.'
                    : 'This screen reads the real task list. Load the demo set to inspect contextual ranking.',
                actionLabel: isEs ? 'Cargar demo' : 'Load demo',
                onAction: () =>
                    ref.read(matrixControllerProvider.notifier).resetToDemo(),
              ),
            )
          else if (filteredTasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: isEs
                    ? 'No hay coincidencias fuertes'
                    : 'No strong contextual matches',
                subtitle: isEs
                    ? 'Prueba otro contexto o usa "Ver todas" para revisar el backlog completo.'
                    : 'Try another context or use "See all" to inspect the full backlog.',
                actionLabel: isEs ? 'Ver todas' : 'See all',
                onAction: () => setState(() => _showAll = true),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContextSummaryBar(
                        contextState: contextState,
                        totalTaskCount: rankedTasks.length,
                        visibleTaskCount: visibleTasks.length,
                        topRankedTask: selectedTask ?? layout.topRankedTask,
                        showAll: _showAll,
                        isCompact: isCompact,
                      ),
                      if (isCompact && sections.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MobileContextGroupChips(
                          sections: sections,
                          selectedGroup: focusedGroup ?? sections.first.group,
                          onSelected: (group) {
                            setState(() {
                              _mobileGroupOverride = group;
                              _selectedTaskId = null;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: treemapHeight,
                        child: ContextualTreemapView(
                          layout: layout,
                          compact: isCompact,
                          selectedTaskId: selectedTask?.task.id,
                          onTaskSelected: (task) {
                            setState(() => _selectedTaskId = task.task.id);
                          },
                        ),
                      ),
                      if (selectedTask != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          isEs ? 'Tarea destacada' : 'Highlighted task',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ContextualTreemapPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(selectedTask.task.id),
                            child:
                                ContextAwareTaskCard(rankedTask: selectedTask),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ContextTreemapGroup? _resolveMobileGroup(
    List<ContextTreemapSection> sections,
    ContextState contextState,
  ) {
    if (sections.isEmpty) return null;
    if (_mobileGroupOverride != null &&
        sections.any((section) => section.group == _mobileGroupOverride)) {
      return _mobileGroupOverride;
    }

    final activeGroup =
        contextTagToTreemapGroup(contextState.currentLocationTag);
    if (sections.any((section) => section.group == activeGroup)) {
      return activeGroup;
    }

    return sections.first.group;
  }

  RankedContextTask? _resolveSelectedTask(
      List<RankedContextTask> visibleTasks) {
    if (visibleTasks.isEmpty) return null;
    final selectedId = _selectedTaskId;
    if (selectedId != null) {
      for (final task in visibleTasks) {
        if (task.task.id == selectedId) return task;
      }
    }
    return visibleTasks.first;
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.contextState,
    required this.title,
    required this.subtitle,
  });

  final ContextState contextState;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeLabel = contextState.isAutoMode ? 'AUTO' : 'MANUAL';
    final permissionLabel = switch (contextState.permissionState) {
      ContextPermissionState.granted => 'GPS OK',
      ContextPermissionState.denied => 'NO GPS',
      ContextPermissionState.unknown => 'GPS ?',
    };
    final contextLabel = localizedContextTag(
      context,
      contextState.currentLocationTag,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            ContextualTreemapPalette.mistGreen,
            ContextualTreemapPalette.surfaceElevated,
            ContextualTreemapPalette.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ContextualTreemapPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                label: modeLabel,
                icon: Icons.motion_photos_auto_rounded,
              ),
              _HeaderChip(label: contextLabel, icon: Icons.place_rounded),
              _HeaderChip(
                label: permissionLabel,
                icon: Icons.shield_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: ContextualTreemapPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: ContextualTreemapPalette.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextSummaryBar extends StatelessWidget {
  const _ContextSummaryBar({
    required this.contextState,
    required this.totalTaskCount,
    required this.visibleTaskCount,
    required this.topRankedTask,
    required this.showAll,
    required this.isCompact,
  });

  final ContextState contextState;
  final int totalTaskCount;
  final int visibleTaskCount;
  final RankedContextTask? topRankedTask;
  final bool showAll;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final topLabel = topRankedTask?.task.title ??
        (isEs ? 'Sin tarea destacada' : 'No highlighted task');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ContextualTreemapPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ContextualTreemapPalette.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _SummaryPill(
            icon: Icons.place_outlined,
            label:
                localizedContextTag(context, contextState.currentLocationTag),
            value: contextState.isAutoMode
                ? (isEs ? 'Automatico' : 'Automatic')
                : (isEs ? 'Manual' : 'Manual'),
          ),
          _SummaryPill(
            icon: Icons.grid_view_rounded,
            label: isEs ? 'Visible' : 'Visible',
            value: '$visibleTaskCount/$totalTaskCount',
          ),
          _SummaryPill(
            icon: Icons.tips_and_updates_outlined,
            label:
                showAll ? (isEs ? 'Vista' : 'View') : (isEs ? 'Modo' : 'Mode'),
            value: showAll
                ? (isEs ? 'Todas' : 'All tasks')
                : (isEs ? 'Sugeridas' : 'Suggested'),
          ),
          if (!isCompact)
            _SummaryPill(
              icon: Icons.auto_awesome_rounded,
              label: isEs ? 'Top match' : 'Top match',
              value: topLabel,
              expanded: true,
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints:
          expanded ? const BoxConstraints(minWidth: 240, maxWidth: 420) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ContextualTreemapPalette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ContextualTreemapPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: ContextualTreemapPalette.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ContextualTreemapPalette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ContextualTreemapPalette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!expanded) return child;
    return IntrinsicWidth(child: child);
  }
}

class _MobileContextGroupChips extends StatelessWidget {
  const _MobileContextGroupChips({
    required this.sections,
    required this.selectedGroup,
    required this.onSelected,
  });

  final List<ContextTreemapSection> sections;
  final ContextTreemapGroup selectedGroup;
  final ValueChanged<ContextTreemapGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: EisenSpacing.sm,
      runSpacing: EisenSpacing.sm,
      children: [
        for (final section in sections)
          ChoiceChip(
            label: Text(_groupLabel(context, section.group)),
            selected: selectedGroup == section.group,
            onSelected: (_) => onSelected(section.group),
          ),
      ],
    );
  }

  String _groupLabel(BuildContext context, ContextTreemapGroup group) {
    return localizedTreemapGroupLabel(context, group);
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextualTreemapPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ContextualTreemapPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: ContextualTreemapPalette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ContextualTreemapPalette.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.onSwitchToManual,
    required this.onAllow,
  });

  final VoidCallback onSwitchToManual;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ContextualTreemapPalette.alertSoft.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ContextualTreemapPalette.alertStrong.withValues(alpha: 0.36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEs ? 'Ubicacion no disponible' : 'Location unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ContextualTreemapPalette.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isEs
                ? 'El ranking baja a prioridad general. Puedes conceder permiso o pasar a modo manual para fijar el contexto.'
                : 'Ranking falls back to general priority. Grant permission or switch to manual mode to force a context.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ContextualTreemapPalette.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: onAllow,
                child: Text(isEs ? 'Permitir' : 'Allow'),
              ),
              OutlinedButton(
                onPressed: onSwitchToManual,
                child: Text(isEs ? 'Usar manual' : 'Use manual'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualContextSelector extends StatelessWidget {
  const _ManualContextSelector({
    required this.selectedTag,
    required this.onSelected,
  });

  final String selectedTag;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEs ? 'Contexto manual' : 'Manual context',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ContextualTreemapPalette.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in contextLocationPresets)
              ChoiceChip(
                label: Text(preset.labelFor(locale)),
                selected: selectedTag == preset.tag,
                onSelected: (_) => onSelected(preset.tag),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ContextualTreemapPalette.mistGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Icon(
                    Icons.layers_clear_rounded,
                    size: 34,
                    color: ContextualTreemapPalette.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ContextualTreemapPalette.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ContextualTreemapPalette.textSecondary,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
