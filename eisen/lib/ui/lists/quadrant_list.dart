import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/category_color_service_factory.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/eisen_task_draggable.dart';
import 'package:eisen/ui/task/task_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuadrantList extends ConsumerWidget {
  const QuadrantList({
    super.key,
    required this.tasks,
    required this.header,
    this.onToggle,
    this.onOpen,
  });
  final List<Task> tasks;
  final Widget header; // includes title and counter
  final void Function(Task task)? onToggle;
  final void Function(Task task)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve classification settings once per list rebuild — not per row.
    final settings = ref.watch(classificationSettingsControllerProvider);
    final categories = ref.watch(categoryConfigControllerProvider);
    final categoryColors = buildClassificationCategoryColorService(
      categories: categories,
    );

    const prototype = TaskRow(
      task: Task(
        id: '_',
        title: 'prototype',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 30,
      ),
    );
    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      thickness: 6,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              child: header,
              minExtent: 40,
              maxExtent: 48,
            ),
          ),
          SliverPrototypeExtentList(
            prototypeItem: prototype,
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final task = tasks[i];
                final category = categoryForTask(categories, task);
                final accent = settings.colorByCategory && category != null
                    ? categoryColors.getColorForCategory(category.name)
                    : null;
                return EisenTaskDraggable(
                  key: ValueKey(task.id),
                  task: task,
                  child: TaskRow(
                    task: task,
                    onToggle: onToggle == null ? null : () => onToggle!(task),
                    onOpen: onOpen == null ? null : () => onOpen!(task),
                    categoryAccent: accent,
                    categoryName: settings.colorByCategory && category != null ? category.name : null,
                    categoryNameLightBg: category != null
                        ? categoryColors.getLightVariant(
                            category.name,
                            opacity: 0.18,
                          )
                        : null,
                    categoryNameBorder: category != null
                        ? categoryColors.getDarkVariant(
                            category.name,
                            opacity: 0.55,
                          )
                        : null,
                    showConfidenceIndicators: settings.showConfidenceIndicators,
                    showAutoTags: settings.showAutoTags,
                  ),
                );
              },
              childCount: tasks.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.child,
    this.minExtent = 44,
    this.maxExtent = 48,
  });
  final Widget child;
  @override
  final double minExtent;
  @override
  final double maxExtent;
  @override
  Widget build(context, shrinkOffset, overlapsContent) =>
      Material(color: Theme.of(context).colorScheme.surface, child: child);
  @override
  bool shouldRebuild(covariant _HeaderDelegate old) => false;
}
