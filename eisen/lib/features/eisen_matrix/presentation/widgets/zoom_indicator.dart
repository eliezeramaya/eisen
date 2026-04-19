import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ZoomIndicator extends ConsumerWidget {
  const ZoomIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomScale = ref.watch(
      matrixControllerProvider.select((s) => s.zoomScale),
    );
    final zoomQuadrant = ref.watch(
      matrixControllerProvider.select((s) => s.zoomQuadrant),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    double globalOpacity;
    double quadrantOpacity;
    double detailOpacity;
    String label;

    if (zoomScale <= 1.1) {
      globalOpacity = 1.0;
      quadrantOpacity = 0.3;
      detailOpacity = 0.15;
      label = isEs ? 'Global' : 'Global';
    } else if (zoomScale <= 2.0) {
      globalOpacity = 0.3;
      quadrantOpacity = 1.0;
      detailOpacity = 0.4;
      label = isEs ? 'Cuadrante' : 'Quadrant';
    } else {
      globalOpacity = 0.15;
      quadrantOpacity = 0.5;
      detailOpacity = 1.0;
      label = isEs ? 'Detalle' : 'Detail';
    }

    final qLabel =
        zoomQuadrant != null ? ' · ${zoomQuadrant.name.toUpperCase()}' : '';

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
                _dot(cs.primary, globalOpacity),
                const SizedBox(width: 4),
                _dot(cs.primary, quadrantOpacity),
                const SizedBox(width: 4),
                _dot(cs.primary, detailOpacity),
                const SizedBox(width: 8),
                Text(
                  '$label$qLabel',
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
}
