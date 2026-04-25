enum EntryKind {
  task,
  project,
  idea,
  habit,
  reminder;

  String get label => switch (this) {
        EntryKind.task => 'Tarea',
        EntryKind.project => 'Proyecto',
        EntryKind.idea => 'Idea',
        EntryKind.habit => 'Hábito',
        EntryKind.reminder => 'Recordatorio',
      };
}
