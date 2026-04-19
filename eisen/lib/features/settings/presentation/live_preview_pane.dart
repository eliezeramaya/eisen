import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/env/build_flags.dart';
import 'package:eisen/features/demo/demo_tasks.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivePreviewPane extends ConsumerWidget {
  const LivePreviewPane({
    super.key,
    required this.enabled,
    required this.topK,
    required this.gamma,
    required this.minArea,
    required this.qPad,
  });
  final bool enabled;
  final int topK;
  final double gamma;
  final double minArea;
  final double qPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (!enabled) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preview not active',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Enable “Preview changes” in Layout to see live effects.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    final cfg = LayoutConfig(
      topKPerQuadrant: topK,
      gamma: gamma,
      minAreaNormalized: minArea,
      quadrantPadding: qPad,
    );
    final engine = EisenTreemapHybrid(cfg);
    // Demo tasks only in dev mode
    final tasks = BuildFlags.isDemo
        ? demoTasks()
        : <Task>[
            Task(
                id: 'p1',
                title: 'Preview',
                quadrant: Quadrant.q2,
                priority: 6,
                minutes: 60),
          ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          // Compute effective min area based on viewport and configured threshold
          final viewportPx = size.width * size.height;
          final pxThreshold = LayoutConstants.minTileAreaPx(
            LayoutConstants.defaultMinTileSize,
          );
          final minArea01 = (pxThreshold / (viewportPx <= 0 ? 1.0 : viewportPx))
              .clamp(0.0, 1.0);
          final effMin = minArea01 > cfg.minAreaNormalized
              ? minArea01
              : cfg.minAreaNormalized;

          final layout = engine.layout(tasks, minArea01: effMin);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.28), width: 1),
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
