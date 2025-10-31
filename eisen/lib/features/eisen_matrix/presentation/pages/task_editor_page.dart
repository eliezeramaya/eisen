import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/app_text_scale.dart';
import 'package:eisen/core/responsive/responsive_wrapper.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key, required this.task});
  final Task task;

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
    final r = Responsive.of(context);
    final prefs = ref.watch(uiPrefsProvider);
    final uiTsf = AppTextScale.of(context, prefs); // AppTextScale applied
    final isExtreme = AppTextScale.isExtreme(context, prefs);
    final pad = EdgeInsets.all(AppSpacing.md * r.paddingScale);

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
        child: MediaQuery(
          // AppTextScale applied
          data: MediaQuery.of(context).copyWith(textScaleFactor: uiTsf),
          child: SingleChildScrollView(
            padding: pad,
            child: LayoutBuilder(builder: (context, c) {
              final isTwoColumn = r.bp == BreakpointSize.md || r.isDesktop;
              final vGap = isExtreme ? AppSpacing.md : AppSpacing.sm;

              Widget buildLeftColumn() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: vGap),
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
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<Quadrant>(
                        initialValue: _quadrant,
                        decoration: const InputDecoration(labelText: 'Quadrant'),
                        items: Quadrant.values
                            .map((q) => DropdownMenuItem(value: q, child: Text(q.name.toUpperCase())))
                            .toList(),
                        onChanged: (q) => setState(() => _quadrant = q ?? _quadrant),
                      ),
                      SizedBox(height: vGap),
                      // Categories selector
                      _CategoriesSelector(
                        selected: _categories,
                        onChanged: (sel) => setState(() => _categories = sel),
                      ),
                    ],
                  );

              final notesField = TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: detailsLabel),
                minLines: isTwoColumn ? 12 : 4,
                maxLines: 18,
              );

              final actions = Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
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
              );

              if (!isTwoColumn) {
                // Mobile/compact: single column
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLeftColumn(),
                    SizedBox(height: vGap),
                    notesField,
                    const SizedBox(height: AppSpacing.lg),
                    actions,
                  ],
                );
              }

              // Tablet/Desktop: two columns
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: buildLeftColumn()),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: notesField),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  actions,
                ],
              );
            }),
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
  const _CategoriesSelector({required this.selected, required this.onChanged});
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Categories feature removed - return empty state
    return Row(
      children: [
        const Icon(Icons.label_outline, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Text(Theme.of(context).brightness == Brightness.dark
            ? 'Categories coming soon'
            : 'Categorías próximamente'),
      ],
    );
  }
}
