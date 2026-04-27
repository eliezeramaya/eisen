enum AutomationMode {
  manualOnly,
  assisted,
  automatic;

  String get label => switch (this) {
        AutomationMode.manualOnly => 'Manual',
        AutomationMode.assisted => 'Asistido',
        AutomationMode.automatic => 'Automático',
      };

  String get description => switch (this) {
        AutomationMode.manualOnly =>
          'Muestra la sugerencia antes de guardar y deja la clasificación manual y claramente editable.',
        AutomationMode.assisted =>
          'Clasifica con ayuda y guarda automáticamente, dejando una corrección rápida a mano.',
        AutomationMode.automatic =>
          'Clasifica y aplica comportamiento visual y agrupaciones automáticamente, sin preguntar.',
      };
}
