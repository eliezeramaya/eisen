import 'dart:ui';

import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the treemap matrix with advanced zoom/pan interactions:
/// - Pinch zoom on touch devices
/// - Ctrl/⌘ + scroll zoom on desktop
/// - Double-tap zoom in/out with quadrant focus
/// - Pan when zoomed in
class MatrixInteractiveWrapper extends ConsumerStatefulWidget {
  const MatrixInteractiveWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<MatrixInteractiveWrapper> createState() =>
      _MatrixInteractiveWrapperState();
}

class _MatrixInteractiveWrapperState
    extends ConsumerState<MatrixInteractiveWrapper> {
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset? _lastDoubleTapLocal;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matrixControllerProvider);
    final controller = ref.read(matrixControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        Widget content = Transform.translate(
          offset: state.zoomOffset,
          child: Transform.scale(
            scale: state.zoomScale,
            alignment: Alignment.center,
            child: widget.child,
          ),
        );

        content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _startScale = state.zoomScale;
            _startOffset = state.zoomOffset;
          },
          onScaleUpdate: (details) {
            // Pinch zoom
            if (details.scale != 1.0) {
              final normalizedFocal = Offset(
                (details.localFocalPoint.dx / size.width).clamp(0.0, 1.0),
                (details.localFocalPoint.dy / size.height).clamp(0.0, 1.0),
              );
              final newScale = _startScale * details.scale;
              controller.setZoomScale(newScale, focalPoint: normalizedFocal);
            }
            // Pan when zoomed in
            if (state.zoomScale > 1.1) {
              controller
                  .setZoomOffset(_startOffset + details.focalPointDelta);
            }
          },
          onDoubleTapDown: (details) {
            _lastDoubleTapLocal = details.localPosition;
          },
          onDoubleTap: () {
            final pos = _lastDoubleTapLocal;
            final q = pos == null ? null : _quadrantForOffset(pos, size);
            final scale = state.zoomScale;
            if (scale < 1.2) {
              controller.animateToScale(1.6, quadrant: q);
            } else {
              controller.animateToScale(1.0);
            }
          },
          child: content,
        );

        content = Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final keys = HardwareKeyboard.instance.logicalKeysPressed;
              final hasCtrl = keys.contains(LogicalKeyboardKey.controlLeft) ||
                  keys.contains(LogicalKeyboardKey.controlRight) ||
                  keys.contains(LogicalKeyboardKey.metaLeft) ||
                  keys.contains(LogicalKeyboardKey.metaRight);
              if (!hasCtrl) return;
              final direction = event.scrollDelta.dy.sign;
              if (direction == 0) return;
              final delta = -direction * 0.1;
              final normalized = Offset(
                (event.localPosition.dx / size.width).clamp(0.0, 1.0),
                (event.localPosition.dy / size.height).clamp(0.0, 1.0),
              );
              controller.setZoomScale(state.zoomScale + delta,
                  focalPoint: normalized);
            }
          },
          child: content,
        );

        return ClipRect(child: content);
      },
    );
  }

  Quadrant _quadrantForOffset(Offset pos, Size size) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    if (pos.dx < halfW && pos.dy < halfH) return Quadrant.q1;
    if (pos.dx >= halfW && pos.dy < halfH) return Quadrant.q2;
    if (pos.dx < halfW && pos.dy >= halfH) return Quadrant.q3;
    return Quadrant.q4;
  }
}

