import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/vocabulary_aliases_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LearningSection extends ConsumerWidget {
  const LearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(classificationSettingsControllerProvider);
    final settingsController =
        ref.read(classificationSettingsControllerProvider.notifier);
    final review = ref.watch(classificationReviewControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Learning',
          subtitle:
              'Controla cómo aprende Eisen de correcciones, vocabulario y patrones repetidos.',
        ),
        EisenCard(
          outlined: true,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.learnFromCorrections,
                onChanged: (value) => settingsController.updateLearning(
                  learnFromCorrections: value,
                ),
                title: const Text('Aprender de mis correcciones'),
                subtitle: const Text(
                  'Registra ajustes manuales como señales de aprendizaje.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.suggestRules,
                onChanged: (value) => settingsController.updateLearning(
                  suggestRules: value,
                ),
                title: const Text('Sugerir reglas nuevas'),
                subtitle: Text(
                  '${review.suggestions.length} sugerencias detectadas ahora mismo.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.useVocabularyAliases,
                onChanged: (value) => settingsController.updateLearning(
                  useVocabularyAliases: value,
                ),
                title: const Text('Usar vocabulario personal'),
                subtitle: const Text(
                  'Aplica aliases como cliente, obra, luum, timmr o super.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.detectHabits,
                onChanged: (value) => settingsController.updateLearning(
                  detectHabits: value,
                ),
                title: const Text('Detectar hábitos desde repeticiones'),
                subtitle: Text(
                  '${review.corrections.length} correcciones acumuladas para aprendizaje.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const VocabularyAliasesSection(embedded: true),
      ],
    );
  }
}
