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

class MatrixState {
  final List<Task> tasks;
  final String? selectedId;
  final Quadrant? zoom;
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
  });

  MatrixState copyWith({
    List<Task>? tasks,
    String? selectedId,
    Quadrant? zoom,
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

  @override
  MatrixState build() {
    _repo = LocalPrefsMatrixRepository(StoragePrefs());
    _ui = UiPrefs();
    // Seed with some demo tasks if empty
    return const MatrixState(tasks: []);
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
    unawaited(persist());
    return id;
  }

  void updateTask(String id, Task Function(Task) updater) {
    final tasks = state.tasks.map((t) => t.id == id ? updater(t).copyWith(updatedAt: DateTime.now()) : t).toList();
    state = state.copyWith(tasks: tasks, version: state.version + 1);
    unawaited(persist());
  }

  void deleteTask(String id) {
    final tasks = state.tasks.where((t) => t.id != id).toList();
    state = state.copyWith(tasks: tasks, selectedId: state.selectedId == id ? null : state.selectedId, version: state.version + 1);
    unawaited(persist());
  }

  void moveTaskToQuadrant(String id, Quadrant q) => updateTask(id, (t) => t.copyWith(quadrant: q));

  /// Computes a stable layout using cached smoothing and bandit tie-breaks.
  /// Uses a simple hash to memoize within a frame to limit rebuild work.
  List<TreemapRect> layout({Quadrant? only}) {
    final filtered = state.query.isEmpty
        ? state.tasks
        : state.tasks.where((t) => t.title.toLowerCase().contains(state.query.toLowerCase())).toList();
    final h = Object.hashAllUnordered(filtered.map((t) => t.id)) ^ filtered.length ^ (state.zoom?.index ?? -1);
    if (_lastHash == h && only == null) return _lastLayout;
    final out = computeStableLayout(filtered, zoom: state.zoom, cache: _cache, bandit: _bandit);
    if (only == null) {
      _lastHash = h;
      _lastLayout = out;
    }
    return out;
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
