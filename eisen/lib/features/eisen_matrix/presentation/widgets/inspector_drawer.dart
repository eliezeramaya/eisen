import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class InspectorDrawer extends StatefulWidget {
  const InspectorDrawer({super.key, required this.task, required this.onChanged, required this.onDelete, this.onComplete});
  final Task task;
  final ValueChanged<Task> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onComplete;

  @override
  State<InspectorDrawer> createState() => _InspectorDrawerState();
}

class _InspectorDrawerState extends State<InspectorDrawer> {
  late TextEditingController _title;
  late TextEditingController _minutes;
  late TextEditingController _category;
  int _priority = 5;
  Quadrant _quadrant = Quadrant.q2;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _minutes = TextEditingController(text: widget.task.minutes.toString());
    _category = TextEditingController(text: widget.task.category ?? '');
    _priority = widget.task.priority;
    _quadrant = widget.task.quadrant;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Inspector', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                    onChanged: (v) {
                      setState(() => _priority = v.toInt());
                      _emit();
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes'),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<Quadrant>(
              initialValue: _quadrant,
              decoration: const InputDecoration(labelText: 'Quadrant'),
              items: Quadrant.values
                  .map((q) => DropdownMenuItem(value: q, child: Text(q.name.toUpperCase())))
                  .toList(),
              onChanged: (q) {
                if (q != null) {
                  setState(() => _quadrant = q);
                  _emit();
                }
              },
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onComplete,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Completar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _emit() {
    final min = int.tryParse(_minutes.text.trim()) ?? widget.task.minutes;
    final t = widget.task.copyWith(
      title: _title.text.trim(),
      minutes: min,
      priority: _priority,
      quadrant: _quadrant,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
    );
    widget.onChanged(t);
  }
}
