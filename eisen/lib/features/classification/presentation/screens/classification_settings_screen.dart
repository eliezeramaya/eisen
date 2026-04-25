import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/quick_capture_classification_controller.dart';
import 'package:eisen/features/classification/presentation/screens/classification_review_screen.dart';
import 'package:eisen/features/classification/presentation/widgets/automation_mode_section.dart';
import 'package:eisen/features/classification/presentation/widgets/category_management_section.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_preview_card.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_rules_section.dart';
import 'package:eisen/features/classification/presentation/widgets/learning_section.dart';
import 'package:eisen/features/classification/presentation/widgets/visualization_behavior_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationSettingsScreen extends ConsumerStatefulWidget {
  const ClassificationSettingsScreen({super.key});

  @override
  ConsumerState<ClassificationSettingsScreen> createState() =>
      _ClassificationSettingsScreenState();
}

class _ClassificationSettingsScreenState
    extends ConsumerState<ClassificationSettingsScreen> {
  final _previewController = TextEditingController(
    text: 'terminar renders del cliente',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(quickCaptureClassificationControllerProvider.notifier)
          .setInput(_previewController.text);
      ref
          .read(quickCaptureClassificationControllerProvider.notifier)
          .classifyNow();
    });
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryConfigControllerProvider);
    final previewState =
        ref.watch(quickCaptureClassificationControllerProvider);
    final previewCtrl =
        ref.read(quickCaptureClassificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Classification'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ClassificationReviewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EisenCard(
            outlined: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Classification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configura cómo Eisen interpreta entradas libres, aprende de correcciones y usa esa lógica para filtros, chips y agrupaciones.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('Captura libre')),
                    Chip(label: Text('Aprendizaje')),
                    Chip(label: Text('Filtros')),
                    Chip(label: Text('Visualización')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AutomationModeSection(),
          const SizedBox(height: 16),
          const CategoryManagementSection(),
          const SizedBox(height: 16),
          const ClassificationRulesSection(),
          const SizedBox(height: 16),
          const LearningSection(),
          const SizedBox(height: 16),
          const VisualizationBehaviorSection(),
          const SizedBox(height: 16),
          EisenCard(
            outlined: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview live card',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Prueba una entrada real para que la configuración no se sienta abstracta.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _previewController,
                  decoration: InputDecoration(
                    labelText: 'Entrada de ejemplo',
                    hintText: 'terminar renders del cliente',
                    suffixIcon: IconButton(
                      onPressed: previewState.isLoading
                          ? null
                          : () async {
                              previewCtrl.setInput(_previewController.text);
                              await previewCtrl.classifyNow();
                            },
                      icon: const Icon(Icons.auto_awesome),
                    ),
                  ),
                  onChanged: previewCtrl.setInput,
                  onSubmitted: (_) async {
                    await previewCtrl.classifyNow();
                  },
                ),
                const SizedBox(height: 14),
                if (previewState.preview != null)
                  ClassificationPreviewCard(
                    metadata: previewState.preview!,
                    categories: categories,
                    title: 'Resultado esperado',
                    subtitle: 'Tipo, categoría, horizonte, energía y confianza',
                  )
                else
                  const Text('Escribe una entrada y genera el preview.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
