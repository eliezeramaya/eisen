import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisualizationBehaviorSection extends ConsumerWidget {
  const VisualizationBehaviorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(classificationSettingsControllerProvider);
    final controller =
        ref.read(classificationSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Visual behavior',
          subtitle:
              'Decide cómo la clasificación afecta color, agrupación y señales visibles.',
        ),
        EisenCard(
          outlined: true,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.colorByCategory,
                onChanged: (value) => controller.updateVisualization(
                  colorByCategory: value,
                ),
                title: const Text('Color por categoría'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.showConfidenceIndicators,
                onChanged: (value) => controller.updateVisualization(
                  showConfidenceIndicators: value,
                ),
                title: const Text('Mostrar confianza'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.showAutoTags,
                onChanged: (value) => controller.updateVisualization(
                  showAutoTags: value,
                ),
                title: const Text('Mostrar auto-tags'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.allowGroupingByCategory,
                onChanged: (value) => controller.updateVisualization(
                  allowGroupingByCategory: value,
                ),
                title: const Text('Agrupar por categoría'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.allowGroupingByKind,
                onChanged: (value) => controller.updateVisualization(
                  allowGroupingByKind: value,
                ),
                title: const Text('Agrupar por tipo'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.allowGroupingByHorizon,
                onChanged: (value) => controller.updateVisualization(
                  allowGroupingByHorizon: value,
                ),
                title: const Text('Agrupar por horizonte'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.allowGroupingByEnergy,
                onChanged: (value) => controller.updateVisualization(
                  allowGroupingByEnergy: value,
                ),
                title: const Text('Agrupar por energía'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
