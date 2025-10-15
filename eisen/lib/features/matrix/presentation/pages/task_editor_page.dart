import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/matrix_controller.dart';
import '../../domain/entities.dart';

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

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _minutes = TextEditingController(text: widget.task.minutes.toString());
    _notes = TextEditingController(text: widget.task.notes ?? '');
    _priority = widget.task.priority;
    _quadrant = widget.task.quadrant;
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
                value: _quadrant,
                decoration: const InputDecoration(labelText: 'Quadrant'),
                items: Quadrant.values
                    .map((q) => DropdownMenuItem(value: q, child: Text(q.name.toUpperCase())))
                    .toList(),
                onChanged: (q) => setState(() => _quadrant = q ?? _quadrant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
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
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
  }
}
