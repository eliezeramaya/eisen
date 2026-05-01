enum TaskViewMode {
  matrix,
  atlas,
}

extension TaskViewModeLabel on TaskViewMode {
  String get label => switch (this) {
        TaskViewMode.matrix => 'Matriz',
        TaskViewMode.atlas => 'Atlas',
      };
}

TaskViewMode taskViewModeFromName(String? name) {
  for (final mode in TaskViewMode.values) {
    if (mode.name == name) return mode;
  }
  return TaskViewMode.matrix;
}
