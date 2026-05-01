import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/features/atlas/domain/atlas_color_resolver.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

class AtlasLegend extends StatefulWidget {
  const AtlasLegend({super.key});

  @override
  State<AtlasLegend> createState() => _AtlasLegendState();
}

class _AtlasLegendState extends State<AtlasLegend> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isNarrow = !deviceClassFromContext(context).isExpandedUp;
    final theme = Theme.of(context);
    final body = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendItem(label: 'Crítico', quadrant: Quadrant.q1),
        _LegendItem(label: 'Crecimiento', quadrant: Quadrant.q2),
        _LegendItem(label: 'De otros', quadrant: Quadrant.q3),
        _LegendItem(label: 'Archivar', quadrant: Quadrant.q4),
        _Meaning(icon: Icons.aspect_ratio, label: 'Tamaño = peso / impacto'),
        _Meaning(icon: Icons.palette_outlined, label: 'Color = cuadrante'),
        _Meaning(icon: Icons.border_outer, label: 'Borde = confianza'),
        _Meaning(icon: Icons.bolt, label: 'Brillo = foco'),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        children: [
                          const Text('Leyenda'),
                          const Spacer(),
                          Icon(_expanded
                              ? Icons.expand_less
                              : Icons.expand_more),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      body,
                    ],
                  ],
                )
              : body,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.quadrant,
  });

  final String label;
  final Quadrant quadrant;

  @override
  Widget build(BuildContext context) {
    final color =
        atlasMutedColorForQuadrant(quadrant, Theme.of(context).brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Meaning extends StatelessWidget {
  const _Meaning({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
