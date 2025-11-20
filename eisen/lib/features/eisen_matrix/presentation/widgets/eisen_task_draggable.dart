import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Premium draggable wrapper for a Matrix task.
///
/// - Uses [LongPressDraggable] for deliberate drag on touch devices.
/// - Semi-opaque feedback (0.85) while dragging.
/// - Fades the original child to 0.4 opacity while dragging.
/// - Notifies [MatrixController] via [setDragging] / [clearDragging].
class EisenTaskDraggable extends ConsumerWidget {
  const EisenTaskDraggable({
    super.key,
    required this.task,
    required this.child,
  });

  final Task task;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(matrixControllerProvider.notifier);

    // Keep selection highlight consistent with MatrixController state.
    final isSelected = ref.watch(
      matrixControllerProvider.select((s) => s.selectedId == task.id),
    );

    Widget visualChild = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: isSelected ? 1.02 : 1.0,
      child: child,
    );

    visualChild = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: visualChild,
    );

    return LongPressDraggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160),
            child: visualChild,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: visualChild,
      ),
      onDragStarted: () => controller.setDragging(task),
      onDragEnd: (_) => controller.clearDragging(),
      onDraggableCanceled: (_, __) => controller.clearDragging(),
      child: visualChild,
    );
  }
}

