import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/domain/task_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskViewModeSwitch extends ConsumerWidget {
  const TaskViewModeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(taskViewModeProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 520;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SegmentedButton<TaskViewMode>(
          showSelectedIcon: !isCompact,
          segments: const [
            ButtonSegment(
              value: TaskViewMode.matrix,
              label: Text('Matriz'),
              icon: Icon(Icons.grid_view_rounded),
            ),
            ButtonSegment(
              value: TaskViewMode.atlas,
              label: Text('Atlas'),
              icon: Icon(Icons.map_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            ref.read(taskViewModeProvider.notifier).update(selection.single);
          },
        ),
      ),
    );
  }
}
