import 'dart:ui';

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/platform/platform_utils.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/theme/colors.dart';
import 'package:eisen/core/ui/app_text_scale.dart';
import 'package:eisen/core/ui/ui_breakpoints.dart';
import 'package:eisen/features/classification/presentation/category_color_service_factory.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_grouping_bar.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/demo/demo_tasks.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/treemap_viewport_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:eisen/features/eisen_matrix/application/semantic_treemap_builder.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/inspector_drawer.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/matrix_interactive_wrapper.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/minimap.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/profile_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/quadrant_empty_placeholder.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/semantic_treemap_view.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet_compact.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/zoom_indicator.dart';
import 'package:eisen/features/filters/presentation/widgets/category_filters_bar.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/insights/domain/nudge_controller.dart';
import 'package:eisen/features/insights_adaptive/domain/adaptive_providers.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
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

/// Score heurístico más reciente (ventana de 7 días).
final todayProductivityScoreProvider = FutureProvider<DailyProductivityScore?>((ref) async {
  final scoring = ref.read(productivityScoringServiceProvider);
  final now = DateTime.now();
  final to = DateTime(now.year, now.month, now.day);
  final from = to.subtract(const Duration(days: 6));
  final scores = await scoring.computeDailyScores(from: from, to: to);
  return scores.isNotEmpty ? scores.last : null;
});

final overloadRiskTodayProvider = FutureProvider<OverloadRisk>((ref) async {
  final scoring = ref.read(productivityScoringServiceProvider);
  return scoring.computeDailyOverloadRisk(DateTime.now());
});

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
    final themeMode = ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final compact = ref.watch(matrixControllerProvider.select((s) => s.compact));
    final showAxisLegends = ref.watch(matrixControllerProvider.select((s) => s.showAxisLegends));
    final minimal = ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final tasks = ref.watch(matrixTasksProvider);
    final visibleTasks = ref.watch(visibleMatrixTasksProvider);
    final selectedId = ref.watch(matrixControllerProvider.select((s) => s.selectedId));
    final isLoading = ref.watch(matrixControllerProvider.select((s) => s.isLoading));
    final advancedInsights = ref.watch(uiPrefsProvider.select((p) => p.advancedInsightsEnabled));

    // Safe lookup for selected task (may be deleted externally)
    final selectedTask = selectedId == null
        ? null
        : (tasks.indexWhere((t) => t.id == selectedId) == -1 ? null : tasks.firstWhere((t) => t.id == selectedId));

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
    final legendsVisible = showAxisLegends && zoom == null && screenWidth >= 600;
    // AppTextScale applied
    final prefsUi = ref.watch(uiPrefsProvider);
    final uiTsf = AppTextScale.of(context, prefsUi);
    final isExtremeScale = AppTextScale.isExtreme(context, prefsUi);
    // Slightly increased to avoid 1px overflow in the axis header row on mobile.
    final axisHeaderHeight = isExtremeScale ? 52.0 : 42.0;
    final viewMode = ref.watch(uiPrefsProvider).viewMode; // 'treemap' | 'list'
    final isDesktopGrid = screenWidth >= bpDesktop && viewMode == 'list';
    final workflowPlanEnabled = ref.watch(uiPrefsProvider.select((p) => p.workflowPlanEnabled));
    final isSearchOpen = ref.watch(matrixControllerProvider.select((s) => s.isSearchOpen));
    final searchQuery = ref.watch(matrixControllerProvider.select((s) => s.searchQuery));
    final showFocusFab = screenWidth < 600;
    ref.read(nudgeControllerProvider.notifier).loadNudges();
    final nudgesAsync = ref.watch(nudgeControllerProvider);
    final Nudge? firstNudge = nudgesAsync.value?.nudges.isNotEmpty == true ? nudgesAsync.value!.nudges.first : null;
    final nudgeCtrl = ref.read(nudgeControllerProvider.notifier);
    final scoreAsync =
        advancedInsights ? ref.watch(todayProductivityScoreProvider) : const AsyncData<DailyProductivityScore?>(null);
    final overloadRiskAsync = ref.watch(overloadRiskTodayProvider);
    final overloadRisk = overloadRiskAsync.maybeWhen(data: (v) => v, orElse: () => null);
    final classificationSettings = ref.watch(classificationSettingsControllerProvider);
    final categoryConfigs = ref.watch(categoryConfigControllerProvider);
    final semanticViewport = ref.watch(treemapViewportControllerProvider);
    final semanticViewportCtrl = ref.read(treemapViewportControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final restoredSearch = semanticViewport.activeSearchQuery;
      if (searchQuery.isEmpty && restoredSearch != null && restoredSearch.isNotEmpty) {
        ctrl.setSearchQuery(restoredSearch);
        return;
      }
      semanticViewportCtrl.syncSearchQuery(searchQuery);
    });
    final classificationCategoryColorService = buildClassificationCategoryColorService(
      categories: categoryConfigs,
      userColorOverrides: ref.watch(uiPrefsProvider).categoryColors,
    );
    final warningTasks =
        tasks.where((t) => t.completedAt == null && _procrastinationScore(t) >= 0.75).map((t) => t.id).toSet();
    final adaptiveProfileAsync = ref.watch(
      FutureProvider<UserProductivityProfile>((ref) {
        return ref.read(adaptivePolicyEngineProvider).getCurrentProfile();
      }),
    );
    final semanticScene = buildSemanticTreemapScene(
      tasks: visibleTasks,
      categories: categoryConfigs,
      viewport: semanticViewport,
      searchQuery: searchQuery,
    );
    TreemapSemanticNode? semanticSelectedNode;
    final selectedSemanticNodeId = semanticViewport.selectedNodeId;
    if (selectedSemanticNodeId != null) {
      for (final node in semanticScene.nodes) {
        if (node.id == selectedSemanticNodeId) {
          semanticSelectedNode = node;
          break;
        }
      }
    }
    final canExitSemantic = semanticViewport.zoomLevel != TreemapZoomLevel.global;
    final showSemanticMap = canExitSemantic;

    return PopScope<void>(
      canPop: zoom == null && !canExitSemantic,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (canExitSemantic) {
            _exitSemanticLevel(ctrl, semanticViewportCtrl, semanticViewport);
            return;
          }
          if (zoom != null) {
            ctrl.resetHomeView();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isSearchOpen ? 135 : 72),
          child: SafeArea(
            top: true,
            bottom: false,
            child: AppToolbar(
              onToggleTheme: ctrl.toggleTheme,
              onQuery: ctrl.setSearchQuery,
              themeMode: themeMode,
              minimal: minimal,
              onToggleMinimal: ctrl.toggleMinimal,
              isSearchOpen: isSearchOpen,
              searchQuery: searchQuery,
              onToggleSearch: ctrl.toggleSearch,
              viewMode: viewMode,
              showViewModeToggle: screenWidth >= bpDesktop,
              onToggleViewMode: () {
                ref.read(uiPrefsControllerProvider.notifier).toggleViewMode();
              },
              onOpenProfile: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                useSafeArea: true,
                builder: (_) => const ProfileSheet(),
              ),
              onOpenContextTasks: () => context.push('/context-aware-tasks'),
              onExitZoom: () => _exitSemanticLevel(ctrl, semanticViewportCtrl, semanticViewport),
              canExitZoom: zoom != null || canExitSemantic,
              onOpenStats: () => context.push('/stats'),
              onOpenFocus: () => context.push('/focus'),
              // When workflow plan is enabled in Settings > General, show the
              // Gantt/Workflow action in the top toolbar.
              showWorkflowPlan: workflowPlanEnabled,
              onOpenWorkflow: workflowPlanEnabled ? () => context.push('/workflow-plan') : null,
              onOpenSettings: () {
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
                                  SnackBar(
                                    content: Text(
                                      '\u2728 Tareas demo restauradas '
                                      '($kDemoTaskCount tareas)',
                                    ),
                                    duration: const Duration(seconds: 2),
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
                                  SnackBar(
                                    content: Text(
                                      '\u2728 Tareas demo restauradas '
                                      '($kDemoTaskCount tareas)',
                                    ),
                                    duration: const Duration(seconds: 2),
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
        ),
        floatingActionButton: showFocusFab
            ? canExitSemantic
                ? FloatingActionButton.extended(
                    heroTag: 'fab-view-all',
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Ver todo'),
                    onPressed: () {
                      semanticViewportCtrl.reset(
                        grouping: semanticViewport.grouping,
                        density: semanticViewport.density,
                      );
                      ctrl.resetHomeView();
                    },
                  )
                : FloatingActionButton.extended(
                    heroTag: 'fab-focus',
                    icon: const Icon(Icons.bolt),
                    label: const Text('Focus'),
                    onPressed: () => context.push('/focus'),
                  )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: MediaQuery(
            // AppTextScale applied: scale general UI using prefs
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(uiTsf)),
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
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.05),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: FadeTransition(
                                      opacity: curved,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildBanner(
                                  context: context,
                                  scoreAsync: scoreAsync,
                                  tasks: tasks,
                                  nudge: firstNudge,
                                  overloadRisk: overloadRisk,
                                  profileAsync: adaptiveProfileAsync,
                                  onDismissNudge: () {
                                    if (firstNudge != null) {
                                      nudgeCtrl.dismissNudge(firstNudge);
                                    }
                                  },
                                  onOpenStats: () => context.push('/stats'),
                                  onOpenQ2Picker: () => _openQ2Picker(context, tasks),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 2,
                                        child: LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                      )
                                    : const SizedBox(height: 2),
                              ),
                              const CategoryFiltersBar(
                                padding: EdgeInsets.only(bottom: 12),
                              ),
                              ClassificationGroupingBar(
                                tasks: visibleTasks,
                                categories: categoryConfigs,
                                settings: classificationSettings,
                              ),
                              _SemanticTreemapHeader(
                                viewport: semanticViewport,
                                scene: semanticScene,
                                onJumpToLevel: (level) {
                                  semanticViewportCtrl.jumpToLevel(level);
                                  if (level == TreemapZoomLevel.global) {
                                    ctrl.resetHomeView();
                                  }
                                },
                                onSelectGrouping: (grouping) {
                                  semanticViewportCtrl.setGrouping(grouping);
                                },
                                onSelectQuickFilter: (filter) {
                                  semanticViewportCtrl.setQuickFilter(
                                    semanticViewport.quickFilter == filter ? null : filter,
                                  );
                                },
                                onViewAll: () {
                                  semanticViewportCtrl.reset(
                                    grouping: semanticViewport.grouping,
                                    density: semanticViewport.density,
                                  );
                                  ctrl.resetHomeView();
                                },
                                onOpenReviewCenter: () => context.push('/classification-review'),
                                onFocusExactTask: semanticScene.exactTaskMatch == null
                                    ? null
                                    : () {
                                        final task = semanticScene.exactTaskMatch!;
                                        final qLabel = _quadrantLabel(context, task.quadrant);
                                        semanticViewportCtrl.enterQuadrant(
                                          task.quadrant,
                                          label: qLabel,
                                        );
                                        semanticViewportCtrl.openCategory(
                                          categoryId: task.categoryId ??
                                              (task.category ?? 'sin-categoria')
                                                  .trim()
                                                  .toLowerCase()
                                                  .replaceAll(' ', '-'),
                                          categoryLabel: task.category ?? task.categoryId ?? 'Sin categoria',
                                        );
                                        semanticViewportCtrl.focusTask(task);
                                        ctrl.setZoom(task.quadrant);
                                        ctrl.setPresentQuadrant(task.quadrant);
                                      },
                              ),
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
                                          color: minimal
                                              ? Colors.transparent
                                              : tokens.glassBg, // TEMP: transparent to see tiles
                                          borderRadius: BorderRadius.circular(tokens.radius),
                                          border: minimal
                                              ? Border.all(color: Colors.transparent, width: 0)
                                              : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                                          boxShadow: minimal
                                              ? const []
                                              : [
                                                  BoxShadow(
                                                      color: tokens.halo.withValues(alpha: 0.15),
                                                      blurRadius: 24,
                                                      spreadRadius: 2)
                                                ],
                                        ),
                                      ),
                                      // TEMP: Disabled grayscale filter to see tile colors
                                      ColorFiltered(
                                        colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                                            final prefs = ref.watch(uiPrefsProvider);
                                            final tileTsf = AppTextScale.forTreemap(context, prefs);
                                            // Use synchronous layout to preserve golden parity and avoid blank frames.
                                            final dynamicLayout =
                                                ctrl.computeLayoutSync(viewport: size, resetCache: true);
                                            final suggested = ctrl.suggestedTopSpots;
                                            return clampTreemapTSF(
                                              context,
                                              child: Stack(
                                                children: [
                                                  AnimatedSwitcher(
                                                    duration: const Duration(
                                                      milliseconds: 240,
                                                    ),
                                                    switchInCurve: Curves.easeOutCubic,
                                                    switchOutCurve: Curves.easeOutCubic,
                                                    child: showSemanticMap
                                                        ? Stack(
                                                            key: ValueKey(
                                                              'semantic-${semanticViewport.zoomLevel.name}-${semanticViewport.selectedNodeId}',
                                                            ),
                                                            children: [
                                                              Positioned.fill(
                                                                child: SemanticTreemapView(
                                                                  scene: semanticScene,
                                                                  selectedNodeId: semanticViewport.selectedNodeId,
                                                                  categoryColorService: classificationSettings
                                                                          .colorByCategory
                                                                      ? classificationCategoryColorService
                                                                      : ref.watch(uiPrefsProvider).categoryColorService,
                                                                  colorByCategory:
                                                                      classificationSettings.colorByCategory,
                                                                  showConfidenceIndicators:
                                                                      classificationSettings.showConfidenceIndicators,
                                                                  showAutoTags: classificationSettings.showAutoTags,
                                                                  onNodeSelected: (node) {
                                                                    semanticViewportCtrl.selectNode(
                                                                      node.id,
                                                                    );
                                                                    if (screenWidth < 900) {
                                                                      showModalBottomSheet<void>(
                                                                        context: context,
                                                                        showDragHandle: true,
                                                                        isScrollControlled: true,
                                                                        builder: (_) => SafeArea(
                                                                          top: false,
                                                                          child: Padding(
                                                                            padding: const EdgeInsets.all(16),
                                                                            child: SemanticTreemapDetailsCard(
                                                                              node: node,
                                                                              onOpen: () {
                                                                                Navigator.of(context).pop();
                                                                                _openSemanticNode(
                                                                                  context: context,
                                                                                  ctrl: ctrl,
                                                                                  viewportCtrl: semanticViewportCtrl,
                                                                                  viewport: semanticViewport,
                                                                                  node: node,
                                                                                );
                                                                              },
                                                                              onReviewLowConfidence: () {
                                                                                Navigator.of(context).pop();
                                                                                semanticViewportCtrl.setQuickFilter(
                                                                                    TreemapQuickFilter.lowConfidence);
                                                                                context.push('/classification-review');
                                                                              },
                                                                              onOpenTaskInspector: () {
                                                                                if (node.isTaskLeaf) {
                                                                                  final task = node.tasks.single;
                                                                                  ctrl.select(task.id);
                                                                                  Navigator.of(context).pop();
                                                                                  WidgetsBinding.instance
                                                                                      .addPostFrameCallback((_) =>
                                                                                          _scaffoldKey.currentState
                                                                                              ?.openEndDrawer());
                                                                                }
                                                                              },
                                                                              onMarkDone: () {
                                                                                if (node.isTaskLeaf) {
                                                                                  final task = node.tasks.single;
                                                                                  ctrl.markTaskDone(task.id);
                                                                                  Navigator.of(context).pop();
                                                                                }
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  onNodeOpen: (node) {
                                                                    _openSemanticNode(
                                                                      context: context,
                                                                      ctrl: ctrl,
                                                                      viewportCtrl: semanticViewportCtrl,
                                                                      viewport: semanticViewport,
                                                                      node: node,
                                                                    );
                                                                  },
                                                                  onOpenTaskInspector: (task) {
                                                                    ctrl.select(task.id);
                                                                    WidgetsBinding.instance.addPostFrameCallback((_) =>
                                                                        _scaffoldKey.currentState?.openEndDrawer());
                                                                  },
                                                                  onReviewLowConfidence: (node) {
                                                                    semanticViewportCtrl.setQuickFilter(
                                                                      TreemapQuickFilter.lowConfidence,
                                                                    );
                                                                    semanticViewportCtrl.selectNode(
                                                                      node.id,
                                                                    );
                                                                    context.push(
                                                                      '/classification-review',
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              if (semanticSelectedNode != null && screenWidth >= 920)
                                                                Positioned(
                                                                  top: 16,
                                                                  right: 16,
                                                                  bottom: 16,
                                                                  child: SemanticTreemapDetailsCard(
                                                                    node: semanticSelectedNode,
                                                                    onOpen: () {
                                                                      final node = semanticSelectedNode;
                                                                      if (node == null) {
                                                                        return;
                                                                      }
                                                                      _openSemanticNode(
                                                                        context: context,
                                                                        ctrl: ctrl,
                                                                        viewportCtrl: semanticViewportCtrl,
                                                                        viewport: semanticViewport,
                                                                        node: node,
                                                                      );
                                                                    },
                                                                    onReviewLowConfidence: () {
                                                                      semanticViewportCtrl.setQuickFilter(
                                                                        TreemapQuickFilter.lowConfidence,
                                                                      );
                                                                      context.push(
                                                                        '/classification-review',
                                                                      );
                                                                    },
                                                                    onOpenTaskInspector: () {
                                                                      final node = semanticSelectedNode;
                                                                      if (node == null || !node.isTaskLeaf) {
                                                                        return;
                                                                      }
                                                                      final task = node.tasks.single;
                                                                      ctrl.select(task.id);
                                                                      WidgetsBinding.instance.addPostFrameCallback(
                                                                          (_) => _scaffoldKey.currentState
                                                                              ?.openEndDrawer());
                                                                    },
                                                                    onMarkDone: () {
                                                                      final node = semanticSelectedNode;
                                                                      if (node == null || !node.isTaskLeaf) {
                                                                        return;
                                                                      }
                                                                      ctrl.markTaskDone(
                                                                        node.tasks.single.id,
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                            ],
                                                          )
                                                        : MatrixInteractiveWrapper(
                                                            key: ValueKey(
                                                              '${zoom}_${dynamicLayout.length}_${suggested.length}',
                                                            ),
                                                            enabled: !showSemanticMap,
                                                            child: TreemapCanvas(
                                                              tasks: visibleTasks,
                                                              layout: dynamicLayout,
                                                              compact: compact,
                                                              suggestedIds: suggested,
                                                              minimal: minimal,
                                                              selectedId: selectedId,
                                                              zoom: zoom,
                                                              presentQuadrant: zoom ??
                                                                  ref.read(matrixControllerProvider).presentQuadrant,
                                                              textScale: tileTsf,
                                                              minTileSizePx: ref
                                                                  .watch(
                                                                    uiPrefsProvider,
                                                                  )
                                                                  .minTileSizePx,
                                                              categoryColorService:
                                                                  classificationSettings.colorByCategory
                                                                      ? classificationCategoryColorService
                                                                      : ref
                                                                          .watch(
                                                                            uiPrefsProvider,
                                                                          )
                                                                          .categoryColorService,
                                                              colorByCategory: classificationSettings.colorByCategory,
                                                              showConfidenceIndicators:
                                                                  classificationSettings.showConfidenceIndicators,
                                                              showAutoTags: classificationSettings.showAutoTags,
                                                              inlineEditId: _inlineEditId,
                                                              lastMovedTaskId: ref
                                                                  .read(
                                                                    matrixControllerProvider,
                                                                  )
                                                                  .lastMovedTaskId,
                                                              loading: isLoading,
                                                              warningTaskIds: warningTasks,
                                                              onInlineSubmit: (id, title) {
                                                                ctrl.updateTask(
                                                                  id,
                                                                  (t) => t.copyWith(
                                                                    title: title,
                                                                  ),
                                                                );
                                                                setState(
                                                                  () => _inlineEditId = null,
                                                                );
                                                              },
                                                              onInlineCancel: (id) {
                                                                final idx = tasks.indexWhere(
                                                                  (e) => e.id == id,
                                                                );
                                                                if (idx != -1) {
                                                                  final t = tasks[idx];
                                                                  if (t.title == 'New Task' &&
                                                                      (t.notes == null || t.notes!.isEmpty)) {
                                                                    ctrl.deleteTask(
                                                                      id,
                                                                    );
                                                                  }
                                                                }
                                                                setState(
                                                                  () => _inlineEditId = null,
                                                                );
                                                              },
                                                              onTap: (id) {
                                                                ctrl.select(id);
                                                                if (id != null) {
                                                                  WidgetsBinding.instance.addPostFrameCallback((_) =>
                                                                      _scaffoldKey.currentState?.openEndDrawer());
                                                                }
                                                              },
                                                              onDropToQuadrant: (id, q) {
                                                                final idx = tasks.indexWhere(
                                                                  (t) => t.id == id,
                                                                );
                                                                if (idx == -1) {
                                                                  return;
                                                                }
                                                                final prev = tasks[idx].quadrant;
                                                                if (prev == q) {
                                                                  return;
                                                                }
                                                                ctrl.moveTaskToQuadrant(
                                                                  id,
                                                                  q,
                                                                );
                                                                final qName = q.name.toUpperCase();
                                                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Tarea movida a $qName',
                                                                    ),
                                                                    action: SnackBarAction(
                                                                      label: 'Deshacer',
                                                                      onPressed: () {
                                                                        ctrl.moveTaskToQuadrant(
                                                                          id,
                                                                          prev,
                                                                        );
                                                                      },
                                                                    ),
                                                                    duration: const Duration(
                                                                      seconds: 4,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              onDoubleTapQuadrant: (q) {
                                                                semanticViewportCtrl.enterQuadrant(
                                                                  q,
                                                                  label: _quadrantLabel(
                                                                    context,
                                                                    q,
                                                                  ),
                                                                );
                                                                ctrl.setZoom(q);
                                                                ctrl.setPresentQuadrant(
                                                                  q,
                                                                );
                                                                ctrl.invalidateLayout();
                                                              },
                                                              onLowConfidenceLongPress: (task) async {
                                                                final categories = ref.read(
                                                                  categoryConfigControllerProvider,
                                                                );
                                                                final meta = task.classificationMetadata ??
                                                                    ClassificationMetadata(
                                                                      categoryId: task.categoryId,
                                                                      entryKind: task.kind,
                                                                      timeHorizon: task.horizon ?? TimeHorizon.someday,
                                                                      energyLevel: task.energy ?? EnergyLevel.medium,
                                                                      priorityLevel: PriorityLevel.medium,
                                                                      confidenceScore: 0.4,
                                                                      confidenceLevel: ConfidenceLevel.low,
                                                                    );
                                                                final result =
                                                                    await showModalBottomSheet<QuickReclassifyResult>(
                                                                  context: context,
                                                                  isScrollControlled: true,
                                                                  builder: (_) => QuickReclassifySheet(
                                                                    metadata: meta,
                                                                    categories: categories,
                                                                  ),
                                                                );
                                                                if (result != null) {
                                                                  ctrl.updateTask(
                                                                    task.id,
                                                                    (t) => t.copyWith(
                                                                      categoryId: result.metadata.categoryId,
                                                                      classificationMetadata: result.metadata,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                  ),
                                                  const ZoomIndicator(),
                                                  if (!showSemanticMap && visibleTasks.isNotEmpty)
                                                    Positioned(
                                                      left: 12,
                                                      top: 12,
                                                      right: screenWidth < 720 ? 12 : 180,
                                                      child: GlobalSemanticSummaryStrip(
                                                        tasks: visibleTasks,
                                                      ),
                                                    ),
                                                  if (!showSemanticMap && dynamicLayout.isEmpty) ...[
                                                    Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      width: size.width / 2,
                                                      height: size.height / 2,
                                                      child: const QuadrantEmptyPlaceholder(
                                                        title: 'Q1 · Urgente e Importante',
                                                        hint: 'No tienes tareas aquí. Usa “Entrada”.',
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
                                                  if (!showSemanticMap && dynamicLayout.isNotEmpty) ...[
                                                    if (!tasks
                                                        .any((t) => t.completedAt == null && t.quadrant == Quadrant.q1))
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        width: size.width / 2,
                                                        height: size.height / 2,
                                                        child: const QuadrantEmptyPlaceholder(
                                                          title: 'Q1 · Urgente e Importante',
                                                          hint: 'No tienes tareas aquí. Usa “Entrada”.',
                                                        ),
                                                      ),
                                                    if (!tasks
                                                        .any((t) => t.completedAt == null && t.quadrant == Quadrant.q2))
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
                                                    if (!tasks
                                                        .any((t) => t.completedAt == null && t.quadrant == Quadrant.q3))
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
                                                    if (!tasks
                                                        .any((t) => t.completedAt == null && t.quadrant == Quadrant.q4))
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
                                              ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Tarea completada!'), duration: Duration(milliseconds: 900)));
                },
              ),
        bottomNavigationBar: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(uiTsf)),
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
                        semanticViewportCtrl.enterQuadrant(
                          q,
                          label: _quadrantLabel(context, q),
                        );
                        ctrl.setZoom(q);
                        ctrl.setPresentQuadrant(q);
                        ctrl.invalidateLayout();
                      },
                      onFullView: () {
                        semanticViewportCtrl.reset(
                          grouping: semanticViewport.grouping,
                          density: semanticViewport.density,
                        );
                        ctrl.resetHomeView();
                      },
                    ),
                  )
                : _buildMobileBottomNav(context, tokens)),
      ),
    );
  }

  Widget _buildDesktopGrid(BuildContext context, GlassTokens tokens, List<Task> tasks) {
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
    final filtered = tasks.toList(growable: false);
    final q1 = filtered.where((t) => t.quadrant == Quadrant.q1).toList(growable: false);
    final q2 = filtered.where((t) => t.quadrant == Quadrant.q2).toList(growable: false);
    final q3 = filtered.where((t) => t.quadrant == Quadrant.q3).toList(growable: false);
    final q4 = filtered.where((t) => t.quadrant == Quadrant.q4).toList(growable: false);

    return Theme(
      data: applyDensity(theme, preset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
          ),
          child: Column(
            children: [
              const CategoryFiltersBar(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              ),
              ClassificationGroupingBar(
                tasks: filtered,
                categories: ref.watch(categoryConfigControllerProvider),
                settings: ref.watch(classificationSettingsControllerProvider),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              ),
              Expanded(
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
                      (t) => t.copyWith(
                        completedAt: nowDone ? DateTime.now() : null,
                      ),
                    );
                  },
                  onOpen: (task) {
                    final ctrl = ref.read(matrixControllerProvider.notifier);
                    ctrl.select(task.id);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scaffoldKey.currentState?.openEndDrawer(),
                    );
                  },
                ),
              ),
            ],
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
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTight = constraints.maxWidth < 380;
              final items = <Widget>[
                _NavBarItem(
                  icon: Icons.bar_chart_rounded,
                  label: isEs ? 'Stats' : 'Stats',
                  onTap: () => context.push('/stats'),
                ),
                _NavBarItem(
                  icon: Icons.history,
                  label: isEs ? 'Completas' : 'Completed',
                  onTap: () => context.push('/completed-matrix'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FloatingActionButton(
                    heroTag: 'fab-entry-nav',
                    mini: isTight,
                    onPressed: () => _openAddTaskSheet(context),
                    elevation: 2,
                    child: Icon(Icons.add, size: isTight ? 22 : 28),
                  ),
                ),
                _NavBarItem(
                  icon: Icons.view_timeline,
                  label: isEs ? 'Workflow' : 'Workflow',
                  onTap: () {
                    if (!ref.read(uiPrefsProvider).workflowPlanEnabled) {
                      final msg = isEs ? 'Activa "Workflow plan" en Ajustes' : 'Enable "Workflow plan" in Settings';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                                    SnackBar(
                                      content: Text(
                                        '\u2728 Tareas demo restauradas '
                                        '($kDemoTaskCount tareas)',
                                      ),
                                      duration: const Duration(seconds: 2),
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
                                    SnackBar(
                                      content: Text(
                                        '\u2728 Tareas demo restauradas '
                                        '($kDemoTaskCount tareas)',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                    );
                  },
                ),
              ];

              if (isTight) {
                return Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: items,
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((w) => Expanded(child: Center(child: w))).toList(growable: false),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildBanner({
  required BuildContext context,
  required AsyncValue<DailyProductivityScore?> scoreAsync,
  required List<Task> tasks,
  required Nudge? nudge,
  OverloadRisk? overloadRisk,
  AsyncValue<UserProductivityProfile>? profileAsync,
  required VoidCallback onDismissNudge,
  required VoidCallback onOpenStats,
  required VoidCallback onOpenQ2Picker,
}) {
  final cs = Theme.of(context).colorScheme;

  DailyProductivityScore? score;
  scoreAsync.whenData((s) => score = s);

  Widget? banner;
  if (profileAsync != null && profileAsync.value?.cluster != null) {
    final cluster = profileAsync.value!.cluster;
    final bannerContent = _adaptiveBanner(cluster, onOpenStats, onOpenQ2Picker);
    if (bannerContent != null) {
      banner = bannerContent;
    }
  }
  if (banner == null && overloadRisk != null && overloadRisk.score >= 0.8) {
    banner = EisenCard(
      margin: const EdgeInsets.fromLTRB(
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.sm,
      ),
      padding: const EdgeInsets.all(EisenSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: EisenSpacing.sm),
          Expanded(
            child: Text(
              'Parece que tu día está sobrecargado. Reorganiza 1–2 tareas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onOpenStats,
            child: const Text('Reorganizar'),
          ),
        ],
      ),
    );
  } else if (score != null) {
    if (score!.overloadScore >= 0.66) {
      banner = EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.priority_high, color: cs.error),
            const SizedBox(width: EisenSpacing.sm),
            Expanded(
              child: Text(
                'Tu día de hoy parece muy cargado. Considera mover 1–2 tareas a mañana.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: EisenSpacing.sm),
            TextButton(
              onPressed: onOpenStats,
              child: const Text('Reorganizar hoy'),
            ),
          ],
        ),
      );
    } else if (score!.q2Ratio < 0.20) {
      banner = EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: cs.primary),
            const SizedBox(width: EisenSpacing.sm),
            Expanded(
              child: Text(
                'Muy poco tiempo en Q2 (importante no urgente). Elige 1 tarea Q2 para hoy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: EisenSpacing.sm),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Elegir tarea Q2'),
            ),
          ],
        ),
      );
    }
  }

  // Si no hay banner de score, usar nudge existente.
  if (banner == null && nudge != null) {
    banner = EisenCard(
      key: ValueKey(nudge.id),
      margin: const EdgeInsets.fromLTRB(
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.md,
        EisenSpacing.sm,
      ),
      padding: const EdgeInsets.all(EisenSpacing.sm),
      interactive: true,
      child: Row(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: EisenColors.q2,
            size: 20,
          ),
          const SizedBox(width: EisenSpacing.sm),
          Expanded(child: Text(nudge.title)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismissNudge,
          ),
        ],
      ),
    );
  }

  return banner ?? const SizedBox.shrink();
}

void _openQ2Picker(BuildContext context, List<Task> tasks) {
  final q2 = tasks.where((t) => t.completedAt == null && t.quadrant == Quadrant.q2).toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      if (q2.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(EisenSpacing.lg),
          child: Text('No hay tareas Q2 pendientes.'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(EisenSpacing.md),
        itemBuilder: (ctx, idx) {
          final t = q2[idx];
          return ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(t.title),
            subtitle: t.due != null
                ? Text(
                    'Vence: ${t.due}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tarea seleccionada: ${t.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: q2.length,
      );
    },
  );
}

Widget? _adaptiveBanner(
  ProductivityCluster cluster,
  VoidCallback onOpenStats,
  VoidCallback onOpenQ2Picker,
) {
  switch (cluster) {
    case ProductivityCluster.morningStrong:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Tus mañanas rinden más. Mueve una tarea Q2 a primera hora.'),
            ),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Mover Q2'),
            ),
          ],
        ),
      );
    case ProductivityCluster.nightSprinter:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.nightlight_round),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Has trabajado tarde varios días. Prueba un cierre antes.'),
            ),
            TextButton(
              onPressed: onOpenStats,
              child: const Text('Configurar cierre'),
            ),
          ],
        ),
      );
    case ProductivityCluster.starterButNotFinisher:
      return EisenCard(
        margin: const EdgeInsets.fromLTRB(
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.md,
          EisenSpacing.sm,
        ),
        padding: const EdgeInsets.all(EisenSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.call_split),
            const SizedBox(width: EisenSpacing.sm),
            const Expanded(
              child: Text('Inicias muchas tareas. Divide una grande en pasos pequeños hoy.'),
            ),
            TextButton(
              onPressed: onOpenQ2Picker,
              child: const Text('Dividir'),
            ),
          ],
        ),
      );
    case ProductivityCluster.unknown:
      return null;
  }
}

double _procrastinationScore(Task task) {
  double score = 0.2;
  score += task.replanCount * 0.15;
  if (task.minutes > 180) score += 0.15;
  if (task.quadrant == Quadrant.q4) score += 0.2;
  final title = task.title.toLowerCase();
  const vague = ['revisar', 'ver', 'checar', 'check', 'look', 'review'];
  if (vague.any(title.contains)) {
    score += 0.1;
  }
  return score.clamp(0.0, 1.0);
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
  const _TopAxisLegends({this.minimal = false, required this.textScale, required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizationsEn();
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
                textScaler: TextScaler.linear(textScale),
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
                textScaler: TextScaler.linear(textScale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftAxisLegends extends StatelessWidget {
  const _LeftAxisLegends({this.minimal = false, required this.textScale, required this.headerHeight});
  final bool minimal;
  // AppTextScale applied
  final double textScale;
  final double headerHeight;
  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizationsEn();
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
                      textScaler: TextScaler.linear(textScale),
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
                      textScaler: TextScaler.linear(textScale),
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

void _exitSemanticLevel(
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

void _openSemanticNode({
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

String _quadrantLabel(BuildContext context, Quadrant quadrant) {
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

class _SemanticTreemapHeader extends StatelessWidget {
  const _SemanticTreemapHeader({
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
              const SizedBox(width: 8),
              if (scene.lowConfidenceCount > 0)
                ActionChip(
                  avatar: const Icon(Icons.rule_folder_outlined, size: 16),
                  label: Text('Revisar ${scene.lowConfidenceCount}'),
                  onPressed: onOpenReviewCenter,
                ),
              const Spacer(),
              Text(
                scene.subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in TreemapQuickFilter.values)
                FilterChip(
                  selected: viewport.quickFilter == filter,
                  onSelected: (_) => onSelectQuickFilter(filter),
                  label: Text(_quickFilterLabel(filter)),
                ),
              if (onFocusExactTask != null)
                ActionChip(
                  avatar: const Icon(Icons.travel_explore, size: 16),
                  label: const Text('Ir a coincidencia exacta'),
                  onPressed: onFocusExactTask,
                ),
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
