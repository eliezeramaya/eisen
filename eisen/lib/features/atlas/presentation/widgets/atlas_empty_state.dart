import 'package:flutter/material.dart';

class AtlasEmptyState extends StatelessWidget {
  const AtlasEmptyState({
    super.key,
    required this.kind,
  });

  final AtlasEmptyStateKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body, icon) = switch (kind) {
      AtlasEmptyStateKind.noTasks => (
          'Atlas está vacío',
          'Agrega una tarea para comenzar a mapear tu día.',
          Icons.map_outlined,
        ),
      AtlasEmptyStateKind.filters => (
          'No hay tareas con estos filtros',
          'Limpia filtros para ver tu Atlas completo.',
          Icons.filter_alt_off_outlined,
        ),
      AtlasEmptyStateKind.noActiveTasks => (
          'No hay tareas activas',
          'Puedes revisar el archivo o crear una nueva tarea.',
          Icons.inventory_2_outlined,
        ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum AtlasEmptyStateKind {
  noTasks,
  filters,
  noActiveTasks,
}
