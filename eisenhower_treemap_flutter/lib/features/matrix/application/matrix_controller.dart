import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities.dart';
import '../domain/treemap_layout.dart';
import '../infra/local_repo.dart';
import '../../../core/services/storage_prefs.dart';

class MatrixState {
  final List<Task> tasks;
  final String? selectedId;
  final Quadrant? zoom;
  final ThemeMode themeMode;
  final String query;
  final bool compact;

  const MatrixState({
    required this.tasks,
    this.selectedId,
    this.zoom,
    this.themeMode = ThemeMode.system,
    this.query = '',
    this.compact = false,
  });

  MatrixState copyWith({
    List<Task>? tasks,
    String? selectedId,
    Quadrant? zoom,
    ThemeMode? themeMode,
    String? query,
    bool? compact,
  }) =>
      MatrixState(
        tasks: tasks ?? this.tasks,
        selectedId: selectedId ?? this.selectedId,
        zoom: zoom ?? this.zoom,
        themeMode: themeMode ?? this.themeMode,
        query: query ?? this.query,
        compact: compact ?? this.compact,
      );
}

class MatrixController extends Notifier<MatrixState> {
  late final MatrixRepository _repo;

  @override
  MatrixState build() {
    _repo = LocalPrefsMatrixRepository(StoragePrefs());
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
  }

  void setZoom(Quadrant? q) => state = state.copyWith(zoom: q);
  void toggleCompact() => state = state.copyWith(compact: !state.compact);
  void setQuery(String q) => state = state.copyWith(query: q);

  void createTask({Quadrant quadrant = Quadrant.q2}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final t = Task(
      id: id,
      title: 'New Task',
      quadrant: quadrant,
      priority: 5,
      minutes: 30,
    );
    final tasks = [...state.tasks, t];
    state = state.copyWith(tasks: tasks, selectedId: id);
    unawaited(persist());
  }

  void updateTask(String id, Task Function(Task) updater) {
    final tasks = state.tasks.map((t) => t.id == id ? updater(t) : t).toList();
    state = state.copyWith(tasks: tasks);
    unawaited(persist());
  }

  void deleteTask(String id) {
    final tasks = state.tasks.where((t) => t.id != id).toList();
    state = state.copyWith(tasks: tasks, selectedId: state.selectedId == id ? null : state.selectedId);
    unawaited(persist());
  }

  void moveTaskToQuadrant(String id, Quadrant q) => updateTask(id, (t) => t.copyWith(quadrant: q));

  List<TreemapRect> layout() {
    final filtered = state.query.isEmpty
        ? state.tasks
        : state.tasks.where((t) => t.title.toLowerCase().contains(state.query.toLowerCase())).toList();
    return computeSquarifiedLayout(filtered, zoom: state.zoom);
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
      );
    });
  }
}

final matrixControllerProvider = NotifierProvider<MatrixController, MatrixState>(() => MatrixController());
