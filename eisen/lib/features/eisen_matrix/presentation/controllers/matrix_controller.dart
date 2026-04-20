import 'dart:async';

import 'package:eisen/core/haptics/haptics_service.dart';
import 'package:eisen/core/performance/perf_logger.dart';
import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/sync/remote_tasks_service.dart';
import 'package:eisen/core/sync/remote_tasks_service_noop.dart';
import 'package:eisen/core/workers/task_sort_worker.dart';
import 'package:eisen/core/workers/worker_models.dart';
import 'package:eisen/features/demo/demo_tasks.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config_provider.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_providers.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:eisen/features/eisen_matrix/domain/matrix_view_mode.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/compute_layout_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/compute_reorder_delta_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/create_task_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/delete_task_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/suggest_top_spots_usecase.dart';
import 'package:eisen/features/eisen_matrix/domain/usecases/update_task_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable state for the Eisenhower matrix.
///
/// - [tasks]: All tasks in the system
/// - [selectedId]: Currently selected task ID (null if none)
/// - [zoom]: Zoomed quadrant (null for full 4-quadrant view)
/// - [presentQuadrant]: Current quadrant in presentation mode
/// - [themeMode]: Light, dark, or system theme
/// - [query]: Legacy search/filter query (kept for tests/backward compat)
/// - [searchQuery]: Advanced search query (drives live filtering)
/// - [isSearchOpen]: Whether the advanced search UI is visible
/// - [compact]: Compact UI mode flag
/// - [showAxisLegends]: Show urgency/importance axis labels
/// - [minimal]: Minimal UI mode (hide extra chrome)
/// - [version]: Increments on mutations to help .select detect changes
/// - [viewMode]: Task view mode (top10/top25/top50/all/custom)
/// - [customTaskLimit]: Custom top‑K value when [viewMode] is [MatrixViewMode.custom]
class MatrixState {
  const MatrixState({
    required this.tasks,
    this.selectedId,
    this.zoom,
    this.zoomScale = 1.0,
    this.zoomOffset = Offset.zero,
    this.zoomQuadrant,
    this.themeMode = ThemeMode.system,
    this.query = '',
    this.searchQuery = '',
    this.isSearchOpen = false,
    this.compact = false,
    this.showAxisLegends = true,
    this.minimal = false,
    this.version = 0,
    this.presentQuadrant,
    this.layoutVersion = 0,
    this.viewMode = MatrixViewMode.top25,
    this.customTaskLimit = 25,
    this.lastMovedTaskId,
    this.isLoading = false,
  });
  final List<Task> tasks;
  final String? selectedId;
  final Quadrant? zoom;
  final double zoomScale;
  final Offset zoomOffset;
  final Quadrant? zoomQuadrant;
  final Quadrant? presentQuadrant;
  final ThemeMode themeMode;
  final String query;
  final String searchQuery;
  final bool isSearchOpen;
  final bool compact;
  final bool showAxisLegends;
  final bool minimal;
  final int version; // increments on task list mutations to help .select
  // Increments when layout configuration changes to force recompute/refresh
  final int layoutVersion;
  final MatrixViewMode viewMode;
  final int customTaskLimit;
  final String? lastMovedTaskId;
  final bool isLoading;

  static const Object _unset = Object();

  MatrixState copyWith({
    List<Task>? tasks,
    Object? selectedId = _unset,
    Object? zoom = _unset,
    double? zoomScale,
    Offset? zoomOffset,
    Object? zoomQuadrant = _unset,
    Object? presentQuadrant = _unset,
    ThemeMode? themeMode,
    String? query,
    String? searchQuery,
    bool? isSearchOpen,
    bool? compact,
    bool? showAxisLegends,
    bool? minimal,
    int? version,
    int? layoutVersion,
    MatrixViewMode? viewMode,
    int? customTaskLimit,
    Object? lastMovedTaskId = _unset,
    bool? isLoading,
  }) =>
      MatrixState(
        tasks: tasks ?? this.tasks,
        selectedId: identical(selectedId, _unset)
            ? this.selectedId
            : selectedId as String?,
        zoom: identical(zoom, _unset) ? this.zoom : zoom as Quadrant?,
        zoomScale: zoomScale ?? this.zoomScale,
        zoomOffset: zoomOffset ?? this.zoomOffset,
        zoomQuadrant: identical(zoomQuadrant, _unset)
            ? this.zoomQuadrant
            : zoomQuadrant as Quadrant?,
        presentQuadrant: identical(presentQuadrant, _unset)
            ? this.presentQuadrant
            : presentQuadrant as Quadrant?,
        themeMode: themeMode ?? this.themeMode,
        query: query ?? this.query,
        searchQuery: searchQuery ?? this.searchQuery,
        isSearchOpen: isSearchOpen ?? this.isSearchOpen,
        compact: compact ?? this.compact,
        showAxisLegends: showAxisLegends ?? this.showAxisLegends,
        minimal: minimal ?? this.minimal,
        version: version ?? this.version,
        layoutVersion: layoutVersion ?? this.layoutVersion,
        viewMode: viewMode ?? this.viewMode,
        customTaskLimit: customTaskLimit ?? this.customTaskLimit,
        lastMovedTaskId: identical(lastMovedTaskId, _unset)
            ? this.lastMovedTaskId
            : lastMovedTaskId as String?,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Main controller (Riverpod Notifier) for the Eisenhower matrix.
///
/// Orchestrates use cases and manages state. Delegates business logic to:
/// - [CreateTaskUseCase]: Task creation
/// - [UpdateTaskUseCase]: Task updates
/// - [DeleteTaskUseCase]: Task deletion and cache cleanup
/// - [ComputeLayoutUseCase]: Treemap layout computation
/// - [SuggestTopSpotsUseCase]: Bandit-based suggestions
/// - [ComputeReorderDeltaUseCase]: Layout stability metrics
class MatrixController extends Notifier<MatrixState> {
  late final MatrixRepository _repo;
  late final UiPrefs _ui;
  late final RemoteTasksService _remoteTasks;

  // Use cases
  late final CreateTaskUseCase _createTaskUseCase;
  late final UpdateTaskUseCase _updateTaskUseCase;
  late final DeleteTaskUseCase _deleteTaskUseCase;
  late ComputeLayoutUseCase _computeLayoutUseCase;
  late final SuggestTopSpotsUseCase _suggestTopSpotsUseCase;
  late final ComputeReorderDeltaUseCase _computeReorderDeltaUseCase;

  final LayoutCache _cache = LayoutCache();
  final BanditService _bandit = BanditService();
  Set<String> _suggested = {};
  LayoutConfig? _lastDynamicCfg;
  static const _customTaskLimitKey = 'customTaskLimit';
  static const _viewModeKey = 'matrixViewMode';
  Timer? _searchDebounce;
  Timer? _lastMovedTimer;

  @override
  MatrixState build() {
    _repo = LocalPrefsMatrixRepository(StoragePrefs());
    _ui = UiPrefs();
    _remoteTasks = ref.read(remoteTasksServiceProvider);

    // Initialize use cases
    _createTaskUseCase = CreateTaskUseCase();
    _updateTaskUseCase = UpdateTaskUseCase();
    _deleteTaskUseCase = DeleteTaskUseCase();
    final cfg = ref.read(layoutConfigProvider);
    _computeLayoutUseCase =
        ComputeLayoutUseCase(cache: _cache, bandit: _bandit, hybridConfig: cfg);

    // Listen to UI prefs for layout-related changes and bump layoutVersion + reconfigure
    ref.listen<UiPrefsData>(uiPrefsProvider, (prev, next) {
      if (prev == null) return;
      final changed = prev.topKPerQuadrant != next.topKPerQuadrant ||
          prev.gamma != next.gamma ||
          prev.minAreaNormalized != next.minAreaNormalized ||
          prev.quadrantPadding != next.quadrantPadding ||
          prev.minTileSizePx != next.minTileSizePx ||
          prev.treemapDensityProfile != next.treemapDensityProfile;
      if (changed) {
        final newCfg = ref.read(layoutConfigProvider);
        _computeLayoutUseCase = ComputeLayoutUseCase(
            cache: _cache, bandit: _bandit, hybridConfig: newCfg);
        // Invalidate all quadrants to ensure fresh layout with new config
        _computeLayoutUseCase.invalidate();
        // Bump layout version to notify UI
        state = state.copyWith(layoutVersion: state.layoutVersion + 1);
      }
    });
    _suggestTopSpotsUseCase = SuggestTopSpotsUseCase(_bandit);
    _computeReorderDeltaUseCase = ComputeReorderDeltaUseCase(_cache);

    return const MatrixState(tasks: [], presentQuadrant: Quadrant.q2);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final loaded = await _repo.load();
    // Check if there are any active (non-completed) tasks
    final activeTasks = loaded.where((t) => t.completedAt == null).toList();

    if (activeTasks.isEmpty) {
      // No active tasks - load demo data
      final demo = _demoTasks();
      state = state.copyWith(tasks: demo);
      await _saveAndSync(demo);
    } else {
      state = state.copyWith(tasks: loaded);
    }
    // Load UI preferences
    final ui = await _ui.load();
    state = state.copyWith(
      themeMode: ui.themeMode,
      compact: ui.compact,
      showAxisLegends: ui.showAxisLegends,
      minimal: ui.minimal,
    );
    // Load matrix‑specific view prefs (viewMode + customTaskLimit)
    await _loadMatrixViewPrefs();
    // Force full layout recomputation on load
    invalidateLayout();
    state = state.copyWith(isLoading: false);
  }

  /// Reset to demo tasks (useful for testing and demos)
  Future<void> resetToDemo() async {
    state = state.copyWith(isLoading: true);
    final demo = _demoTasks();
    state = state.copyWith(tasks: demo, version: state.version + 1);
    await _saveAndSync(demo);
    state = state.copyWith(isLoading: false);
  }

  Future<void> persist() => _saveAndSync(state.tasks);

  void select(String? id) => state = state.copyWith(selectedId: id);

  /// Called when a drag operation starts for [task].
  ///
  /// Reserved for future global drag state (e.g. status bar hints).
  void setDragging(Task task) {
    // Premium drag state can be surfaced from here if needed.
  }

  /// Clears any dragging-related state.
  void clearDragging() {
    // Reserved hook for future global drag state.
  }

  void _markLastMoved(String id) {
    _lastMovedTimer?.cancel();
    state = state.copyWith(lastMovedTaskId: id);
    _lastMovedTimer = Timer(const Duration(milliseconds: 200), () {
      state = state.copyWith(lastMovedTaskId: null);
    });
  }

  void toggleTheme() {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    state = state.copyWith(themeMode: next);
    _saveUi();
  }

  /// Sets zoomed quadrant and keeps presentation state in sync.
  ///
  /// When entering a quadrant (q != null), we also set presentQuadrant to q so
  /// all consumers that rely on the presentation quadrant render the correct
  /// content. When exiting zoom (q == null), we reset presentQuadrant to Q2 as
  /// the default full-view focus.
  void setZoom(Quadrant? q) {
    final present = q ?? Quadrant.q2;
    state = state.copyWith(zoom: q, presentQuadrant: present);
  }

  void setPresentQuadrant(Quadrant q) =>
      state = state.copyWith(presentQuadrant: q);
  void toggleCompact() {
    state = state.copyWith(compact: !state.compact);
    _saveUi();
  }

  void toggleMinimal() {
    state = state.copyWith(minimal: !state.minimal);
    _saveUi();
  }

  void _applySearchQuery(String raw) {
    final trimmed = raw.trim();
    state = state.copyWith(
      query: trimmed,
      searchQuery: trimmed,
    );
  }

  /// Legacy API used by some tests; keeps [query] and [searchQuery] in sync.
  void setQuery(String q) => _applySearchQuery(q);

  /// Toggle the advanced search UI. When closing, clears the query so the
  /// matrix returns to its full state.
  void toggleSearch([bool? open]) {
    final shouldOpen = open ?? !state.isSearchOpen;
    if (!shouldOpen) {
      _searchDebounce?.cancel();
      state = state.copyWith(
        isSearchOpen: false,
        searchQuery: '',
        query: '',
      );
    } else {
      state = state.copyWith(isSearchOpen: true);
    }
  }

  /// Debounced search query update for live search UX from the toolbar.
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    final value = query;
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _applySearchQuery(value);
    });
  }

  void toggleAxisLegends() {
    state = state.copyWith(showAxisLegends: !state.showAxisLegends);
    _saveUi();
  }

  /// Set continuous zoom scale (0.8–3.0) and update dominant quadrant.
  ///
  /// [focalPoint], if provided, is expected to be in normalized (0..1) coordinates
  /// relative to the matrix viewport.
  void setZoomScale(double newScale, {Offset? focalPoint}) {
    final clamped = newScale.clamp(0.8, 3.0);
    final quadrant =
        clamped > 1.1 ? _detectQuadrantFromOffset(focalPoint) : null;
    state = state.copyWith(
      zoomScale: clamped,
      zoomQuadrant: quadrant,
    );
    _syncTopKWithZoom();
  }

  /// Set pan offset for the zoomed matrix.
  void setZoomOffset(Offset offset) {
    state = state.copyWith(zoomOffset: offset);
  }

  /// Animate smoothly to a target zoom scale.
  Future<void> animateToScale(double targetScale, {Quadrant? quadrant}) async {
    final start = state.zoomScale;
    final clampedTarget = targetScale.clamp(0.8, 3.0);
    if ((clampedTarget - start).abs() < 0.001) return;

    const duration = Duration(milliseconds: 220);
    final begin = DateTime.now();
    while (true) {
      final now = DateTime.now();
      final tRaw =
          now.difference(begin).inMilliseconds / duration.inMilliseconds;
      if (tRaw >= 1.0) break;
      final t = Curves.easeOutCubic.transform(tRaw.clamp(0.0, 1.0));
      final value = start + (clampedTarget - start) * t;
      final q = value > 1.1
          ? (quadrant ?? state.zoomQuadrant ?? state.presentQuadrant)
          : null;
      state = state.copyWith(
        zoomScale: value,
        zoomQuadrant: q,
      );
      _syncTopKWithZoom();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final finalQ = clampedTarget > 1.1
        ? (quadrant ?? state.zoomQuadrant ?? state.presentQuadrant)
        : null;
    state = state.copyWith(
      zoomScale: clampedTarget,
      zoomQuadrant: finalQ,
    );
    _syncTopKWithZoom();
  }

  /// Reset continuous zoom/pan state to defaults.
  void resetZoom() {
    state = state.copyWith(
      zoomScale: 1.0,
      zoomOffset: Offset.zero,
      zoomQuadrant: null,
    );
    _syncTopKWithZoom();
  }

  Quadrant? _detectQuadrantFromOffset(Offset? focalPoint) {
    if (focalPoint == null) {
      return state.zoomQuadrant ?? state.presentQuadrant;
    }
    final x = focalPoint.dx.clamp(0.0, 1.0);
    final y = focalPoint.dy.clamp(0.0, 1.0);
    if (x < 0.5 && y < 0.5) return Quadrant.q1;
    if (x >= 0.5 && y < 0.5) return Quadrant.q2;
    if (x < 0.5 && y >= 0.5) return Quadrant.q3;
    return Quadrant.q4;
  }

  /// Sets the task view mode (top10/top25/top50/all/custom) and synchronizes
  /// treemap layout topK with the effective limit.
  void setViewMode(MatrixViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _syncTopKWithZoom();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_viewModeKey, mode.index));
  }

  /// Updates custom top‑K limit (10–100) and persists it.
  void setCustomTaskLimit(int newLimit) {
    final clamped = newLimit.clamp(10, 100);
    state = state.copyWith(customTaskLimit: clamped);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_customTaskLimitKey, clamped));
    _syncTopKWithZoom();
  }

  Future<void> _saveUi() async {
    // Preserve existing layout-related fields when saving basic toggles.
    final prev = await _ui.load();
    final data = prev.copyWith(
      themeMode: state.themeMode,
      compact: state.compact,
      showAxisLegends: state.showAxisLegends,
      minimal: state.minimal,
    );
    await _ui.save(data);
  }

  Future<void> _loadMatrixViewPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLimit = prefs.containsKey(_customTaskLimitKey);
    final hasMode = prefs.containsKey(_viewModeKey);

    final savedLimit = hasLimit
        ? (prefs.getInt(_customTaskLimitKey) ?? 25)
        : state.customTaskLimit;
    final modeIndex = hasMode ? prefs.getInt(_viewModeKey) : null;
    MatrixViewMode mode = state.viewMode;
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < MatrixViewMode.values.length) {
      mode = MatrixViewMode.values[modeIndex];
    }
    state = state.copyWith(
      customTaskLimit: savedLimit,
      viewMode: mode,
    );

    // Only override existing layout prefs when there is an explicit
    // saved view mode or custom limit from a previous session.
    if (hasMode || hasLimit) {
      _syncTopKWithZoom();
    }
  }

  void _syncTopKWithViewMode(MatrixViewMode mode, int customLimit) {
    int k;
    switch (mode) {
      case MatrixViewMode.top10:
        k = 10;
        break;
      case MatrixViewMode.top25:
        k = 25;
        break;
      case MatrixViewMode.top50:
        k = 50;
        break;
      case MatrixViewMode.top100:
        k = 100;
        break;
      case MatrixViewMode.all:
        // Use a high value to approximate "no limit"; layout providers will
        // clamp based on their own safety bounds.
        k = 100;
        break;
      case MatrixViewMode.custom:
        k = customLimit;
        break;
    }
    // Synchronize with layout prefs so treemap uses the effective topK
    ref.read(uiPrefsControllerProvider.notifier).setTopK(k);
  }

  Future<void> _saveAndSync(List<Task> tasks) async {
    await _repo.save(tasks);
    unawaited(
      _remoteTasks.pushRemoteTasks(tasks).catchError((_) => null),
    );
  }

  void _syncTopKWithZoom() {
    final scale = state.zoomScale;
    if (scale > 2.0) {
      ref.read(uiPrefsControllerProvider.notifier).setTopK(100);
      return;
    }
    if (scale > 1.2) {
      ref
          .read(uiPrefsControllerProvider.notifier)
          .setTopK(state.customTaskLimit.clamp(10, 100));
      return;
    }
    _syncTopKWithViewMode(state.viewMode, state.customTaskLimit);
  }

  String createTask(
      {Quadrant quadrant = Quadrant.q2, String title = 'New Task'}) {
    final task = _createTaskUseCase.execute(quadrant: quadrant, title: title);
    final tasks = [...state.tasks, task];

    state = state.copyWith(
      tasks: tasks,
      selectedId: task.id,
      version: state.version + 1,
    );

    _computeLayoutUseCase.markDirty({quadrant});
    unawaited(persist());
    // TODO: Re-enable analytics
    // unawaited(_logEvent(
    // UserEvent(
    // type: UserEventType.taskCreated,
    // timestamp: DateTime.now(),
    // metadata: {
    // 'taskId': task.id,
    // 'quadrant': quadrant.name,
    // 'projectId': task.projectId,
    // 'due': task.due?.toIso8601String(),
    // 'minutes': task.minutes,
    // 'priority': task.priority,
    // },
    // ),
    // ));

    return task.id;
  }

  void updateTask(String id, Task Function(Task) updater) {
    final idx = state.tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return; // nothing to update
    final prev = state.tasks[idx];
    final next = _updateTaskUseCase.execute(prev, updater);
    final tasks = state.tasks.map((t) => t.id == id ? next : t).toList();

    state = state.copyWith(tasks: tasks, version: state.version + 1);

    // Mark dirty quadrants
    final dirtyQuadrants = <Quadrant>{};
    if (prev.quadrant != next.quadrant) {
      dirtyQuadrants.addAll([prev.quadrant, next.quadrant]);
      _markLastMoved(next.id);
    } else {
      dirtyQuadrants.add(next.quadrant);
    }
    _computeLayoutUseCase.markDirty(dirtyQuadrants);

    unawaited(persist());

    // Instrumentar replanificaciones (cambio de due o replanCount).
    final dueChanged = prev.due != next.due;
    final replanChanged = prev.replanCount != next.replanCount;
    if (dueChanged || replanChanged) {
      // TODO: Re-enable analytics
      // unawaited(_logEvent(
      // UserEvent(
      // type: UserEventType.taskRescheduled,
      // timestamp: DateTime.now(),
      // metadata: {
      // 'taskId': next.id,
      // 'oldDue': prev.due?.toIso8601String(),
      // 'newDue': next.due?.toIso8601String(),
      // 'replanCount': next.replanCount,
      // },
      // ),
      // ));
    }
  }

  void deleteTask(String id) {
    final idx = state.tasks.indexWhere((t) => t.id == id);
    final prev = idx == -1 ? null : state.tasks[idx];
    final tasks = state.tasks.where((t) => t.id != id).toList();

    state = state.copyWith(
      tasks: tasks,
      selectedId: state.selectedId == id ? null : state.selectedId,
      version: state.version + 1,
    );

    if (prev != null) {
      _computeLayoutUseCase.markDirty({prev.quadrant});
      _deleteTaskUseCase.cleanupCache(id, _cache);
    } else {
      // If prev missing, conservatively invalidate all
      _computeLayoutUseCase.invalidate();
    }

    unawaited(persist());
  }

  void moveTaskToQuadrant(String id, Quadrant q) =>
      updateTask(id, (t) => t.copyWith(quadrant: q));

  void markTaskDone(String id) {
    updateTask(id, (t) => t.copyWith(completedAt: DateTime.now()));

    // Haptic feedback on task completion
    final haptics = ref.read(hapticsServiceProvider);
    haptics.light();

    // TODO: Remove or use completed task analytics
    // final completed = state.tasks.firstWhere(
    //   (t) => t.id == id,
    //   orElse: () => Task(
    //     id: id,
    //     title: '',
    //     quadrant: Quadrant.q2,
    //     priority: 5,
    //     minutes: 60,
    //   ),
    // );
    // TODO: Re-enable analytics
    // unawaited(_logEvent(
    // UserEvent(
    // type: UserEventType.taskCompleted,
    // timestamp: DateTime.now(),
    // metadata: {
    // 'taskId': completed.id,
    // 'quadrant': completed.quadrant.name,
    // 'projectId': completed.projectId,
    // 'due': completed.due?.toIso8601String(),
    // },
    // ),
    // ));
  }

  /// Resets the matrix view to the initial "home" state.
  ///
  /// - Clears zoom and selection
  /// - Resets search/query and closes the advanced search UI
  /// - Ensures the presentation quadrant is Q2 (full 4-quadrant view)
  /// - Invalidates layout so the treemap recomputes for the full matrix
  void resetHomeView() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      zoom: null,
      zoomScale: 1.0,
      zoomOffset: Offset.zero,
      zoomQuadrant: null,
      presentQuadrant: Quadrant.q2,
      selectedId: null,
      query: '',
      searchQuery: '',
      isSearchOpen: false,
    );
    invalidateLayout();
  }

  /// Normaliza texto para búsqueda: minúsculas y sin acentos básicos.
  String _normalizeSearchText(String input) {
    final lower = input.toLowerCase();
    const mapping = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    final buffer = StringBuffer();
    for (final codeUnit in lower.runes) {
      final ch = String.fromCharCode(codeUnit);
      buffer.write(mapping[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Computes the treemap layout with filtering and delegates to isolate worker.
  Future<List<TreemapRect>> layout({Quadrant? only, Size? viewport}) async {
    final filtered = _filteredTasksForLayout();
    final sorted = await _sortTasksForLayout(filtered);
    final resolvedDensity = _resolvedTreemapDensityFor(viewport);
    final layout = await _computeLayoutUseCase.executeAsync(
      tasks: sorted,
      zoom: state.zoom,
      viewport: viewport,
      only: only,
      compactDensity: resolvedDensity.compactDensity,
      minTileSizePx: resolvedDensity.minTileSizePx,
    );

    // Update suggestions and compute metrics
    _suggested = _suggestTopSpotsUseCase.execute(layout);

    final taskById = {for (final t in state.tasks) t.id: t};
    _computeReorderDeltaUseCase.execute(layout, taskById);

    return layout;
  }

  Set<String> get suggestedTopSpots => _suggested;

  /// Synchronous layout computation for scenarios that need immediate results
  /// (e.g., golden tests or first paint) without isolate hop.
  List<TreemapRect> computeLayoutSync({
    Quadrant? only,
    Size? viewport,
    bool resetCache = false,
  }) {
    _maybeUpdateDynamicLayoutConfig(viewport, mutateState: false);
    if (resetCache) {
      resetLayoutCache();
    }
    final filtered = _filteredTasksForLayout();
    final resolvedDensity = _resolvedTreemapDensityFor(viewport);
    final layout = _computeLayoutUseCase.execute(
      tasks: filtered,
      zoom: state.zoom,
      viewport: viewport,
      only: only,
      compactDensity: resolvedDensity.compactDensity,
      minTileSizePx: resolvedDensity.minTileSizePx,
    );
    _suggested = _suggestTopSpotsUseCase.execute(layout);
    final taskById = {for (final t in state.tasks) t.id: t};
    _computeReorderDeltaUseCase.execute(layout, taskById);
    return layout;
  }

  /// Clears layout cache to produce deterministic layouts (useful for goldens).
  void resetLayoutCache() {
    _cache.lastWeight.clear();
    _cache.lastRect.clear();
    _cache.lastRank.clear();
    _computeLayoutUseCase.invalidate();
  }

  /// Public API: Computes layout for given viewport.
  Future<List<TreemapRect>> computeLayout(
      {Quadrant? only, Size? viewport}) async {
    _maybeUpdateDynamicLayoutConfig(viewport);
    return layout(only: only, viewport: viewport);
  }

  /// Manually invalidate layout cache for [q] (or all if null).
  void invalidateLayout([Quadrant? q]) {
    _computeLayoutUseCase.invalidate(q);
  }

  /// Public method to explicitly notify listeners that layout should recompute.
  /// Increments [layoutVersion] to trigger dependent UI updates.
  void notifyLayoutRecompute() {
    state = state.copyWith(layoutVersion: state.layoutVersion + 1);
  }

  List<Task> _filteredTasksForLayout() {
    var filtered = state.tasks.where((t) => t.completedAt == null).toList();
    final q = _normalizeSearchText(state.searchQuery.trim());
    if (q.isNotEmpty) {
      filtered = filtered.where((t) {
        final title = _normalizeSearchText(t.title);
        final notes = _normalizeSearchText(t.notes ?? '');
        final category = _normalizeSearchText(t.category ?? '');
        final categories = _normalizeSearchText(t.categories.join(' '));
        final tags = _normalizeSearchText(t.tags.join(' '));
        return title.contains(q) ||
            notes.contains(q) ||
            category.contains(q) ||
            categories.contains(q) ||
            tags.contains(q);
      }).toList();
    }
    return filtered;
  }

  void _maybeUpdateDynamicLayoutConfig(Size? viewport,
      {bool mutateState = true}) {
    // Responsive topK override based on viewport size
    if (viewport != null && viewport.width > 0 && viewport.height > 0) {
      final dynCfg = ref.read(layoutConfigForSizeProvider(viewport));
      final prev = _lastDynamicCfg;
      final changed = prev == null ||
          prev.topKPerQuadrant != dynCfg.topKPerQuadrant ||
          prev.gamma != dynCfg.gamma ||
          prev.minAreaNormalized != dynCfg.minAreaNormalized ||
          prev.quadrantPadding != dynCfg.quadrantPadding;
      if (changed) {
        _lastDynamicCfg = dynCfg;
        _computeLayoutUseCase = ComputeLayoutUseCase(
          cache: _cache,
          bandit: _bandit,
          hybridConfig: dynCfg,
        );
        _computeLayoutUseCase.invalidate();
        if (mutateState) {
          state = state.copyWith(layoutVersion: state.layoutVersion + 1);
        }
      }
    }
  }

  ResolvedTreemapDensity _resolvedTreemapDensityFor(Size? viewport) {
    final size = (viewport != null && viewport.width > 0 && viewport.height > 0)
        ? viewport
        : TreemapDensityResolver.fallbackScreenSize;
    return ref.read(treemapDensityForSizeProvider(size));
  }

  Future<List<Task>> _sortTasksForLayout(List<Task> tasks) async {
    // For small sets, sorting overhead is not worth spinning an isolate.
    if (tasks.length < 200) return tasks;

    final request = TaskSortRequest(
      tasks: tasks.map(TaskIsolateSnapshot.fromTask).toList(growable: false),
      mode: TaskSortMode.priorityThenDue,
      includeCompleted: false,
    );

    try {
      final response = await PerfLogger.instance.measureTaskSort(
        () => compute(taskSortWorker, request.toJson()),
        sampleSize: tasks.length,
      );

      final byId = {for (final t in tasks) t.id: t};
      final ordered = <Task>[];
      for (final id in response.orderedIds) {
        final task = byId.remove(id);
        if (task != null) ordered.add(task);
      }
      if (byId.isNotEmpty) {
        ordered.addAll(byId.values);
      }
      return ordered;
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint(
            'MatrixController sortTasks isolate failed, using original order: $err\n$st');
      }
      return tasks;
    }
  }

  List<Task> _demoTasks() => demoTasks();
}

final matrixControllerProvider =
    NotifierProvider<MatrixController, MatrixState>(MatrixController.new);

// TODO: Re-implement analytics with proper architecture
// extension _MatrixAnalytics on MatrixController {
//   Future<void> _logEvent(UserEvent event) {
//     return ref.read(analyticsServiceProvider).logEvent(event);
//   }
// }

// Example of selective providers to minimize rebuilds where used
final matrixVersionProvider = Provider<int>(
    (ref) => ref.watch(matrixControllerProvider.select((s) => s.version)));
final matrixZoomProvider = Provider<Quadrant?>(
    (ref) => ref.watch(matrixControllerProvider.select((s) => s.zoom)));
final matrixTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(matrixControllerProvider.select((s) => s.tasks)));
