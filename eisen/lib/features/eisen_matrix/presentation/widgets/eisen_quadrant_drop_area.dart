import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drop target for a quadrant in the Eisenhower matrix.
///
/// Shows a subtle animated border when a draggable task hovers over it and
/// moves the task to the target quadrant on drop.
class EisenQuadrantDropArea extends ConsumerStatefulWidget {
  const EisenQuadrantDropArea({
    super.key,
    required this.quadrant,
    required this.child,
  });

  final Quadrant quadrant;
  final Widget child;

  @override
  ConsumerState<EisenQuadrantDropArea> createState() =>
      _EisenQuadrantDropAreaState();
}

class _EisenQuadrantDropAreaState
    extends ConsumerState<EisenQuadrantDropArea> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(matrixControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (task) {
        setState(() => _hovered = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _hovered = false);
      },
      onAcceptWithDetails: (details) {
        controller.moveTaskToQuadrant(details.data.id, widget.quadrant);
        controller.clearDragging();
        setState(() => _hovered = false);
      },
      builder: (context, candidateData, rejectedData) {
        final active = _hovered || candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(
                    color: cs.primary.withValues(alpha: 0.7),
                    width: 2,
                  )
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}
