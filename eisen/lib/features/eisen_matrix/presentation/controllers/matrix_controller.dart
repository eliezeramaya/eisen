import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/services/telemetry.dart';

class MatrixState {
  final List<Task> tasks;
  final String? selectedId;
  final Quadrant? zoom;
  final Quadrant? presentQuadrant;
  final ThemeMode themeMode;
  final String query;
  final bool compact;
  final bool showAxisLegends;
  final bool minimal;
  final int version; // increments on task list mutations to help .select

  const MatrixState({
    required this.tasks,
    this.selectedId,
    this.zoom,
    this.themeMode = ThemeMode.system,
    this.query = '',
    this.compact = false,
    this.showAxisLegends = true,
    this.minimal = false,
    this.version = 0,
    this.presentQuadrant,
  });

  MatrixState copyWith({
    List<Task>? tasks,
    String? selectedId,
    Quadrant? zoom,
    Quadrant? presentQuadrant,
    ThemeMode? themeMode,
    String? query,
    bool? compact,
    bool? showAxisLegends,
    bool? minimal,
    int? version,
  }) =>
      MatrixState(
        tasks: tasks ?? this.tasks,
        selectedId: selectedId ?? this.selectedId,
        zoom: zoom ?? this.zoom,
        presentQuadrant: presentQuadrant ?? this.presentQuadrant,
        themeMode: themeMode ?? this.themeMode,
        query: query ?? this.query,
        compact: compact ?? this.compact,
        showAxisLegends: showAxisLegends ?? this.showAxisLegends,
        minimal: minimal ?? this.minimal,
        version: version ?? this.version,
      );
}

class MatrixController extends Notifier<MatrixState> {
  late final MatrixRepository _repo;
  late final UiPrefs _ui;
  final LayoutCache _cache = LayoutCache();
  final BanditService _bandit = BanditService();
  // Small memoization to avoid recompute if inputs unchanged within a frame
  int _lastHash = 0;
  List<TreemapRect> _lastLayout = const [];
  Set<Quadrant> _dirtyQuadrants = {};
  Quadrant? _lastZoom;
  Size? _lastViewport;
  Set<String> _suggested = {};

  @override
  MatrixState build() {
    _repo = LocalPrefsMatrixRepository(StoragePrefs());
    _ui = UiPrefs();
    // Seed with some demo tasks if empty
    return const MatrixState(tasks: [], presentQuadrant: Quadrant.q2);
  }

  Future<void> load() async {
    final loaded = await _repo.load();
    if (loaded.isEmpty) {
      final demo = _demoTasks();
      state = state.copyWith(tasks: demo);
      await _repo.save(demo);
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
  }

  Future<void> persist() => _repo.save(state.tasks);

  void select(String? id) => state = state.copyWith(selectedId: id);

  void toggleTheme() {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    state = state.copyWith(themeMode: next);
    _saveUi();
  }

  void setZoom(Quadrant? q) => state = state.copyWith(zoom: q);
  void setPresentQuadrant(Quadrant q) => state = state.copyWith(presentQuadrant: q);
  void toggleCompact() {
    state = state.copyWith(compact: !state.compact);
    _saveUi();
  }
  void toggleMinimal() {
    state = state.copyWith(minimal: !state.minimal);
    _saveUi();
  }
  void setQuery(String q) => state = state.copyWith(query: q);
  void toggleAxisLegends() {
    state = state.copyWith(showAxisLegends: !state.showAxisLegends);
    _saveUi();
  }

  Future<void> _saveUi() async {
    final data = UiPrefsData(
      themeMode: state.themeMode,
      compact: state.compact,
      showAxisLegends: state.showAxisLegends,
      minimal: state.minimal,
    );
    await _ui.save(data);
  }

  String createTask({Quadrant quadrant = Quadrant.q2, String title = 'New Task'}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final t = Task(
      id: id,
      title: title,
      quadrant: quadrant,
      priority: 5,
      minutes: 30,
      createdAt: DateTime.now(),
    );
    final tasks = [...state.tasks, t];
    state = state.copyWith(tasks: tasks, selectedId: id, version: state.version + 1);
    _dirtyQuadrants.add(quadrant);
    unawaited(persist());
    return id;
  }

  void updateTask(String id, Task Function(Task) updater) {
    final prev = state.tasks.firstWhere((t) => t.id == id);
    final next = updater(prev).copyWith(updatedAt: DateTime.now());
    final tasks = state.tasks.map((t) => t.id == id ? next : t).toList();
    state = state.copyWith(tasks: tasks, version: state.version + 1);
    if (prev.quadrant != next.quadrant) {
      _dirtyQuadrants.add(prev.quadrant);
      _dirtyQuadrants.add(next.quadrant);
    } else {
      _dirtyQuadrants.add(next.quadrant);
    }
    unawaited(persist());
  }

  void deleteTask(String id) {
    final prev = state.tasks.firstWhere((t) => t.id == id, orElse: () => state.tasks.first);
    final tasks = state.tasks.where((t) => t.id != id).toList();
    state = state.copyWith(tasks: tasks, selectedId: state.selectedId == id ? null : state.selectedId, version: state.version + 1);
    _dirtyQuadrants.add(prev.quadrant);
    // Clean caches to prevent leaks
    _cache.lastWeight.remove(id);
    _cache.lastRect.remove(id);
    _cache.lastRank.remove(id);
    unawaited(persist());
  }

  void moveTaskToQuadrant(String id, Quadrant q) => updateTask(id, (t) => t.copyWith(quadrant: q));

  void markTaskDone(String id) {
    updateTask(id, (t) => t.copyWith(completedAt: DateTime.now()));
  }

  /// Computes a stable layout. If there are pending dirty quadrants and not zoomed,
  /// recomputes only affected quadrants and merges with cached layout.
  List<TreemapRect> layout({Quadrant? only, Size? viewport}) {
    final filtered = state.query.isEmpty
        ? state.tasks
        : state.tasks.where((t) => t.title.toLowerCase().contains(state.query.toLowerCase())).toList();
    int h = Object.hashAllUnordered(filtered.map((t) => t.id)) ^ filtered.length ^ (state.zoom?.index ?? -1);
    double? minArea01;
    if (viewport != null && viewport.width > 0 && viewport.height > 0) {
      final minPx = 44.0 * 44.0;
      final totalPx = viewport.width * viewport.height;
      minArea01 = (minPx / totalPx).clamp(0.0, 1.0);
    }
    final zoom = state.zoom;
    final viewportChanged = _lastViewport == null || viewport == null || _lastViewport != viewport;
    final zoomChanged = _lastZoom != zoom;
    if (viewport != null) {
      h ^= viewport.width.round();
      h ^= (viewport.height.round() << 16);
    }
    if (only == null && _dirtyQuadrants.isEmpty && !zoomChanged && !viewportChanged && _lastHash == h) {
      return _lastLayout;
    }
    if (zoom != null) {
      final rect = const Rect.fromLTWH(0, 0, 1, 1);
      final tasksInQ = filtered.where((t) => t.quadrant == zoom).toList();
      final sw = Stopwatch()..start();
      final part = layoutQuadrantStable(tasksInQ, rect, _cache, _bandit, zoom, minTileArea01: minArea01);
      sw.stop(); Telemetry.layoutTime(zoom.name, sw.elapsedMicroseconds / 1000.0);
      _lastLayout = part;
      _lastHash = h;
      _lastZoom = zoom;
      _lastViewport = viewport;
      _dirtyQuadrants.clear();
      _computeTopSpots(_lastLayout);
      return _lastLayout;
    }
    if (only != null) {
      _dirtyQuadrants.add(only);
    }
    if (_lastLayout.isEmpty || viewportChanged || zoomChanged || _dirtyQuadrants.length >= 4) {
      final sw = Stopwatch()..start();
      final out = computeStableLayout(filtered, zoom: null, cache: _cache, bandit: _bandit, minTileArea01: minTileArea01);
      sw.stop(); Telemetry.layoutTime(null, sw.elapsedMicroseconds / 1000.0);
      _lastLayout = out;
      _lastHash = h;
      _lastZoom = zoom;
      _lastViewport = viewport;
      _dirtyQuadrants.clear();
      _computeTopSpots(_lastLayout);
      return out;
    }
    final keepQuadrants = {Quadrant.q1, Quadrant.q2, Quadrant.q3, Quadrant.q4}..removeAll(_dirtyQuadrants);
    final prevByQ = <Quadrant, List<TreemapRect>>{for (final q in Quadrant.values) q: []};
    for (final tr in _lastLayout) {
      prevByQ[tr.task.quadrant]!.add(tr);
    }
    final qRects = <Quadrant, Rect>{
      Quadrant.q1: const Rect.fromLTWH(0, 0, 0.5, 0.5),
      Quadrant.q2: const Rect.fromLTWH(0.5, 0, 0.5, 0.5),
      Quadrant.q3: const Rect.fromLTWH(0, 0.5, 0.5, 0.5),
      Quadrant.q4: const Rect.fromLTWH(0.5, 0.5, 0.5, 0.5),
    };
    final tasksByQ = <Quadrant, List<Task>>{for (final q in Quadrant.values) q: []};
    for (final t in filtered) {
      tasksByQ[t.quadrant]!.add(t);
    }
    final merged = <TreemapRect>[];
    final existingIds = filtered.map((t) => t.id).toSet();
    for (final q in keepQuadrants) {
      final kept = prevByQ[q]!.where((tr) => existingIds.contains(tr.task.id)).toList();
      merged.addAll(kept);
    }
    for (final q in _dirtyQuadrants) {
      final sw = Stopwatch()..start();
      final part = layoutQuadrantStable(tasksByQ[q]!, qRects[q]!, _cache, _bandit, q, minTileArea01: minTileArea01);
      sw.stop(); Telemetry.layoutTime(q.name, sw.elapsedMicroseconds / 1000.0);
      merged.addAll(part);
    }
    _lastLayout = merged;
    _lastHash = h;
    _lastZoom = zoom;
    _lastViewport = viewport;
    _dirtyQuadrants.clear();
    _computeTopSpots(_lastLayout);
    _computeTop3ReorderDelta(_lastLayout);
    return merged;
  }

  void _computeTopSpots(List<TreemapRect> layout) {
    final byQ = <Quadrant, List<TreemapRect>>{for (final q in Quadrant.values) q: []};
    for (final tr in layout) {
      if (tr.stackChildren.isNotEmpty) continue;
      byQ[tr.task.quadrant]!.add(tr);
    }
    final sug = <String>{};
    for (final q in Quadrant.values) {
      final list = byQ[q]!;
      if (list.isEmpty) continue;
      // Areas
      final areas = list.map((e) => e.rect01.width * e.rect01.height).toList();
      final maxA = areas.reduce((a, b) => a > b ? a : b);
      final cand = <Task>[];
      for (var i = 0; i < list.length; i++) {
        if (areas[i] >= maxA * 0.95) cand.add(list[i].task);
      }
      if (cand.isEmpty) continue;
      final top = _bandit.pickTopSpot(cand, q);
      if (top != null) sug.add(top);
    }
    _suggested = sug;
    if (sug.isNotEmpty) Telemetry.suggestedExpose(sug);
  }

  void _computeTop3ReorderDelta(List<TreemapRect> layout) {
    // Compare previous vs current top-3 ids per quadrant
    final prevByQ = <Quadrant, List<String>>{for (final q in Quadrant.values) q: []};
    final currByQ = <Quadrant, List<String>>{for (final q in Quadrant.values) q: []};
    // previous top3 from _lastLayout is not available here (we just replaced it). So track via cache.lastRank
    // Build previous ordering list by ascending lastRank
    final taskById = {for (final t in state.tasks) t.id: t};
    for (final q in Quadrant.values) {
      final ids = _cache.lastRank.keys.where((id) {
        final t = taskById[id];
        return t != null && t.quadrant == q;
      }).toList();
      ids.sort((a,b) => (_cache.lastRank[a] ?? 1<<30).compareTo(_cache.lastRank[b] ?? 1<<30));
      prevByQ[q] = ids.take(3).toList();
    }
    for (final q in Quadrant.values) {
      final items = layout.where((e) => e.task.quadrant == q && e.stackChildren.isEmpty).toList();
      if (items.isEmpty) continue;
      items.sort((a,b) => (b.rect01.width*b.rect01.height).compareTo(a.rect01.width*a.rect01.height));
      currByQ[q] = items.map((e)=>e.task.id).take(3).toList();
    }
    int delta = 0;
    for (final q in Quadrant.values) {
      final a = prevByQ[q]!;
      final b = currByQ[q]!;
      // count symmetric difference in positions
      final setA = a.toSet();
      final setB = b.toSet();
      final sym = {...setA.difference(setB), ...setB.difference(setA)};
      delta += sym.length;
    }
    if (delta > 0) Telemetry.top3ReorderDelta(delta);
  }

  Set<String> get suggestedTopSpots => _suggested;

  /// Public API alias for layout, for clarity in call sites.
  /// If [only] is provided, marks that quadrant dirty and recomputes just it.
  List<TreemapRect> computeLayout({Quadrant? only, Size? viewport}) => layout(only: only, viewport: viewport);

  /// Manually invalidate layout cache for [q] (or all if null).
  void invalidateLayout([Quadrant? q]) {
    if (q == null) {
      _dirtyQuadrants = {Quadrant.q1, Quadrant.q2, Quadrant.q3, Quadrant.q4};
    } else {
      _dirtyQuadrants.add(q);
    }
  }

  List<Task> _demoTasks() {
    final r = Random(42);
    Quadrant q(int i) => Quadrant.values[i % 4];
    return List.generate(24, (i) {
      return Task(
        id: 't$i',
        title: 'Task ${i + 1}',
        quadrant: q(i + 1),
        priority: 1 + r.nextInt(10),
        minutes: 10 + r.nextInt(120),
        createdAt: DateTime.now().subtract(Duration(days: r.nextInt(10))),
      );
    });
  }
}

final matrixControllerProvider = NotifierProvider<MatrixController, MatrixState>(() => MatrixController());

// Example of selective providers to minimize rebuilds where used
final matrixVersionProvider = Provider<int>((ref) => ref.watch(matrixControllerProvider.select((s) => s.version)));
final matrixZoomProvider = Provider<Quadrant?>((ref) => ref.watch(matrixControllerProvider.select((s) => s.zoom)));
final matrixTasksProvider = Provider<List<Task>>((ref) => ref.watch(matrixControllerProvider.select((s) => s.tasks)));
