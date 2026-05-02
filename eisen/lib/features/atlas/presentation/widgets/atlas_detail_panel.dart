import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';

class AtlasDetailPanel extends StatelessWidget {
  const AtlasDetailPanel({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onEdit,
    required this.onReclassify,
    required this.onArchive,
    required this.onRestore,
    required this.labelStyle,
    this.onClose,
  });

  final Task? task;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onReclassify;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final QuadrantLabelStyle labelStyle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = task;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: selected == null
            ? Center(
                child: Text(
                  'Selecciona una tarea para ver el detalle',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : _TaskDetail(
                task: selected,
                onComplete: onComplete,
                onEdit: onEdit,
                onReclassify: onReclassify,
                onArchive: onArchive,
                onRestore: onRestore,
                labelStyle: labelStyle,
                onClose: onClose,
              ),
      ),
    );
  }
}

class _TaskDetail extends StatelessWidget {
  const _TaskDetail({
    required this.task,
    required this.onComplete,
    required this.onEdit,
    required this.onReclassify,
    required this.onArchive,
    required this.onRestore,
    required this.labelStyle,
    this.onClose,
  });

  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onReclassify;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final QuadrantLabelStyle labelStyle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quadrant = getQuadrantLabel(task.quadrant, labelStyle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _MetaRow(label: 'Cuadrante', value: quadrant.title),
                _MetaRow(label: 'Categoría', value: _categoryLabel(task)),
                _MetaRow(label: 'Prioridad', value: '${task.priority}/10'),
                _MetaRow(label: 'Minutos', value: '${task.minutes} min'),
                _MetaRow(
                  label: 'Horizonte',
                  value: task.horizon?.label ?? 'Sin horizonte',
                ),
                _MetaRow(
                  label: 'Energía',
                  value: task.energy?.label ?? 'Sin energía',
                ),
                _MetaRow(
                  label: 'Confianza',
                  value:
                      task.classificationConfidence?.label ?? 'Sin confianza',
                ),
                if (task.notes?.trim().isNotEmpty == true)
                  _MetaRow(label: 'Notas', value: task.notes!.trim()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Completar'),
            ),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar'),
            ),
            OutlinedButton.icon(
              onPressed: onReclassify,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Reclasificar'),
            ),
            OutlinedButton.icon(
              onPressed: task.isArchived ? onRestore : onArchive,
              icon: Icon(
                task.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 18,
              ),
              label: Text(task.isArchived ? 'Restaurar' : 'Archivar'),
            ),
          ],
        ),
      ],
    );
  }

  String _categoryLabel(Task task) {
    if (task.category?.trim().isNotEmpty == true) return task.category!.trim();
    if (task.categories.isNotEmpty) return task.categories.first;
    if (task.categoryId?.trim().isNotEmpty == true) {
      return task.categoryId!.trim();
    }
    return 'Sin categoría';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
