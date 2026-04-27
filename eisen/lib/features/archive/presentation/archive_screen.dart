import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  final _queryController = TextEditingController();
  Quadrant? _quadrantFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(matrixControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(matrixTasksProvider);
    final labelStyle = ref.watch(
      uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle),
    );
    final query = _queryController.text.trim().toLowerCase();
    final archived = tasks.where((task) {
      if (!task.isArchived) return false;
      if (_quadrantFilter != null && task.quadrant != _quadrantFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return task.title.toLowerCase().contains(query) ||
          (task.notes ?? '').toLowerCase().contains(query) ||
          (task.categoryId ?? '').toLowerCase().contains(query) ||
          task.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) {
        final left = a.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EisenCard(
            outlined: true,
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar en archivo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Quadrant?>(
                  initialValue: _quadrantFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por cuadrante',
                  ),
                  items: [
                    const DropdownMenuItem<Quadrant?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    for (final quadrant in Quadrant.values)
                      DropdownMenuItem<Quadrant?>(
                        value: quadrant,
                        child: Text(
                          getQuadrantLabel(quadrant, labelStyle).title,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _quadrantFilter = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (archived.isEmpty)
            const EisenCard(
              outlined: true,
              child: Text('No hay tareas archivadas con estos filtros.'),
            )
          else
            for (final task in archived)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArchivedTaskTile(
                  task: task,
                  labelStyle: labelStyle,
                ),
              ),
        ],
      ),
    );
  }
}

class _ArchivedTaskTile extends ConsumerWidget {
  const _ArchivedTaskTile({
    required this.task,
    required this.labelStyle,
  });

  final Task task;
  final QuadrantLabelStyle labelStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrantLabel =
        getQuadrantLabel(task.quadrant, labelStyle).shortLabel;
    final archivedAt = _formatDate(task.archivedAt);
    return EisenCard(
      outlined: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.archive_outlined),
        title: Text(task.title),
        subtitle: Text(
          '$quadrantLabel · Archivada $archivedAt'
          '${task.categoryId == null ? '' : ' · ${task.categoryId}'}',
        ),
        trailing: FilledButton.tonal(
          onPressed: () {
            ref.read(matrixControllerProvider.notifier).restoreTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tarea restaurada')),
            );
          },
          child: const Text('Restaurar'),
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return 'sin fecha';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
