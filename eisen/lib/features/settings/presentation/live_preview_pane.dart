import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/core/constants/layout_constants.dart';

class LivePreviewPane extends ConsumerWidget {
  final bool enabled;
  final int topK;
  final double gamma;
  final double minArea;
  final double qPad;
  const LivePreviewPane({
    super.key,
    required this.enabled,
    required this.topK,
    required this.gamma,
    required this.minArea,
    required this.qPad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (!enabled) {
      return Center(
        child: Text('Preview disabled', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      );
    }
    final cfg = LayoutConfig(
      topKPerQuadrant: topK,
      gamma: gamma,
      minAreaNormalized: minArea,
      quadrantPadding: qPad,
    );
    final engine = EisenTreemapHybrid(cfg);
    // Sample tasks for preview (balanced across quadrants)
    final tasks = <Task>[
      Task(id: 'p1', title: 'Q1 A', quadrant: Quadrant.q1, priority: 9, minutes: 90),
      Task(id: 'p2', title: 'Q1 B', quadrant: Quadrant.q1, priority: 7, minutes: 60),
      Task(id: 'p3', title: 'Q2 A', quadrant: Quadrant.q2, priority: 8, minutes: 120),
      Task(id: 'p4', title: 'Q2 B', quadrant: Quadrant.q2, priority: 6, minutes: 80),
      Task(id: 'p5', title: 'Q3 A', quadrant: Quadrant.q3, priority: 5, minutes: 45),
      Task(id: 'p6', title: 'Q3 B', quadrant: Quadrant.q3, priority: 4, minutes: 40),
      Task(id: 'p7', title: 'Q4 A', quadrant: Quadrant.q4, priority: 3, minutes: 30),
      Task(id: 'p8', title: 'Q4 B', quadrant: Quadrant.q4, priority: 2, minutes: 25),
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          // Compute effective min area based on viewport and configured threshold
          final viewportPx = size.width * size.height;
          final pxThreshold = LayoutConstants.minTileAreaPx;
          final minArea01 = (pxThreshold / (viewportPx <= 0 ? 1.0 : viewportPx)).clamp(0.0, 1.0);
          final effMin = minArea01 > cfg.minAreaNormalized ? minArea01 : cfg.minAreaNormalized;

          final layout = engine.layout(tasks, minArea01: effMin);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TreemapCanvas(
                tasks: tasks,
                layout: layout,
                minimal: false,
                compact: false,
                selectedId: null,
                presentQuadrant: null,
                suggestedIds: const {},
              ),
            ),
          );
        },
      ),
    );
  }
}

