import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/treemap_viewport_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ZoomIndicator extends ConsumerWidget {
  const ZoomIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomScale =
        ref.watch(matrixControllerProvider.select((s) => s.zoomScale));
    final zoomQuadrant =
        ref.watch(matrixControllerProvider.select((s) => s.zoomQuadrant));
    final viewport = ref.watch(treemapViewportControllerProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final labels = <TreemapZoomLevel, String>{
      TreemapZoomLevel.global: isEs ? 'Global' : 'Global',
      TreemapZoomLevel.category: isEs ? 'Categorías' : 'Categories',
      TreemapZoomLevel.subcategory: isEs ? 'Subcategorías' : 'Subcategories',
      TreemapZoomLevel.group: isEs ? 'Grupos' : 'Groups',
      TreemapZoomLevel.task: isEs ? 'Tareas' : 'Tasks',
    };
    final activeLevel = viewport.zoomLevel;
    final semanticMode = activeLevel != TreemapZoomLevel.global;
    final fallbackLabel = zoomScale <= 1.1
        ? 'Global'
        : zoomScale <= 2.0
            ? (isEs ? 'Cuadrante' : 'Quadrant')
            : (isEs ? 'Detalle' : 'Detail');
    final qLabel = zoomQuadrant != null && !semanticMode
        ? ' · ${zoomQuadrant.name.toUpperCase()}'
        : '';

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (semanticMode) ...[
                  for (final level in TreemapZoomLevel.values) ...[
                    _pill(
                      context,
                      labels[level]!,
                      active: level == activeLevel,
                    ),
                    if (level != TreemapZoomLevel.values.last)
                      const SizedBox(width: 4),
                  ],
                ] else ...[
                  _dot(cs.primary, zoomScale <= 1.1 ? 1 : 0.3),
                  const SizedBox(width: 4),
                  _dot(cs.primary,
                      zoomScale > 1.1 && zoomScale <= 2.0 ? 1 : 0.3),
                  const SizedBox(width: 4),
                  _dot(cs.primary, zoomScale > 2.0 ? 1 : 0.2),
                ],
                const SizedBox(width: 8),
                Text(
                  '${semanticMode ? labels[activeLevel] : fallbackLabel}$qLabel',
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, {required bool active}) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? cs.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? cs.primary : cs.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}
