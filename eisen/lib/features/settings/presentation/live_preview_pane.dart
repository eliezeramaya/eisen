import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/env/build_flags.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/demo/demo_tasks.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivePreviewPane extends ConsumerWidget {
  const LivePreviewPane({
    super.key,
    required this.enabled,
    required this.screenSize,
    required this.treemapDensityProfile,
    required this.topK,
    required this.gamma,
    required this.minArea,
    required this.qPad,
    required this.minTileSizePx,
  });

  final bool enabled;
  final Size screenSize;
  final String treemapDensityProfile;
  final int topK;
  final double gamma;
  final double minArea;
  final double qPad;
  final double minTileSizePx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (!enabled) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Preview not active',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable “Preview changes” in Layout to see live effects.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final resolved = TreemapDensityResolver.resolve(
      prefs: UiPrefsData(
        topKPerQuadrant: topK,
        gamma: gamma,
        minAreaNormalized: minArea,
        quadrantPadding: qPad,
        minTileSizePx: minTileSizePx,
        treemapDensityProfile: treemapDensityProfile,
      ),
      screenSize: screenSize,
    );
    final engine = EisenTreemapHybrid(resolved.layoutConfig);
    final tasks = BuildFlags.isDemo
        ? demoTasks()
        : <Task>[
            Task(
              id: 'p1',
              title: 'Preview',
              quadrant: Quadrant.q2,
              priority: 6,
              minutes: 60,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final viewportPx = previewSize.width * previewSize.height;
          final pxThreshold = LayoutConstants.minTileAreaPx(
            resolved.minTileSizePx,
          );
          final densityFactor = resolved.compactDensity ? 0.7 : 1.0;
          final minArea01 = ((pxThreshold * densityFactor) /
                  (viewportPx <= 0 ? 1.0 : viewportPx))
              .clamp(0.0, 1.0);
          final effectiveMinArea = minArea01 > resolved.minAreaNormalized
              ? minArea01
              : resolved.minAreaNormalized;
          final layout = engine.layout(tasks, minArea01: effectiveMinArea);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  '${_profileLabel(resolved.profile)} · '
                  '${resolved.topKPerQuadrant} tasks/quadrant · '
                  '${resolved.minTileSizePx.toStringAsFixed(0)}px min tile',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.28),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TreemapCanvas(
                      tasks: tasks,
                      layout: layout,
                      minimal: false,
                      compact: resolved.compactDensity,
                      selectedId: null,
                      presentQuadrant: null,
                      suggestedIds: const {},
                      minTileSizePx: resolved.minTileSizePx,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _profileLabel(String profile) {
    return switch (profile) {
      TreemapDensityProfiles.airy => 'Airy',
      TreemapDensityProfiles.balanced => 'Balanced',
      TreemapDensityProfiles.compact => 'Compact',
      TreemapDensityProfiles.detailed => 'Detailed',
      TreemapDensityProfiles.custom => 'Custom',
      _ => 'Balanced',
    };
  }
}
