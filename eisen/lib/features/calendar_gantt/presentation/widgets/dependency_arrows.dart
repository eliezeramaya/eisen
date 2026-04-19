import 'dart:math' as math;

import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:flutter/material.dart';

/// Convert logical dependencies into arrow specs anchored to span rectangles.
List<DependencyArrow> computeDependencyArrows({
  required List<TaskDependency> dependencies,
  required Map<String, Rect> spanRects,
  Color color = Colors.orangeAccent,
}) {
  final arrows = <DependencyArrow>[];

  for (final dep in dependencies) {
    final fromRect = spanRects[dep.prerequisiteId];
    final toRect = spanRects[dep.dependentId];
    if (fromRect == null || toRect == null) continue;

    arrows.add(DependencyArrow(
      fromTaskId: dep.prerequisiteId,
      toTaskId: dep.dependentId,
      startPoint: Offset(fromRect.right, fromRect.center.dy),
      endPoint: Offset(toRect.left, toRect.center.dy),
      dependencyType: dep.type,
      color: color,
    ));
  }

  return arrows;
}

/// Visual representation of a task dependency arrow in the Gantt chart.
///
/// Draws a curved arrow from the prerequisite task to the dependent task,
/// with different styles based on the dependency type.
class DependencyArrowPainter extends CustomPainter {
  DependencyArrowPainter({
    required this.startPoint,
    required this.endPoint,
    required this.dependencyType,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.showArrowhead = true,
    this.curveFactor = 0.3,
  });

  final Offset startPoint;
  final Offset endPoint;
  final DependencyType dependencyType;
  final Color color;
  final double strokeWidth;
  final bool showArrowhead;
  final double curveFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw different arrow styles based on dependency type
    switch (dependencyType) {
      case DependencyType.finishToStart:
        _drawFinishToStartArrow(canvas, paint);
        break;
      case DependencyType.startToStart:
        _drawStartToStartArrow(canvas, paint);
        break;
      case DependencyType.finishToFinish:
        _drawFinishToFinishArrow(canvas, paint);
        break;
      case DependencyType.startToFinish:
        _drawStartToFinishArrow(canvas, paint);
        break;
    }
  }

  void _drawFinishToStartArrow(Canvas canvas, Paint paint) {
    // Curved line from finish of prerequisite to start of dependent
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * curveFactor,
      startPoint.dy,
    );
    final controlPoint2 = Offset(
      endPoint.dx - (endPoint.dx - startPoint.dx) * curveFactor,
      endPoint.dy,
    );

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);

    if (showArrowhead) {
      _drawArrowhead(canvas, paint, controlPoint2, endPoint);
    }
  }

  void _drawStartToStartArrow(Canvas canvas, Paint paint) {
    // Dashed line for start-to-start (parallel tasks)
    paint.style = PaintingStyle.stroke;
    final dashWidth = 5.0;
    final dashSpace = 5.0;
    final path = Path();

    double distance = 0;
    final totalDistance = (endPoint - startPoint).distance;
    final unitVector = (endPoint - startPoint) / totalDistance;

    while (distance < totalDistance) {
      final dashEnd = math.min(distance + dashWidth, totalDistance);
      path.moveTo(
        startPoint.dx + unitVector.dx * distance,
        startPoint.dy + unitVector.dy * distance,
      );
      path.lineTo(
        startPoint.dx + unitVector.dx * dashEnd,
        startPoint.dy + unitVector.dy * dashEnd,
      );
      distance += dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);

    if (showArrowhead) {
      _drawArrowhead(
        canvas,
        paint,
        endPoint - unitVector * 10,
        endPoint,
      );
    }
  }

  void _drawFinishToFinishArrow(Canvas canvas, Paint paint) {
    // Dotted line for finish-to-finish (synchronized completion)
    final dotRadius = strokeWidth;
    final dotSpace = 8.0;
    final totalDistance = (endPoint - startPoint).distance;
    final unitVector = (endPoint - startPoint) / totalDistance;

    paint.style = PaintingStyle.fill;

    double distance = 0;
    while (distance < totalDistance) {
      final dotCenter = Offset(
        startPoint.dx + unitVector.dx * distance,
        startPoint.dy + unitVector.dy * distance,
      );
      canvas.drawCircle(dotCenter, dotRadius, paint);
      distance += dotSpace;
    }

    if (showArrowhead) {
      paint.style = PaintingStyle.stroke;
      _drawArrowhead(
        canvas,
        paint,
        endPoint - unitVector * 10,
        endPoint,
      );
    }
  }

  void _drawStartToFinishArrow(Canvas canvas, Paint paint) {
    // Uncommon: draw with double line
    final path1 = Path();
    final path2 = Path();
    final offset = 2.0;

    final perpendicular = Offset(
          -(endPoint.dy - startPoint.dy),
          endPoint.dx - startPoint.dx,
        ).normalize() *
        offset;

    path1.moveTo(
      startPoint.dx + perpendicular.dx,
      startPoint.dy + perpendicular.dy,
    );
    path1.lineTo(
      endPoint.dx + perpendicular.dx,
      endPoint.dy + perpendicular.dy,
    );

    path2.moveTo(
      startPoint.dx - perpendicular.dx,
      startPoint.dy - perpendicular.dy,
    );
    path2.lineTo(
      endPoint.dx - perpendicular.dx,
      endPoint.dy - perpendicular.dy,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    if (showArrowhead) {
      final unitVector = (endPoint - startPoint).normalize();
      _drawArrowhead(canvas, paint, endPoint - unitVector * 10, endPoint);
    }
  }

  void _drawArrowhead(
    Canvas canvas,
    Paint paint,
    Offset fromPoint,
    Offset toPoint,
  ) {
    final arrowSize = 8.0;
    final angle =
        math.atan2(toPoint.dy - fromPoint.dy, toPoint.dx - fromPoint.dx);

    final arrowPath = Path()
      ..moveTo(toPoint.dx, toPoint.dy)
      ..lineTo(
        toPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
        toPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        toPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
        toPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(DependencyArrowPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.dependencyType != dependencyType ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Widget that renders dependency arrows on top of a Gantt chart.
///
/// Takes a list of [DependencyArrow] specifications and renders them
/// using [CustomPaint] with proper layering and clipping.
class DependencyArrowsLayer extends StatelessWidget {
  const DependencyArrowsLayer({
    super.key,
    required this.arrows,
    required this.child,
  });

  final List<DependencyArrow> arrows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: MultiArrowPainter(arrows: arrows),
            ),
          ),
        ),
      ],
    );
  }
}

/// Data class representing a single dependency arrow to be drawn.
@immutable
class DependencyArrow {
  const DependencyArrow({
    required this.fromTaskId,
    required this.toTaskId,
    required this.startPoint,
    required this.endPoint,
    required this.dependencyType,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.isHighlighted = false,
  });

  final String fromTaskId;
  final String toTaskId;
  final Offset startPoint;
  final Offset endPoint;
  final DependencyType dependencyType;
  final Color color;
  final double strokeWidth;
  final bool isHighlighted;

  DependencyArrow copyWith({
    String? fromTaskId,
    String? toTaskId,
    Offset? startPoint,
    Offset? endPoint,
    DependencyType? dependencyType,
    Color? color,
    double? strokeWidth,
    bool? isHighlighted,
  }) {
    return DependencyArrow(
      fromTaskId: fromTaskId ?? this.fromTaskId,
      toTaskId: toTaskId ?? this.toTaskId,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      dependencyType: dependencyType ?? this.dependencyType,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }
}

/// Custom painter that draws multiple dependency arrows.
class MultiArrowPainter extends CustomPainter {
  MultiArrowPainter({required this.arrows});

  final List<DependencyArrow> arrows;

  @override
  void paint(Canvas canvas, Size size) {
    for (final arrow in arrows) {
      final painter = DependencyArrowPainter(
        startPoint: arrow.startPoint,
        endPoint: arrow.endPoint,
        dependencyType: arrow.dependencyType,
        color: arrow.isHighlighted
            ? arrow.color.withValues(alpha: 1.0)
            : arrow.color.withValues(alpha: 0.6),
        strokeWidth:
            arrow.isHighlighted ? arrow.strokeWidth + 1 : arrow.strokeWidth,
      );

      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(MultiArrowPainter oldDelegate) {
    return oldDelegate.arrows != arrows;
  }
}

/// Extension to normalize Offset vectors.
extension OffsetNormalize on Offset {
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return this / magnitude;
  }
}
