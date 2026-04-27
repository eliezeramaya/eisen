import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_correction_event.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/quadrant_learning_engine.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/quick_capture_classification_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_preview_card.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/classification/presentation/widgets/rule_suggestion_card.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationReviewScreen extends ConsumerStatefulWidget {
  const ClassificationReviewScreen({super.key});

  @override
  ConsumerState<ClassificationReviewScreen> createState() =>
      _ClassificationReviewScreenState();
}

class _ClassificationReviewScreenState
    extends ConsumerState<ClassificationReviewScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryConfigControllerProvider);
    final previewState =
        ref.watch(quickCaptureClassificationControllerProvider);
    final previewController = ref.read(
      quickCaptureClassificationControllerProvider.notifier,
    );
    final reviewState = ref.watch(classificationReviewControllerProvider);
    final reviewController =
        ref.read(classificationReviewControllerProvider.notifier);
    final tasks = ref.watch(matrixTasksProvider);
    final labelStyle = ref.watch(
      uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle),
    );

    final lowConfidenceTasks = tasks
        .where(
          (task) =>
              task.completedAt == null &&
              !task.isArchived &&
              task.classificationConfidence == ConfidenceLevel.low,
        )
        .toList(growable: false);
    final uncategorizedTasks = tasks
        .where(
          (task) =>
              task.completedAt == null &&
              !task.isArchived &&
              task.categoryId == null,
        )
        .toList(growable: false);
    final quadrantSuggestionTasks = tasks
        .where(
          (task) =>
              task.completedAt == null &&
              !task.isArchived &&
              task.classificationMetadata?.suggestedQuadrant != null &&
              task.classificationMetadata!.suggestedQuadrant != task.quadrant,
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Review'),
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
                  'Playground',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    labelText: 'Entrada libre',
                    hintText: 'Ej. pagar tarjeta el viernes',
                    suffixIcon: IconButton(
                      onPressed: previewState.isLoading
                          ? null
                          : () async {
                              previewController.setInput(_inputController.text);
                              await previewController.classifyNow();
                            },
                      icon: const Icon(Icons.auto_awesome),
                    ),
                  ),
                  onSubmitted: (_) async {
                    previewController.setInput(_inputController.text);
                    await previewController.classifyNow();
                  },
                ),
                if (previewState.preview != null) ...[
                  const SizedBox(height: 16),
                  ClassificationPreviewCard(
                    metadata: previewState.preview!,
                    categories: categories,
                    title: 'Preview',
                    subtitle: 'Corrige rápido si hace falta',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openReclassifySheet(
                        context: context,
                        categories: categories,
                      ),
                      icon: const Icon(Icons.tune),
                      label: const Text('Corregir'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Baja confianza',
            subtitle: 'Entradas que conviene revisar primero.',
            child: lowConfidenceTasks.isEmpty
                ? const Text('No hay tareas con confianza baja.')
                : Column(
                    children: [
                      for (final task in lowConfidenceTasks.take(8))
                        _TaskReviewTile(
                          task: task,
                          categories: categories,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Sin categoría',
            subtitle:
                'Tareas clasificadas que todavía no cayeron en una categoría.',
            child: uncategorizedTasks.isEmpty
                ? const Text('No hay tareas pendientes sin categoría.')
                : Column(
                    children: [
                      for (final task in uncategorizedTasks.take(8))
                        _TaskReviewTile(
                          task: task,
                          categories: categories,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Sugerencias de cuadrante',
            subtitle:
                'Revisa tareas donde la inferencia no coincide con el cuadrante actual.',
            child: quadrantSuggestionTasks.isEmpty
                ? const Text('No hay sugerencias de cuadrante pendientes.')
                : Column(
                    children: [
                      for (final task in quadrantSuggestionTasks.take(8))
                        _QuadrantSuggestionTile(
                          task: task,
                          labelStyle: labelStyle,
                          onApply: () => _applyQuadrantSuggestion(task),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Learning de pesos',
            subtitle:
                'Ajustes aprendidos desde correcciones de cuadrante del usuario.',
            child: _LearningProfileView(
              profile: reviewState.learningProfile,
              labelStyle: labelStyle,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Reglas sugeridas',
            subtitle: 'Detectadas por correcciones repetidas.',
            child: reviewState.suggestions.isEmpty
                ? const Text('Aún no hay sugerencias basadas en correcciones.')
                : Column(
                    children: [
                      for (final suggestion in reviewState.suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RuleSuggestionCard(
                            rule: suggestion,
                            onApply: () =>
                                reviewController.approveSuggestion(suggestion),
                            onDismiss: () => reviewController
                                .dismissSuggestion(suggestion.id),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Revisión reciente',
            subtitle: 'Últimas correcciones registradas.',
            child: reviewState.corrections.isEmpty
                ? const Text('Todavía no hay eventos de corrección.')
                : Column(
                    children: [
                      for (final correction
                          in reviewState.corrections.reversed.take(8))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(correction.rawText),
                          subtitle: Text(
                            _correctionSummary(correction, labelStyle),
                          ),
                          trailing: Text(
                              correction.correctedKind?.label ?? 'Sin tipo'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReclassifySheet({
    required BuildContext context,
    required List<CategoryConfig> categories,
  }) async {
    final previewController =
        ref.read(quickCaptureClassificationControllerProvider.notifier);
    final preview =
        ref.read(quickCaptureClassificationControllerProvider).preview;
    if (preview == null) return;

    final result = await showModalBottomSheet<QuickReclassifyResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickReclassifySheet(
        metadata: preview,
        categories: categories,
      ),
    );

    if (!mounted || result == null) return;
    previewController.applyOverride(result.metadata);
    if (result.rememberDecision) {
      await ref
          .read(classificationReviewControllerProvider.notifier)
          .recordCorrection(
            inputText: preview.inputText,
            original: preview,
            corrected: result.metadata,
          );
    }
    if (result.createRule) {
      await ref.read(classificationRulesControllerProvider.notifier).add(
            buildRuleFromReclassification(
              inputText: preview.inputText,
              corrected: result.metadata,
            ),
          );
    }
  }

  Future<void> _applyQuadrantSuggestion(Task task) async {
    final metadata = task.classificationMetadata;
    final suggested = metadata?.suggestedQuadrant;
    if (suggested == null) return;

    final matrixController = ref.read(matrixControllerProvider.notifier);
    final reviewController =
        ref.read(classificationReviewControllerProvider.notifier);

    if (metadata != null) {
      await reviewController.recordCorrection(
        inputText: task.title,
        original: metadata.copyWith(suggestedQuadrant: task.quadrant),
        corrected: metadata.copyWith(suggestedQuadrant: suggested),
        taskId: task.id,
        note: 'Cuadrante aplicado desde Review Center.',
      );
    }
    matrixController.moveTaskToQuadrant(task.id, suggested);

    if (!mounted) return;
    final label = getQuadrantLabel(
      suggested,
      ref.read(uiPrefsProvider).quadrantLabelStyle,
    ).title;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cuadrante actualizado a $label')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EisenCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _QuadrantSuggestionTile extends StatelessWidget {
  const _QuadrantSuggestionTile({
    required this.task,
    required this.labelStyle,
    required this.onApply,
  });

  final Task task;
  final QuadrantLabelStyle labelStyle;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final suggested = task.classificationMetadata!.suggestedQuadrant!;
    final currentLabel = getQuadrantLabel(task.quadrant, labelStyle).shortLabel;
    final suggestedLabel = getQuadrantLabel(suggested, labelStyle);
    final reason = task.classificationMetadata!.quadrantReason;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(task.title),
      subtitle: Text(
        '$currentLabel → ${suggestedLabel.title}'
        '${reason.isEmpty ? '' : ' · $reason'}',
      ),
      trailing: FilledButton.tonal(
        onPressed: onApply,
        child: const Text('Aplicar'),
      ),
    );
  }
}

class _LearningProfileView extends StatelessWidget {
  const _LearningProfileView({
    required this.profile,
    required this.labelStyle,
  });

  final QuadrantLearningProfile profile;
  final QuadrantLabelStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    if (!profile.hasSignals) {
      return const Text('Aún no hay suficientes correcciones de cuadrante.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final quadrant in Quadrant.values)
          Chip(
            label: Text(
              '${getQuadrantLabel(quadrant, labelStyle).shortLabel} '
              'x${profile.factorFor(quadrant).toStringAsFixed(2)}',
            ),
          ),
      ],
    );
  }
}

class _TaskReviewTile extends StatelessWidget {
  const _TaskReviewTile({
    required this.task,
    required this.categories,
  });

  final Task task;
  final List<CategoryConfig> categories;

  @override
  Widget build(BuildContext context) {
    String categoryName = 'Sin categoría';
    for (final category in categories) {
      if (category.id == task.categoryId) {
        categoryName = category.name;
        break;
      }
    }

    final confidence = task.classificationConfidence?.label ?? 'Sin señal';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(task.title),
      subtitle: Text(
        '$categoryName · ${task.kind.label} · ${task.horizon?.label ?? 'Sin horizonte'}',
      ),
      trailing: Text(confidence),
    );
  }
}

String _correctionSummary(
  ClassificationCorrectionEvent correction,
  QuadrantLabelStyle labelStyle,
) {
  final category =
      '${correction.originalCategoryId ?? 'sin categoría'} → ${correction.correctedCategoryId ?? 'sin categoría'}';
  final originalQuadrant = correction.originalQuadrant;
  final correctedQuadrant = correction.correctedQuadrant;
  if (originalQuadrant == null && correctedQuadrant == null) return category;

  final originalLabel = originalQuadrant == null
      ? 'sin cuadrante'
      : getQuadrantLabel(originalQuadrant, labelStyle).shortLabel;
  final correctedLabel = correctedQuadrant == null
      ? 'sin cuadrante'
      : getQuadrantLabel(correctedQuadrant, labelStyle).shortLabel;
  return '$category · $originalLabel → $correctedLabel';
}
