import 'dart:ui';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/minimap.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/profile_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/inspector_drawer.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/task_editor_page.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/stats_page.dart';
import 'package:eisen/features/tasks/presentation/add_task_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/quadrant_empty_placeholder.dart';
import 'package:eisen/core/platform/platform_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/fab_add_task.dart';
import 'package:eisen/features/onboarding/domain/onboarding_provider.dart';
import 'package:eisen/features/onboarding/presentation/fab_coachmark.dart';


class MatrixPage extends ConsumerStatefulWidget {
  const MatrixPage({super.key});

  @override
  ConsumerState<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends ConsumerState<MatrixPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _inlineEditId;
  final _scrollController = ScrollController();
  bool _fabVisible = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(matrixControllerProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (dir == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final ctrl = ref.read(matrixControllerProvider.notifier);
    // Minimize rebuild noise via .select
    final zoom = ref.watch(matrixZoomProvider);
    final themeMode = ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final query = ref.watch(matrixControllerProvider.select((s) => s.query));
    final compact = ref.watch(matrixControllerProvider.select((s) => s.compact));
    final showAxisLegends = ref.watch(matrixControllerProvider.select((s) => s.showAxisLegends));
    final minimal = ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final tasks = ref.watch(matrixTasksProvider);
    final selectedId = ref.watch(matrixControllerProvider.select((s) => s.selectedId));

    // Safe lookup for selected task (may be deleted externally)
  final _selectedTask = selectedId == null
    ? null
    : (tasks.indexWhere((t) => t.id == selectedId) == -1 ? null : tasks.firstWhere((t) => t.id == selectedId));

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppToolbar(
          onToggleTheme: ctrl.toggleTheme,
          onQuery: ctrl.setQuery,
          themeMode: themeMode,
          minimal: minimal,
          onToggleMinimal: ctrl.toggleMinimal,
          onOpenStats: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsPage())),
          onOpenProfile: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => const ProfileSheet(),
          ),
          onExitZoom: () {
            ctrl.setZoom(null);
            ctrl.select(null);
            ctrl.setQuery('');
            ctrl.invalidateLayout();
          },
          canExitZoom: zoom != null,
          onOpenSettings: () {
            if (isDesktop) {
              context.push('/settings');
            } else {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SettingsSheet(
                  onToggleTheme: ctrl.toggleTheme,
                  onToggleDensity: ctrl.toggleCompact,
                  compact: compact,
                  showAxisLegends: showAxisLegends,
                  onToggleAxisLegends: ctrl.toggleAxisLegends,
                  minimal: minimal,
                  onToggleMinimal: ctrl.toggleMinimal,
                  onResetToDemo: () async {
                    await ctrl.resetToDemo();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('\u2728 Tareas demo restauradas (20 tareas)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showAxisLegends && zoom == null) _LeftAxisLegends(minimal: minimal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showAxisLegends && zoom == null) _TopAxisLegends(minimal: minimal),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radius),
                        child: Stack(
                          children: [
                            // Removed Beta banner
                            Positioned.fill(
                              child: minimal
                                  ? const SizedBox.expand()
                                  : BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: tokens.blur, sigmaY: tokens.blur),
                                      child: const SizedBox.expand(),
                                    ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: minimal ? Colors.transparent : tokens.glassBg, // TEMP: transparent to see tiles
                                borderRadius: BorderRadius.circular(tokens.radius),
                                border: minimal
                                    ? Border.all(color: Colors.transparent, width: 0)
                                    : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                                boxShadow: minimal
                                    ? const []
                                    : [BoxShadow(color: tokens.halo.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2)],
                              ),
                            ),
                            // TEMP: Disabled grayscale filter to see tile colors
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                                  // Recompute incrementally based on current viewport
                                  final dynamicLayout = ctrl.computeLayout(viewport: size);
                                  final suggested = ctrl.suggestedTopSpots;
                                  final l10n = AppLocalizations.of(context);
                                  return Stack(
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 240),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeOutCubic,
                                        child: TreemapCanvas(
                                          key: ValueKey('${zoom}_${dynamicLayout.length}_${suggested.length}'),
                                          tasks: tasks,
                                          layout: dynamicLayout,
                                          compact: compact,
                                          suggestedIds: suggested,
                                          minimal: minimal,
                                          selectedId: selectedId,
                                          zoom: zoom,
                                          presentQuadrant: zoom ?? ref.read(matrixControllerProvider).presentQuadrant,
                                          inlineEditId: _inlineEditId,
                                          onInlineSubmit: (id, title) {
                                            ctrl.updateTask(id, (t) => t.copyWith(title: title));
                                            setState(() => _inlineEditId = null);
                                          },
                                          onInlineCancel: (id) {
                                            final idx = tasks.indexWhere((e) => e.id == id);
                                            if (idx != -1) {
                                              final t = tasks[idx];
                                              if (t.title == 'New Task' && (t.notes == null || t.notes!.isEmpty)) {
                                                ctrl.deleteTask(id);
                                              }
                                            }
                                            setState(() => _inlineEditId = null);
                                          },
                                          onTap: (id) {
                                            ctrl.select(id);
                                            if (id != null) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) => _scaffoldKey.currentState?.openEndDrawer());
                                            }
                                          },
                                          onDropToQuadrant: (id, q) {
                                            final idx = tasks.indexWhere((t) => t.id == id);
                                            if (idx == -1) return;
                                            final prev = tasks[idx].quadrant;
                                            if (prev == q) return; // no-op
                                            ctrl.moveTaskToQuadrant(id, q);
                                            final qName = q.name.toUpperCase();
                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Tarea movida a $qName'),
                                                action: SnackBarAction(
                                                  label: 'Deshacer',
                                                  onPressed: () {
                                                    ctrl.moveTaskToQuadrant(id, prev);
                                                  },
                                                ),
                                                duration: const Duration(seconds: 4),
                                              ),
                                            );
                                          },
                                          onDoubleTapQuadrant: (q) {
                                            ctrl.setZoom(zoom == q ? null : q);
                                            ctrl.setPresentQuadrant(q);
                                            ctrl.invalidateLayout();
                                          },
                                        ),
                                      ),
                                      if (dynamicLayout.isEmpty) ...[
                                        // Quadrant-specific placeholders to guide first use
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          width: size.width / 2,
                                          height: size.height / 2,
                                          child: const QuadrantEmptyPlaceholder(
                                            title: 'Q1 · Urgente e Importante',
                                            hint: 'No tienes tareas aquí. Usa “Agregar tarea”.',
                                          ),
                                        ),
                                        Positioned(
                                          left: size.width / 2,
                                          top: 0,
                                          width: size.width / 2,
                                          height: size.height / 2,
                                          child: const QuadrantEmptyPlaceholder(
                                            title: 'Q2 · No Urgente e Importante',
                                            hint: 'Planifica aquí objetivos clave.',
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: size.height / 2,
                                          width: size.width / 2,
                                          height: size.height / 2,
                                          child: const QuadrantEmptyPlaceholder(
                                            title: 'Q3 · Urgente y No Importante',
                                            hint: 'Delegables o de baja prioridad.',
                                          ),
                                        ),
                                        Positioned(
                                          left: size.width / 2,
                                          top: size.height / 2,
                                          width: size.width / 2,
                                          height: size.height / 2,
                                          child: const QuadrantEmptyPlaceholder(
                                            title: 'Q4 · No Urgente y No Importante',
                                            hint: 'Evita o elimina distracciones.',
                                          ),
                                        ),
                                      ],
                                      if (dynamicLayout.isNotEmpty) ...[
                                        // Show placeholders for empty quadrants even when others have tasks
                                        if (!tasks.any((t) => t.completedAt == null && t.quadrant == Quadrant.q1))
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            width: size.width / 2,
                                            height: size.height / 2,
                                            child: const QuadrantEmptyPlaceholder(
                                              title: 'Q1 · Urgente e Importante',
                                              hint: 'No tienes tareas aquí. Usa “Agregar tarea”.',
                                            ),
                                          ),
                                        if (!tasks.any((t) => t.completedAt == null && t.quadrant == Quadrant.q2))
                                          Positioned(
                                            left: size.width / 2,
                                            top: 0,
                                            width: size.width / 2,
                                            height: size.height / 2,
                                            child: const QuadrantEmptyPlaceholder(
                                              title: 'Q2 · No Urgente e Importante',
                                              hint: 'Planifica aquí objetivos clave.',
                                            ),
                                          ),
                                        if (!tasks.any((t) => t.completedAt == null && t.quadrant == Quadrant.q3))
                                          Positioned(
                                            left: 0,
                                            top: size.height / 2,
                                            width: size.width / 2,
                                            height: size.height / 2,
                                            child: const QuadrantEmptyPlaceholder(
                                              title: 'Q3 · Urgente y No Importante',
                                              hint: 'Delegables o de baja prioridad.',
                                            ),
                                          ),
                                        if (!tasks.any((t) => t.completedAt == null && t.quadrant == Quadrant.q4))
                                          Positioned(
                                            left: size.width / 2,
                                            top: size.height / 2,
                                            width: size.width / 2,
                                            height: size.height / 2,
                                            child: const QuadrantEmptyPlaceholder(
                                              title: 'Q4 · No Urgente y No Importante',
                                              hint: 'Evita o elimina distracciones.',
                                            ),
                                          ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Removed quadrant quick-add buttons; using global FAB instead
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _selectedTask == null ? null : InspectorDrawer(
        key: ValueKey(_selectedTask.id),
        task: _selectedTask,
        onChanged: (t) => ctrl.updateTask(t.id, (_) => t),
        onDelete: () => ctrl.deleteTask(_selectedTask.id),
        onComplete: () {
          ctrl.markTaskDone(_selectedTask.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Tarea completada!'), duration: Duration(milliseconds: 900)));
        },
      ),
      bottomNavigationBar: _BottomActionBar(
        onNew: () {
          _openAddTaskSheet(context);
        },
        onNewInQuadrant: (q) {
          final id = ctrl.createTask(quadrant: q);
          ctrl.select(id);
          setState(() => _inlineEditId = id);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tarea creada en ${q.name.toUpperCase()}'), duration: const Duration(seconds: 3)),
          );
        },
        minimap: Minimap(
          zoom: zoom,
          minimal: minimal,
          tasks: tasks,
          onSelectQuadrant: (q) {
            ctrl.setZoom(q);
            ctrl.invalidateLayout();
          },
          onFullView: () {
            ctrl.setZoom(null);
            ctrl.select(null);
            ctrl.setQuery('');
            ctrl.invalidateLayout();
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: FabCoachmark(
        show: ref.watch(onboardingProvider.select((s) => s.showFabCoachmark)),
        child: FabAddTask(
          visible: _fabVisible,
          onPressed: () {
            ref.read(onboardingProvider.notifier).dismissFabCoachmark();
            _openAddTaskSheet(context);
          },
        ),
      ),
    );
  }
}

// Quick quadrant add removed in favor of global FAB

Future<void> _openAddTaskSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddTaskSheet(),
  );
}

class _TopAxisLegends extends StatelessWidget {
  final bool minimal;
  const _TopAxisLegends({this.minimal = false});
  static const double _kAxisHeaderHeight = 40.0;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return SizedBox(
      height: _kAxisHeaderHeight,
      child: Row(
        children: [
          Expanded(child: Center(child: Text(l10n.axisUrgent, style: style))),
          Expanded(child: Center(child: Text(l10n.axisNotUrgent, style: style))),
        ],
      ),
    );
  }
}

class _LeftAxisLegends extends StatelessWidget {
  final bool minimal;
  const _LeftAxisLegends({this.minimal = false});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return SizedBox(
      width: 64,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reserve the same vertical space as the top axis headers
            const SizedBox(height: _TopAxisLegends._kAxisHeaderHeight),
            // Two equal halves for vertical centering within each quadrant
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(quarterTurns: 3, child: Text(l10n.axisImportant, style: style)),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(quarterTurns: 3, child: Text(l10n.axisNotImportant, style: style)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onNew;
  final void Function(Quadrant q) onNewInQuadrant;
  final Widget? minimap;

  const _BottomActionBar({
    required this.onNew,
    required this.onNewInQuadrant,
    this.minimap,
  });

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final entryLabel = isEs ? 'Entrada' : 'Entry';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hideMinimap = constraints.maxWidth < 560;

            return SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered primary action button (Entrada)
                  Semantics(
                    button: true,
                    enabled: true,
                    label: entryLabel,
                    child: FilledButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add),
                      label: Text(entryLabel),
                    ),
                  ),

                  // Minimap pinned to the right when there's space
                  if (!hideMinimap && minimap != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: minimap!,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
