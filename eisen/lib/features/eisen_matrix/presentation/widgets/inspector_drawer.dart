import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_recommendations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inspector drawer for task details and editing.
///
/// Current implementation (Phase 1):
/// - Basic fields: title, priority, minutes, category, quadrant
/// - Complete and delete actions
///
/// TODO Phase 2: Enhanced UX for additional fields
/// The following fields are available in the Task model but need better UI/UX:
/// - `due`: DateTime? - Due date picker (DatePicker widget)
/// - `tags`: List\<String\> - Tag chips with add/remove (ChipInput widget)
/// - `notes`: String? - Multi-line text editor with formatting
/// - `categories`: List\<String\> - Multiple category selection
/// - `status`: TaskStatus - Status dropdown (pending, inProgress, blocked, completed)
/// - `effort`: EffortLevel - Effort level selector (low, medium, high, veryHigh)
/// - `subtasks`: List\<Subtask\> - Expandable subtask list with checkboxes
/// - `recurrence`: RecurrencePattern - Recurrence pattern picker
/// - `projectId`: String? - Project association
/// - `assignedTo`: String? - User assignment
/// - `attachments`: List\<String\> - File attachment manager
/// - `dependencies`: List\<String\> - Task dependency graph viewer
///
/// Design considerations for Phase 2:
/// - Group related fields in expandable sections
/// - Use Material 3 components (SegmentedButton, FilterChip, etc.)
/// - Add visual hierarchy with proper spacing and dividers
/// - Implement inline editing for tags/subtasks
/// - Show metadata (createdAt, updatedAt) in read-only section
/// - Add validation and error states
/// - Consider responsive layout for desktop vs mobile
class InspectorDrawer extends ConsumerStatefulWidget {
  const InspectorDrawer(
      {super.key,
      required this.task,
      required this.onChanged,
      required this.onDelete,
      this.onArchive,
      this.onComplete});
  final Task task;
  final ValueChanged<Task> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onComplete;

  @override
  ConsumerState<InspectorDrawer> createState() => _InspectorDrawerState();
}

class _InspectorDrawerState extends ConsumerState<InspectorDrawer> {
  late TextEditingController _title;
  late TextEditingController _minutes;
  late TextEditingController _category;
  late TextEditingController _notes;
  int _priority = 5;
  Quadrant _quadrant = Quadrant.q2;
  DateTime? _dueDate;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _minutes = TextEditingController(text: widget.task.minutes.toString());
    _category = TextEditingController(text: widget.task.category ?? '');
    _notes = TextEditingController(text: widget.task.notes ?? '');
    _priority = widget.task.priority;
    _quadrant = widget.task.quadrant;
    _dueDate = widget.task.due;
    _tags = List.from(widget.task.tags);
  }

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        ref.watch(uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle));
    final currentQuadrantLabel = getQuadrantLabel(_quadrant, labelStyle);
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
            // Show category pill with color if not empty
            if (_category.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ref
                          .watch(uiPrefsProvider)
                          .categoryColorService
                          .getLightVariant(_category.text),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ref
                            .watch(uiPrefsProvider)
                            .categoryColorService
                            .getDarkVariant(_category.text),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 16,
                          color: ref
                              .watch(uiPrefsProvider)
                              .categoryColorService
                              .getColorForCategory(_category.text),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _category.text,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),

            // Due Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_dueDate == null
                  ? 'Set due date'
                  : 'Due: ${_formatDate(_dueDate!)}'),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _dueDate = null);
                        _emit();
                      },
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                  _emit();
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Tags Input (Basic implementation - TODO: enhance in Phase 2)
            TextField(
              decoration: InputDecoration(
                labelText: 'Tags (comma-separated)',
                helperText: 'e.g., urgent, work, personal',
                suffixIcon: _tags.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _tags.clear());
                          _emit();
                        },
                      )
                    : null,
              ),
              controller: TextEditingController(text: _tags.join(', ')),
              onChanged: (value) {
                setState(() {
                  _tags = value
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                });
                _emit();
              },
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                            _emit();
                          },
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),

            // Notes Field
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add detailed notes here...',
              ),
              maxLines: 4,
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.xs),

            DropdownButtonFormField<Quadrant>(
              initialValue: _quadrant,
              decoration: const InputDecoration(labelText: 'Quadrant'),
              items: Quadrant.values
                  .map((q) => DropdownMenuItem(
                        value: q,
                        child: Text(getQuadrantLabel(q, labelStyle).title),
                      ))
                  .toList(),
              onChanged: (q) {
                if (q != null) {
                  setState(() => _quadrant = q);
                  _emit();
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tips_and_updates_outlined),
              title: Text(currentQuadrantLabel.subtitle),
              subtitle: Text(getQuadrantRecommendation(_quadrant)),
            ),
            const Divider(height: AppSpacing.lg),
            if (_quadrant == Quadrant.q4 && widget.onArchive != null) ...[
              FilledButton.icon(
                onPressed: widget.onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archivar'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
      due: _dueDate,
      tags: _tags,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    widget.onChanged(t);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
