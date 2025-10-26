import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/l10n/app_localizations.dart';

class TaskEditorPage extends ConsumerStatefulWidget {
  final Task task;
  const TaskEditorPage({super.key, required this.task});

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  late TextEditingController _title;
  late TextEditingController _minutes;
  late TextEditingController _notes;
  late int _priority;
  late Quadrant _quadrant;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _minutes = TextEditingController(text: widget.task.minutes.toString());
    _notes = TextEditingController(text: widget.task.notes ?? '');
    _priority = widget.task.priority;
    _quadrant = widget.task.quadrant;
    _categories = List<String>.from(widget.task.categories);
  }

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(matrixControllerProvider.notifier);
    final detailsLabel = Localizations.localeOf(context).languageCode == 'es' ? 'Detalles' : 'Details';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit task'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final updated = _buildTask();
              ctrl.updateTask(updated.id, (_) => updated);
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Priority'),
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_priority',
                      onChanged: (v) => setState(() => _priority = v.toInt()),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Quadrant>(
                initialValue: _quadrant,
                decoration: const InputDecoration(labelText: 'Quadrant'),
                items: Quadrant.values
                    .map((q) => DropdownMenuItem(value: q, child: Text(q.name.toUpperCase())))
                    .toList(),
                onChanged: (q) => setState(() => _quadrant = q ?? _quadrant),
              ),
              const SizedBox(height: 16),
              // Categories selector
              _CategoriesSelector(
                selected: _categories,
                onChanged: (sel) => setState(() => _categories = sel),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: detailsLabel),
                minLines: 4,
                maxLines: 10,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final updated = _buildTask();
                      ctrl.updateTask(updated.id, (_) => updated);
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Task _buildTask() {
    final minutes = int.tryParse(_minutes.text.trim()) ?? widget.task.minutes;
    return widget.task.copyWith(
      title: _title.text.trim(),
      minutes: minutes,
      priority: _priority,
      quadrant: _quadrant,
      categories: _categories,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
  }
}

class _CategoriesSelector extends ConsumerWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  const _CategoriesSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Categories feature removed - return empty state
    return Row(
      children: [
        const Icon(Icons.label_outline, size: 18),
        const SizedBox(width: 8),
        Text(Theme.of(context).brightness == Brightness.dark
            ? 'Categories coming soon'
            : 'Categorías próximamente'),
      ],
    );
  }
}
