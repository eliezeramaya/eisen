enum EntryKind {
  task,
  shoppingItem,
  project,
  idea,
  habit,
  reminder;

  String get label => switch (this) {
        EntryKind.task => 'Tarea',
        EntryKind.shoppingItem => 'Compra',
        EntryKind.project => 'Proyecto',
        EntryKind.idea => 'Idea',
        EntryKind.habit => 'Hábito',
        EntryKind.reminder => 'Recordatorio',
      };
}
