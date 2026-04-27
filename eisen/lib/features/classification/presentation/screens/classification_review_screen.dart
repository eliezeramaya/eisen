import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/quick_capture_classification_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_preview_card.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/classification/presentation/widgets/rule_suggestion_card.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
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

    final lowConfidenceTasks = tasks
        .where((task) => task.classificationConfidence == ConfidenceLevel.low)
        .toList(growable: false);
    final uncategorizedTasks = tasks
        .where((task) => task.completedAt == null && task.categoryId == null)
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
                            '${correction.originalCategoryId ?? 'sin categoría'}'
                            ' → ${correction.correctedCategoryId ?? 'sin categoría'}',
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
