import 'package:eisen/features/atlas/domain/atlas_color_resolver.dart';
import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';

class AtlasLegend extends StatefulWidget {
  const AtlasLegend({
    super.key,
    this.config,
    required this.labelStyle,
  });

  final AtlasResponsiveConfig? config;
  final QuadrantLabelStyle labelStyle;

  @override
  State<AtlasLegend> createState() => _AtlasLegendState();
}

class _AtlasLegendState extends State<AtlasLegend> {
  late bool _expanded;
  bool _userOverrodeExpanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = _defaultExpanded;
  }

  @override
  void didUpdateWidget(covariant AtlasLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_userOverrodeExpanded &&
        oldWidget.config?.showLegendExpandedByDefault !=
            widget.config?.showLegendExpandedByDefault) {
      _expanded = _defaultExpanded;
    }
  }

  bool get _defaultExpanded =>
      widget.config?.showLegendExpandedByDefault ?? true;

  @override
  Widget build(BuildContext context) {
    final resolvedConfig = widget.config ??
        atlasResponsiveConfigForWidth(MediaQuery.sizeOf(context).width);
    final canCollapse = !resolvedConfig.showLegendExpandedByDefault;
    final theme = Theme.of(context);
    final body = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendItem(
          label: getQuadrantLabel(Quadrant.q1, widget.labelStyle).title,
          quadrant: Quadrant.q1,
        ),
        _LegendItem(
          label: getQuadrantLabel(Quadrant.q2, widget.labelStyle).title,
          quadrant: Quadrant.q2,
        ),
        _LegendItem(
          label: getQuadrantLabel(Quadrant.q3, widget.labelStyle).title,
          quadrant: Quadrant.q3,
        ),
        _LegendItem(
          label: getQuadrantLabel(Quadrant.q4, widget.labelStyle).title,
          quadrant: Quadrant.q4,
        ),
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
          child: canCollapse
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _userOverrodeExpanded = true;
                        _expanded = !_expanded;
                      }),
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
