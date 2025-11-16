import 'dart:ui';

import 'package:eisen/core/platform/platform_utils.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/ui/app_text_scale.dart';
import 'package:eisen/core/ui/ui_breakpoints.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/stats_page.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/inspector_drawer.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/minimap.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/profile_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/quadrant_empty_placeholder.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet_compact.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/tasks/presentation/add_task_sheet.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/l10n/app_localizations_en.dart';
import 'package:eisen/theme/density.dart';
import 'package:eisen/ui/matrix/matrix_desktop.dart';
import 'package:eisen/utils/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Removed FAB + coachmark imports; using single CTA in bottom bar

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
  Size? _lastSize;
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
    final theme = Theme.of(context);
    final tokens = theme.extension<GlassTokens>() ??
        GlassTokens(
          glassBg: theme.colorScheme.surface,
          blur: 12,
          radius: 16,
          q1: Colors.transparent,
          q2: Colors.transparent,
          q3: Colors.transparent,
          q4: Colors.transparent,
          halo: Colors.transparent,
        );
    final ctrl = ref.read(matrixControllerProvider.notifier);
    // Minimize rebuild noise via .select
    final zoom = ref.watch(matrixZoomProvider);
    final themeMode =
        ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final compact =
        ref.watch(matrixControllerProvider.select((s) => s.compact));
    final showAxisLegends =
        ref.watch(matrixControllerProvider.select((s) => s.showAxisLegends));
    final minimal =
        ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final tasks = ref.watch(matrixTasksProvider);
    final selectedId =
        ref.watch(matrixControllerProvider.select((s) => s.selectedId));

    // Safe lookup for selected task (may be deleted externally)
    final selectedTask = selectedId == null
        ? null
        : (tasks.indexWhere((t) => t.id == selectedId) == -1
            ? null
            : tasks.firstWhere((t) => t.id == selectedId));

    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    // Trigger recompute when size changes (orientation/resize)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_lastSize != screenSize) {
        _lastSize = screenSize;
        ref.read(matrixControllerProvider.notifier).notifyLayoutRecompute();
      }
    });
    final legendsVisible =
        showAxisLegends && zoom == null && screenWidth >= 600;
    // AppTextScale applied
    final prefsUi = ref.watch(uiPrefsProvider);
    final uiTsf = AppTextScale.of(context, prefsUi);
    final isExtremeScale = AppTextScale.isExtreme(context, prefsUi);
    final axisHeaderHeight = isExtremeScale ? 48.0 : 40.0;

    final viewMode = ref.watch(uiPrefsProvider).viewMode; // 'treemap' | 'list'
    final isDesktopGrid = screenWidth >= bpDesktop && viewMode == 'list';
    // Show top-level navigation actions on all sizes; layout adapts inside AppToolbar.
    final showTopStats = true;
    final showTopSettings = true;
    final showTopWorkflow = true;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          top: true,
          bottom: false,
          child: AppToolbar(
            onToggleTheme: ctrl.toggleTheme,
            onQuery: ctrl.setQuery,
            themeMode: themeMode,
            minimal: minimal,
            onToggleMinimal: ctrl.toggleMinimal,
            // Always allow Workflow in the top menu on wide layouts.
            // On mobile, we only keep the bottom-nav entry.
            showWorkflowPlan: true,
            onOpenWorkflow: showTopWorkflow
                ? () {
                    if (!ref.read(uiPrefsProvider).workflowPlanEnabled) {
                      final isEs =
                          Localizations.localeOf(context).languageCode == 'es';
                      final msg = isEs
                          ? 'Activa \"Workflow plan\" en Ajustes'
                          : 'Enable \"Workflow plan\" in Settings';
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      return;
                    }
                    context.push('/list-mode');
                }
                : null,
            onOpenStats: showTopStats
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatsPage(),
                      ),
                    )
                : null,
            onOpenCompleted: () => context.go('/completed-matrix'),
            onOpenProfile: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              builder: (_) => const ProfileSheet(),
            ),
            onExitZoom: () {
              ctrl.setZoom(null);
              ctrl.setPresentQuadrant(Quadrant.q2);
              ctrl.select(null);
              ctrl.setQuery('');
              ctrl.invalidateLayout();
            },
            canExitZoom: zoom != null,
            onOpenSettings: showTopSettings
                ? () {
                    if (isDesktop) {
                      context.push('/settings');
                    } else {
                      final width = MediaQuery.sizeOf(context).width;
                      final isMobile = width < 600;
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => isMobile
                            ? SettingsSheetCompact(
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
                                        content: Text(
                                            '\u2728 Tareas demo restauradas (20 tareas)'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              )
                            : SettingsSheet(
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
                                        content: Text(
                                            '\u2728 Tareas demo restauradas (20 tareas)'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                      );
                    }
                  }
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: MediaQuery(
          // AppTextScale applied: scale general UI using prefs
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(uiTsf)),
          child: Padding(
            // Slightly reduce bottom spacing above the bottom bar on compact layouts.
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              screenWidth < 600 ? 8 : 16,
            ),
            child: isDesktopGrid
                ? _buildDesktopGrid(context, tokens, tasks)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (legendsVisible)
                        // AppTextScale applied: isolated + scaled legends
                        RepaintBoundary(
                          child: _LeftAxisLegends(
                            minimal: minimal,
                            textScale: uiTsf,
                            headerHeight: axisHeaderHeight,
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (legendsVisible)
                              // AppTextScale applied: isolated + scaled legends
                              RepaintBoundary(
                                child: _TopAxisLegends(
                                  minimal: minimal,
                                  textScale: uiTsf,
                                  headerHeight: axisHeaderHeight,
                                ),
                              ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(tokens.radius),
                                child: Stack(
                                  children: [
                                    // Removed Beta banner
                                    Positioned.fill(
                                      child: minimal
                                          ? const SizedBox.expand()
                                          : BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: tokens.blur,
                                                  sigmaY: tokens.blur),
                                              child: const SizedBox.expand(),
                                            ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: minimal
                                            ? Colors.transparent
                                            : tokens
                                                .glassBg, // TEMP: transparent to see tiles
                                        borderRadius: BorderRadius.circular(
                                            tokens.radius),
                                        border: minimal
                                            ? Border.all(
                                                color: Colors.transparent,
                                                width: 0)
                                            : Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.08),
                                                width: 1),
                                        boxShadow: minimal
                                            ? const []
                                            : [
                                                BoxShadow(
                                                    color: tokens.halo
                                                        .withValues(
                                                            alpha: 0.15),
                                                    blurRadius: 24,
                                                    spreadRadius: 2)
                                              ],
                                      ),
                                    ),
                                    // TEMP: Disabled grayscale filter to see tile colors
                                    ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.srcOver),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = Size(
                                              constraints.maxWidth,
                                              constraints.maxHeight);
                                          // Recompute incrementally based on current viewport
                                          final dynamicLayout = ctrl
                                              .computeLayout(viewport: size);
                                          final suggested =
                                              ctrl.suggestedTopSpots;
                                          // Compute user text scale; clamp tighter for treemap readability
                                          final prefs =
                                              ref.watch(uiPrefsProvider);
                                          final tileTsf =
                                              AppTextScale.forTreemap(
                                                  context, prefs);
                                          return clampTreemapTSF(context,
                                              child: Stack(
                                                children: [
                                                  AnimatedSwitcher(
                                                    duration: const Duration(
                                                        milliseconds: 240),
                                                    switchInCurve:
                                                        Curves.easeOutCubic,
                                                    switchOutCurve:
                                                        Curves.easeOutCubic,
                                                    child: TreemapCanvas(
                                                      key: ValueKey(
                                                          '${zoom}_${dynamicLayout.length}_${suggested.length}'),
                                                      tasks: tasks,
                                                      layout: dynamicLayout,
                                                      compact: compact,
                                                      suggestedIds: suggested,
                                                      minimal: minimal,
                                                      selectedId: selectedId,
                                                      zoom: zoom,
                                                      presentQuadrant: zoom ??
                                                          ref
                                                              .read(
                                                                  matrixControllerProvider)
                                                              .presentQuadrant,
                                                      textScale: tileTsf,
                                                      inlineEditId:
                                                          _inlineEditId,
                                                      onInlineSubmit:
                                                          (id, title) {
                                                        ctrl.updateTask(
                                                            id,
                                                            (t) => t.copyWith(
                                                                title: title));
                                                        setState(() =>
                                                            _inlineEditId =
                                                                null);
                                                      },
                                                      onInlineCancel: (id) {
                                                        final idx = tasks
                                                            .indexWhere((e) =>
                                                                e.id == id);
                                                        if (idx != -1) {
                                                          final t = tasks[idx];
                                                          if (t.title ==
                                                                  'New Task' &&
                                                              (t.notes ==
                                                                      null ||
                                                                  t.notes!
                                                                      .isEmpty)) {
                                                            ctrl.deleteTask(id);
                                                          }
                                                        }
                                                        setState(() =>
                                                            _inlineEditId =
                                                                null);
                                                      },
                                                      onTap: (id) {
                                                        ctrl.select(id);
                                                        if (id != null) {
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback(
                                                                  (_) => _scaffoldKey
                                                                      .currentState
                                                                      ?.openEndDrawer());
                                                        }
                                                      },
                                                      onDropToQuadrant:
                                                          (id, q) {
                                                        final idx = tasks
                                                            .indexWhere((t) =>
                                                                t.id == id);
                                                        if (idx == -1) return;
                                                        final prev =
                                                            tasks[idx].quadrant;
                                                        if (prev == q) {
                                                          return; // no-op
                                                        }
                                                        ctrl.moveTaskToQuadrant(
                                                            id, q);
                                                        final qName = q.name
                                                            .toUpperCase();
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .hideCurrentSnackBar();
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Tarea movida a $qName'),
                                                            action:
                                                                SnackBarAction(
                                                              label: 'Deshacer',
                                                              onPressed: () {
                                                                ctrl.moveTaskToQuadrant(
                                                                    id, prev);
                                                              },
                                                            ),
                                                            duration:
                                                                const Duration(
                                                                    seconds: 4),
                                                          ),
                                                        );
                                                      },
                                                      onDoubleTapQuadrant: (q) {
                                                        ctrl.setZoom(zoom == q
                                                            ? null
                                                            : q);
                                                        ctrl.setPresentQuadrant(
                                                            q);
                                                        ctrl.invalidateLayout();
                                                      },
                                                    ),
                                                  ),
                                                  if (dynamicLayout
                                                      .isEmpty) ...[
                                                    // Quadrant-specific placeholders to guide first use
                                                    Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      width: size.width / 2,
                                                      height: size.height / 2,
                                                      child:
                                                          const QuadrantEmptyPlaceholder(
                                                        title:
                                                            'Q1 · Urgente e Importante',
                                                        hint:
                                                            'No tienes tareas aquí. Usa “Entrada”.',
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: size.width / 2,
                                                      top: 0,
                                                      width: size.width / 2,
                                                      height: size.height / 2,
                                                      child:
                                                          const QuadrantEmptyPlaceholder(
                                                        title:
                                                            'Q2 · No Urgente e Importante',
                                                        hint:
                                                            'Planifica aquí objetivos clave.',
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0,
                                                      top: size.height / 2,
                                                      width: size.width / 2,
                                                      height: size.height / 2,
                                                      child:
                                                          const QuadrantEmptyPlaceholder(
                                                        title:
                                                            'Q3 · Urgente y No Importante',
                                                        hint:
                                                            'Delegables o de baja prioridad.',
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: size.width / 2,
                                                      top: size.height / 2,
                                                      width: size.width / 2,
                                                      height: size.height / 2,
                                                      child:
                                                          const QuadrantEmptyPlaceholder(
                                                        title:
                                                            'Q4 · No Urgente y No Importante',
                                                        hint:
                                                            'Evita o elimina distracciones.',
                                                      ),
                                                    ),
                                                  ],
                                                  if (dynamicLayout
                                                      .isNotEmpty) ...[
                                                    // Show placeholders for empty quadrants even when others have tasks
                                                    if (!tasks.any((t) =>
                                                        t.completedAt == null &&
                                                        t.quadrant ==
                                                            Quadrant.q1))
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        width: size.width / 2,
                                                        height: size.height / 2,
                                                        child:
                                                            const QuadrantEmptyPlaceholder(
                                                          title:
                                                              'Q1 · Urgente e Importante',
                                                          hint:
                                                              'No tienes tareas aquí. Usa “Entrada”.',
                                                        ),
                                                      ),
                                                    if (!tasks.any((t) =>
                                                        t.completedAt == null &&
                                                        t.quadrant ==
                                                            Quadrant.q2))
                                                      Positioned(
                                                        left: size.width / 2,
                                                        top: 0,
                                                        width: size.width / 2,
                                                        height: size.height / 2,
                                                        child:
                                                            const QuadrantEmptyPlaceholder(
                                                          title:
                                                              'Q2 · No Urgente e Importante',
                                                          hint:
                                                              'Planifica aquí objetivos clave.',
                                                        ),
                                                      ),
                                                    if (!tasks.any((t) =>
                                                        t.completedAt == null &&
                                                        t.quadrant ==
                                                            Quadrant.q3))
                                                      Positioned(
                                                        left: 0,
                                                        top: size.height / 2,
                                                        width: size.width / 2,
                                                        height: size.height / 2,
                                                        child:
                                                            const QuadrantEmptyPlaceholder(
                                                          title:
                                                              'Q3 · Urgente y No Importante',
                                                          hint:
                                                              'Delegables o de baja prioridad.',
                                                        ),
                                                      ),
                                                    if (!tasks.any((t) =>
                                                        t.completedAt == null &&
                                                        t.quadrant ==
                                                            Quadrant.q4))
                                                      Positioned(
                                                        left: size.width / 2,
                                                        top: size.height / 2,
                                                        width: size.width / 2,
                                                        height: size.height / 2,
                                                        child:
                                                            const QuadrantEmptyPlaceholder(
                                                          title:
                                                              'Q4 · No Urgente y No Importante',
                                                          hint:
                                                              'Evita o elimina distracciones.',
                                                        ),
                                                      ),
                                                  ],
                                                ],
                                              ));
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
      ),
      endDrawer: selectedTask == null
          ? null
          : InspectorDrawer(
              key: ValueKey(selectedTask.id),
              task: selectedTask,
              onChanged: (t) => ctrl.updateTask(t.id, (_) => t),
              onDelete: () => ctrl.deleteTask(selectedTask.id),
              onComplete: () {
                ctrl.markTaskDone(selectedTask.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('¡Tarea completada!'),
                    duration: Duration(milliseconds: 900)));
              },
            ),
      bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(uiTsf)),
          child: screenWidth >= 600
              ? _BottomActionBar(
                  highScale: isExtremeScale,
                  onNew: () => _openAddTaskSheet(context),
                  onNewInQuadrant: (q) {
                    ctrl.setZoom(q);
                    _openAddTaskSheet(context);
                  },
                  minimap: Minimap(
                    zoom: zoom,
                    tasks: tasks,
                    onSelectQuadrant: (q) {
                      ctrl.setZoom(q);
                      ctrl.setPresentQuadrant(q);
                      ctrl.invalidateLayout();
                    },
                    onFullView: () {
                      ctrl.setZoom(null);
                      ctrl.setPresentQuadrant(Quadrant.q2);
                      ctrl.select(null);
                      ctrl.setQuery('');
                      ctrl.invalidateLayout();
                    },
                  ),
                )
              : _buildMobileBottomNav(context, tokens)),
    );
  }

  Widget _buildDesktopGrid(
      BuildContext context, GlassTokens tokens, List<Task> tasks) {
    final w = MediaQuery.sizeOf(context).width;
    final densityPref = ref.watch(uiPrefsProvider).densityPreset;
    final DensityPreset preset = () {
      if (densityPref != 'auto') {
        switch (densityPref) {
          case 'compact':
            return DensityPreset.compact;
          case 'ultra':
            return DensityPreset.ultra;
          case 'comfy':
          default:
            return DensityPreset.comfy;
        }
      }
      if (w >= bpWidescreen) return DensityPreset.ultra;
      if (w >= bpDesktop) return DensityPreset.compact;
      return DensityPreset.comfy;
    }();

    final theme = Theme.of(context);
    final filtered =
        tasks.where((t) => t.completedAt == null).toList(growable: false);
    final q1 = filtered
        .where((t) => t.quadrant == Quadrant.q1)
        .toList(growable: false);
    final q2 = filtered
        .where((t) => t.quadrant == Quadrant.q2)
        .toList(growable: false);
    final q3 = filtered
        .where((t) => t.quadrant == Quadrant.q3)
        .toList(growable: false);
    final q4 = filtered
        .where((t) => t.quadrant == Quadrant.q4)
        .toList(growable: false);

    return Theme(
      data: applyDensity(theme, preset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radius),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.06), width: 1),
          ),
          child: MatrixDesktop(
            q1: q1,
            q2: q2,
            q3: q3,
            q4: q4,
            onToggle: (task) {
              final ctrl = ref.read(matrixControllerProvider.notifier);
              final nowDone = task.completedAt == null;
              ctrl.updateTask(
                task.id,
                (t) => t.copyWith(completedAt: nowDone ? DateTime.now() : null),
              );
            },
            onOpen: (task) {
              final ctrl = ref.read(matrixControllerProvider.notifier);
              ctrl.select(task.id);
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scaffoldKey.currentState?.openEndDrawer());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context, GlassTokens tokens) {
    final ctrl = ref.read(matrixControllerProvider.notifier);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final compact = ref.watch(uiPrefsProvider).compact;
    final showAxisLegends = ref.watch(uiPrefsProvider).showAxisLegends;
    final minimal = ref.watch(uiPrefsProvider).minimal;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: Icons.bar_chart_rounded,
                label: isEs ? 'Stats' : 'Stats',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                ),
              ),
              _NavBarItem(
                icon: Icons.history,
                label: isEs ? 'Completas' : 'Completed',
                onTap: () => context.go('/completed-matrix'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FloatingActionButton(
                  heroTag: 'fab-entry-nav',
                  onPressed: () => _openAddTaskSheet(context),
                  elevation: 2,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
              _NavBarItem(
                icon: Icons.view_timeline,
                label: isEs ? 'Workflow' : 'Workflow',
                onTap: () {
                  if (!ref.read(uiPrefsProvider).workflowPlanEnabled) {
                    final msg = isEs
                        ? 'Activa "Workflow plan" en Ajustes'
                        : 'Enable "Workflow plan" in Settings';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                    return;
                  }
                  context.push('/list-mode');
                },
              ),
              _NavBarItem(
                icon: Icons.settings,
                label: isEs ? 'Ajustes' : 'Settings',
                onTap: () {
                  final width = MediaQuery.sizeOf(context).width;
                  final isMobile = width < 600;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => isMobile
                        ? SettingsSheetCompact(
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
                                    content: Text(
                                        '\u2728 Tareas demo restauradas (20 tareas)'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          )
                        : SettingsSheet(
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
                                    content: Text(
                                        '\u2728 Tareas demo restauradas (20 tareas)'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
  const _TopAxisLegends(
      {this.minimal = false,
      required this.textScale,
      required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            AppLocalizationsEn();
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                l10n.axisUrgent,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textScaleFactor: textScale,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.axisNotUrgent,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textScaleFactor: textScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftAxisLegends extends StatelessWidget {
  const _LeftAxisLegends(
      {this.minimal = false,
      required this.textScale,
      required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            AppLocalizationsEn();
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
            SizedBox(height: headerHeight),
            // Two equal halves for vertical centering within each quadrant
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      l10n.axisImportant,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textScaleFactor: textScale,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      l10n.axisNotImportant,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textScaleFactor: textScale,
                    ),
                  ),
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
  const _BottomActionBar({
    required this.onNew,
    required this.onNewInQuadrant,
    this.minimap,
    this.highScale = false,
  });
  final VoidCallback onNew;
  final void Function(Quadrant q) onNewInQuadrant;
  final Widget? minimap;
  // AppTextScale applied: adjusts paddings for high scales
  final bool highScale;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final entryLabel = isEs ? 'Entrada' : 'Entry';
    return SafeArea(
      child: Container(
        // Reduce vertical padding to make the bar more compact on mobile
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          // Increase vertical padding slightly when scale is extreme
          vertical: highScale ? 10 : 6,
        ),
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
            final isNarrow = constraints.maxWidth < 400;

            return SizedBox(
              // More compact height on very narrow screens
              height: isNarrow ? 44 : 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered primary action button (Entrada)
                  Semantics(
                    button: true,
                    enabled: true,
                    label: entryLabel,
                    child: isNarrow
                        // Icon-only CTA on very small widths
                        ? IconButton(
                            onPressed: onNew,
                            tooltip: entryLabel,
                            icon: const Icon(Icons.add),
                          )
                        : FilledButton.icon(
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
