import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:flutter/material.dart';

class AtlasExportOptionsSheet extends StatefulWidget {
  const AtlasExportOptionsSheet({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final AtlasPdfOptions options;
  final ValueChanged<AtlasPdfOptions> onChanged;

  @override
  State<AtlasExportOptionsSheet> createState() => _AtlasExportOptionsSheetState();
}

class _AtlasExportOptionsSheetState extends State<AtlasExportOptionsSheet> {
  late AtlasPdfOptions _options;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
  }

  void _update(AtlasPdfOptions updated) {
    setState(() => _options = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Opciones de exportación',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _SectionHeader(label: 'Tamaño de papel'),
                    _PaperSizeGroup(
                      label: 'Estándar',
                      sizes: const [
                        AtlasPaperSize.letter,
                        AtlasPaperSize.a4,
                        AtlasPaperSize.legal,
                        AtlasPaperSize.a3,
                      ],
                      selected: _options.paperSize,
                      onSelected: (s) => _update(_options.copyWith(paperSize: s)),
                    ),
                    _PaperSizeGroup(
                      label: 'Arquitectónico',
                      sizes: const [
                        AtlasPaperSize.archA,
                        AtlasPaperSize.archB,
                        AtlasPaperSize.archC,
                        AtlasPaperSize.archD,
                        AtlasPaperSize.archE,
                        AtlasPaperSize.archE1,
                      ],
                      selected: _options.paperSize,
                      onSelected: (s) => _update(_options.copyWith(paperSize: s)),
                    ),
                    const Divider(),
                    _SectionHeader(label: 'Orientación'),
                    _OrientationToggle(
                      orientation: _options.orientation,
                      onChanged: (o) => _update(_options.copyWith(orientation: o)),
                    ),
                    const Divider(),
                    _SectionHeader(label: 'Contenido'),
                    _ContentToggle(
                      label: 'Título y fecha',
                      value: _options.includeTitle && _options.includeDate,
                      onChanged: (v) => _update(
                        _options.copyWith(includeTitle: v, includeDate: v),
                      ),
                    ),
                    _ContentToggle(
                      label: 'Leyenda',
                      value: _options.includeLegend,
                      onChanged: (v) => _update(_options.copyWith(includeLegend: v)),
                    ),
                    _ContentToggle(
                      label: 'Insights',
                      value: _options.includeInsights,
                      onChanged: (v) => _update(_options.copyWith(includeInsights: v)),
                    ),
                    _ContentToggle(
                      label: 'Filtros activos',
                      value: _options.includeFilters,
                      onChanged: (v) => _update(_options.copyWith(includeFilters: v)),
                    ),
                    _ContentToggle(
                      label: 'Resumen por cuadrante',
                      value: _options.includeTaskSummary,
                      onChanged: (v) => _update(_options.copyWith(includeTaskSummary: v)),
                    ),
                    _ContentToggle(
                      label: 'Lista de tareas',
                      value: _options.includeTaskList,
                      onChanged: (v) => _update(_options.copyWith(includeTaskList: v)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => widget.onChanged(_options),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _PaperSizeGroup extends StatelessWidget {
  const _PaperSizeGroup({
    required this.label,
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<AtlasPaperSize> sizes;
  final AtlasPaperSize selected;
  final ValueChanged<AtlasPaperSize> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final size in sizes)
              ChoiceChip(
                label: Text(atlasPaperSizeLabel(size)),
                selected: selected == size,
                onSelected: (_) => onSelected(size),
              ),
          ],
        ),
      ],
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({
    required this.orientation,
    required this.onChanged,
  });

  final AtlasPaperOrientation orientation;
  final ValueChanged<AtlasPaperOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OrientationChip(
            icon: Icons.crop_portrait_outlined,
            label: 'Vertical',
            selected: orientation == AtlasPaperOrientation.portrait,
            onTap: () => onChanged(AtlasPaperOrientation.portrait),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OrientationChip(
            icon: Icons.crop_landscape_outlined,
            label: 'Horizontal',
            selected: orientation == AtlasPaperOrientation.landscape,
            onTap: () => onChanged(AtlasPaperOrientation.landscape),
          ),
        ),
      ],
    );
  }
}

class _OrientationChip extends StatelessWidget {
  const _OrientationChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentToggle extends StatelessWidget {
  const _ContentToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      dense: true,
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
