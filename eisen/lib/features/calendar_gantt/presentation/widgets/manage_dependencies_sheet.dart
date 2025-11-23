import 'package:eisen/core/haptics/haptics_service.dart';
import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart' show Task;
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for managing dependencies for a specific task.
///
/// Allows users to:
/// - View existing dependencies (prerequisites)
/// - Add new dependencies
/// - Remove existing dependencies
/// - See visual warnings about cycles
class ManageDependenciesSheet extends ConsumerStatefulWidget {
  const ManageDependenciesSheet({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<ManageDependenciesSheet> createState() =>
      _ManageDependenciesSheetState();
}

class _ManageDependenciesSheetState
    extends ConsumerState<ManageDependenciesSheet> {
  String? _selectedPrerequisiteId;
  DependencyType _selectedType = DependencyType.finishToStart;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(dependenciesControllerProvider.notifier);
    final allTasks = ref.watch(matrixTasksProvider);

    // Get current dependencies for this task
    final currentDeps = controller.getDependenciesForTask(widget.task.id);

    // Filter available tasks (exclude self and already dependent tasks)
    final availableTasks = allTasks.where((t) {
      if (t.id == widget.task.id) return false;
      if (currentDeps.any((dep) => dep.prerequisiteId == t.id)) return false;
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.link, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dependencies for "${widget.task.title}"',
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Current dependencies list
          Text(
            'Prerequisites (${currentDeps.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          if (currentDeps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No dependencies yet. This task can start anytime.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...currentDeps.map((dep) {
              final prerequisiteTask = allTasks.firstWhere(
                (t) => t.id == dep.prerequisiteId,
                orElse: () => widget.task,
              );

              return _DependencyTile(
                prerequisiteTask: prerequisiteTask,
                dependency: dep,
                onRemove: () {
                  controller.removeDependency(
                    prerequisiteId: dep.prerequisiteId,
                    dependentId: dep.dependentId,
                  );
                  setState(() => _errorMessage = null);
                },
                onTypeChange: (newType) {
                  controller.updateDependency(
                    prerequisiteId: dep.prerequisiteId,
                    dependentId: dep.dependentId,
                    type: newType,
                  );
                },
              );
            }),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Add new dependency section
          Text(
            'Add Dependency',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          if (availableTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No more tasks available to add as prerequisites.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Task selector
            DropdownButtonFormField<String>(
              value: _selectedPrerequisiteId,
              decoration: const InputDecoration(
                labelText: 'Select prerequisite task',
                border: OutlineInputBorder(),
              ),
              items: availableTasks.map((task) {
                return DropdownMenuItem(
                  value: task.id,
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrerequisiteId = value;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 12),

            // Type selector
            DropdownButtonFormField<DependencyType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Dependency type',
                border: OutlineInputBorder(),
              ),
              items: DependencyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_dependencyTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Add button
            FilledButton.icon(
              onPressed: _selectedPrerequisiteId == null
                  ? null
                  : () => _addDependency(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Dependency'),
            ),
          ],

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }

  void _addDependency(BuildContext context) {
    if (_selectedPrerequisiteId == null) return;

    final controller = ref.read(dependenciesControllerProvider.notifier);

    final result = controller.addDependency(
      prerequisiteId: _selectedPrerequisiteId!,
      dependentId: widget.task.id,
      type: _selectedType,
    );

    if (result.hasCycle) {
      // Error haptic feedback for circular dependency
      final haptics = ref.read(hapticsServiceProvider);
      haptics.error();

      setState(() {
        _errorMessage =
            'Cannot add dependency: would create a circular dependency!\n'
            'Cycle: ${result.cycleDescription}';
      });
    } else {
      setState(() {
        _selectedPrerequisiteId = null;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dependency added successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _dependencyTypeLabel(DependencyType type) {
    switch (type) {
      case DependencyType.finishToStart:
        return 'Finish-to-Start (Most common)';
      case DependencyType.startToStart:
        return 'Start-to-Start (Parallel)';
      case DependencyType.finishToFinish:
        return 'Finish-to-Finish (Synchronized)';
      case DependencyType.startToFinish:
        return 'Start-to-Finish (Rare)';
    }
  }
}

/// Individual tile showing a dependency with remove option.
class _DependencyTile extends StatelessWidget {
  const _DependencyTile({
    required this.prerequisiteTask,
    required this.dependency,
    required this.onRemove,
    required this.onTypeChange,
  });

  final Task prerequisiteTask;
  final TaskDependency dependency;
  final VoidCallback onRemove;
  final Function(DependencyType) onTypeChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _iconForType(dependency.type),
          color: theme.colorScheme.primary,
        ),
        title: Text(
          prerequisiteTask.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_typeDescription(dependency.type)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
          tooltip: 'Remove dependency',
        ),
        onTap: () {
          // Could show a dialog to change type
        },
      ),
    );
  }

  IconData _iconForType(DependencyType type) {
    switch (type) {
      case DependencyType.finishToStart:
        return Icons.arrow_forward;
      case DependencyType.startToStart:
        return Icons.start;
      case DependencyType.finishToFinish:
        return Icons.done_all;
      case DependencyType.startToFinish:
        return Icons.swap_horiz;
    }
  }

  String _typeDescription(DependencyType type) {
    switch (type) {
      case DependencyType.finishToStart:
        return 'Starts when prerequisite finishes';
      case DependencyType.startToStart:
        return 'Starts when prerequisite starts';
      case DependencyType.finishToFinish:
        return 'Finishes when prerequisite finishes';
      case DependencyType.startToFinish:
        return 'Finishes when prerequisite starts';
    }
  }
}

/// Helper function to show the dependencies sheet.
void showManageDependenciesSheet(BuildContext context, Task task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ManageDependenciesSheet(task: task),
  );
}
