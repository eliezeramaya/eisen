enum AutomationMode {
  manualOnly,
  assisted,
  automatic;

  String get label => switch (this) {
        AutomationMode.manualOnly => 'Asistido',
        AutomationMode.assisted => 'Equilibrado',
        AutomationMode.automatic => 'Avanzado',
      };

  String get description => switch (this) {
        AutomationMode.manualOnly =>
          'Muestra la sugerencia antes de guardar y deja la clasificación claramente editable.',
        AutomationMode.assisted =>
          'Guarda automático cuando clasifica y deja una corrección rápida a mano.',
        AutomationMode.automatic =>
          'Clasifica y aplica comportamiento visual y agrupaciones sin preguntar.',
      };
}
