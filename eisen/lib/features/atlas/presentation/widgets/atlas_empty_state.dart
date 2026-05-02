import 'package:eisen/core/responsive/app_breakpoints.dart';
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
    final isCompact = deviceClassFromContext(context).isCompact;
    final (title, body, desktopBody, icon) = switch (kind) {
      AtlasEmptyStateKind.noTasks => (
          'Atlas está vacío',
          'Agrega una tarea para comenzar a mapear tu día.',
          'Agrega una tarea para comenzar a mapear tu día y ver prioridades, energía y horizonte en un solo mapa.',
          Icons.map_outlined,
        ),
      AtlasEmptyStateKind.filters => (
          'No hay tareas con estos filtros',
          'Limpia filtros para ver tu Atlas completo.',
          'Limpia filtros o cambia la agrupación para volver a ver tu Atlas completo.',
          Icons.filter_alt_off_outlined,
        ),
      AtlasEmptyStateKind.noActiveTasks => (
          'No hay tareas activas',
          'Puedes revisar el archivo o crear una nueva tarea.',
          'Puedes revisar el archivo, restaurar una tarea o crear una nueva entrada para seguir trabajando.',
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
              isCompact ? body : desktopBody,
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
