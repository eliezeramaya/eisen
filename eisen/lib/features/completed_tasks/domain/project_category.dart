/// Project categories for filtering completed tasks.
///
/// Used to group and filter tasks by their project/context.
/// Each category has a display name for UI presentation.
enum ProjectCategory {
  all,
  work,
  family,
  personal,
  project1,
  project2,
  health,
  learning,
  social,
  strategy,
  sales,
  communication,
  meetings,
  customization;

  /// Human-readable display name for UI
  String get displayName => switch (this) {
        ProjectCategory.all => 'Todos',
        ProjectCategory.work => 'Trabajo',
        ProjectCategory.family => 'Familia',
        ProjectCategory.personal => 'Personal',
        ProjectCategory.project1 => 'Proyecto 1',
        ProjectCategory.project2 => 'Proyecto 2',
        ProjectCategory.health => 'Salud',
        ProjectCategory.learning => 'Aprendizaje',
        ProjectCategory.social => 'Social',
        ProjectCategory.strategy => 'Estrategia',
        ProjectCategory.sales => 'Ventas',
        ProjectCategory.communication => 'Comunicación',
        ProjectCategory.meetings => 'Reuniones',
        ProjectCategory.customization => 'Personalización',
      };

  /// Parse from task category string
  static ProjectCategory? fromString(String? category) {
    if (category == null || category.isEmpty) return null;

    return ProjectCategory.values.firstWhere(
      (c) => c.displayName.toLowerCase() == category.toLowerCase(),
      orElse: () => ProjectCategory.personal,
    );
  }
}
