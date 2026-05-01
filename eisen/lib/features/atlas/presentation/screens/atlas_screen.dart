import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_breadcrumb.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_canvas.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_detail_panel.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_legend.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_toolbar.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AtlasScreen extends ConsumerWidget {
  const AtlasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(atlasVisibleNodesProvider);
    final focusedIds = ref.watch(atlasFocusedTaskIdsProvider);
    final selectedTask = ref.watch(atlasSelectedTaskProvider);
    final allTasks = ref.watch(matrixTasksProvider);
    final atlasTasks = ref.watch(atlasTasksProvider);
    final hasFilters = ref.watch(atlasHasActiveFiltersProvider);
    final path = ref.watch(atlasResolvedDrilldownPathProvider);
    final width = MediaQuery.sizeOf(context).width;
    final deviceClass = deviceClassOf(width);
    final showDetailPanel = deviceClass.isExpandedUp;
    final emptyKind = _emptyKind(
      allTasks: allTasks,
      atlasTasks: atlasTasks,
      hasFilters: hasFilters,
    );

    Future<void> openReclassify(Task task) async {
      final categories = ref.read(categoryConfigControllerProvider);
      final original = _classificationMetadataForTask(task);
      final result = await showModalBottomSheet<QuickReclassifyResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => QuickReclassifySheet(
          metadata: original,
          categories: categories,
        ),
      );
      if (result == null) return;

      final corrected = result.metadata;
      Task? updatedTask;
      ref.read(matrixControllerProvider.notifier).updateTask(
        task.id,
        (current) {
          final classified = applyClassificationToTask(
            task: current,
            metadata: corrected,
            categories: ref.read(categoryConfigControllerProvider),
          );
          updatedTask = corrected.suggestedQuadrant == null
              ? classified
              : classified.copyWith(quadrant: corrected.suggestedQuadrant);
          return updatedTask!;
        },
      );
      if (updatedTask != null) {
        ref.read(atlasSelectedTaskProvider.notifier).select(updatedTask);
      }

      await ref
          .read(classificationReviewControllerProvider.notifier)
          .recordCorrection(
            taskId: task.id,
            inputText: original.inputText,
            original: original,
            corrected: corrected,
          );
      if (result.createRule) {
        await ref.read(classificationRulesControllerProvider.notifier).add(
              buildRuleFromReclassification(
                inputText: original.inputText,
                corrected: corrected,
              ),
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clasificación corregida')),
      );
    }

    void selectTask(Task task) {
      ref.read(atlasSelectedTaskProvider.notifier).select(task);
      ref.read(matrixControllerProvider.notifier).select(task.id);
      if (!showDetailPanel) {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AtlasDetailPanel(
                task: task,
                onComplete: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .markTaskDone(task.id);
                  Navigator.of(context).pop();
                },
                onEdit: () => Navigator.of(context).pop(),
                onReclassify: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => openReclassify(task),
                  );
                },
                onArchive: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .archiveTask(task.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      }
    }

    void showQuickActions(Task task) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Completar'),
                onTap: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .markTaskDone(task.id);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archivar'),
                onTap: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .archiveTask(task.id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
    }

    final canvas = AtlasCanvas(
      nodes: nodes,
      focusedTaskIds: focusedIds,
      selectedTaskId: selectedTask?.id,
      emptyStateKind: emptyKind,
      onTaskSelected: selectTask,
      onTaskLongPress: showQuickActions,
      onGroupTap: (node) {
        ref.read(atlasDrilldownPathProvider.notifier).enter(node);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AtlasToolbar(),
        const AtlasLegend(),
        AtlasBreadcrumb(
          path: path,
          onRoot: () {
            ref.read(atlasDrilldownPathProvider.notifier).clear();
          },
          onSelect: (index) {
            ref.read(atlasDrilldownPathProvider.notifier).jumpTo(index);
          },
        ),
        Expanded(
          child: showDetailPanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: canvas),
                    if (selectedTask != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: deviceClass.isLarge ? 340 : 300,
                        child: AtlasDetailPanel(
                          task: selectedTask,
                          onClose: () {
                            ref
                                .read(atlasSelectedTaskProvider.notifier)
                                .select(null);
                          },
                          onComplete: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .markTaskDone(selectedTask.id);
                          },
                          onEdit: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .select(selectedTask.id);
                          },
                          onReclassify: () => openReclassify(selectedTask),
                          onArchive: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .archiveTask(selectedTask.id);
                          },
                        ),
                      ),
                    ],
                  ],
                )
              : canvas,
        ),
      ],
    );
  }

  AtlasEmptyStateKind _emptyKind({
    required List<Task> allTasks,
    required List<Task> atlasTasks,
    required bool hasFilters,
  }) {
    if (atlasTasks.isNotEmpty) return AtlasEmptyStateKind.noTasks;
    if (hasFilters) return AtlasEmptyStateKind.filters;
    if (allTasks.isEmpty) return AtlasEmptyStateKind.noTasks;
    return AtlasEmptyStateKind.noActiveTasks;
  }

  ClassificationMetadata _classificationMetadataForTask(Task task) {
    final existing = task.classificationMetadata;
    if (existing != null) {
      return existing.copyWith(
        inputText: existing.inputText.isEmpty ? task.title : existing.inputText,
        normalizedText: existing.normalizedText.isEmpty
            ? task.title.trim().toLowerCase()
            : existing.normalizedText,
        suggestedQuadrant: existing.suggestedQuadrant ?? task.quadrant,
      );
    }

    return ClassificationMetadata(
      inputText: task.title,
      normalizedText: task.title.trim().toLowerCase(),
      categoryId: task.categoryId,
      entryKind: task.kind,
      timeHorizon: task.horizon ?? TimeHorizon.someday,
      energyLevel: task.energy ?? EnergyLevel.medium,
      priorityLevel: _priorityLevelForTask(task),
      confidenceScore: switch (task.classificationConfidence) {
        ConfidenceLevel.high => 0.86,
        ConfidenceLevel.medium => 0.62,
        ConfidenceLevel.low => 0.38,
        null => 0.45,
      },
      confidenceLevel: task.classificationConfidence ?? ConfidenceLevel.medium,
      matchedKeywords: [
        for (final tag in [...task.tags, ...task.autoTags])
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      suggestedQuadrant: task.quadrant,
      quadrantReason: 'Reclasificación iniciada desde Atlas.',
    );
  }

  PriorityLevel _priorityLevelForTask(Task task) {
    if (task.inferredPriority != null) return task.inferredPriority!;
    if (task.priority >= 9) return PriorityLevel.critical;
    if (task.priority >= 7) return PriorityLevel.high;
    if (task.priority >= 4) return PriorityLevel.medium;
    return PriorityLevel.low;
  }
}
