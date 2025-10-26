import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  Quadrant _quadrant = Quadrant.q2;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Describe la tarea',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Cuadrante:'),
                  const SizedBox(width: 12),
                  SegmentedButton<Quadrant>(
                    segments: [
                      for (final q in Quadrant.values)
                        ButtonSegment(value: q, label: Text(q.name.toUpperCase())),
                    ],
                    selected: {_quadrant},
                    onSelectionChanged: (s) => setState(() => _quadrant = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)'
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Guardar'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final ctrl = ref.read(matrixControllerProvider.notifier);
    final id = ctrl.createTask(quadrant: _quadrant, title: title);
    final cat = _categoryCtrl.text.trim();
    if (cat.isNotEmpty) {
      ctrl.updateTask(id, (t) => t.copyWith(categories: [cat], category: cat));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tarea agregada ✅'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            ctrl.deleteTask(id);
          },
        ),
      ),
    );
  }
}
