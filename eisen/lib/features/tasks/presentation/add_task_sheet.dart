import 'dart:async';

import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/quick_capture_classification_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_preview_card.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  Quadrant _quadrant = Quadrant.q2;
  Timer? _classifyDebounce;

  @override
  void dispose() {
    _classifyDebounce?.cancel();
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final previewState =
        ref.watch(quickCaptureClassificationControllerProvider);
    final categories = ref.watch(categoryConfigControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Describe la tarea',
                ),
                textInputAction: TextInputAction.done,
                onChanged: _handleTitleChanged,
                onSubmitted: (_) => _save(),
              ),
              if (previewState.isLoading && previewState.preview == null) ...[                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Analizando entrada…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (previewState.preview != null) ...[
                const SizedBox(height: 12),
                ClassificationPreviewCard(
                  metadata: previewState.preview!,
                  categories: categories,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: previewState.isLoading
                          ? null
                          : () => _classifyNow(_titleCtrl.text),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Reclasificar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: previewState.preview == null
                          ? null
                          : () => _openQuickCorrection(
                                previewState.preview!,
                                categories,
                              ),
                      icon: const Icon(Icons.tune),
                      label: const Text('Corregir'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Cuadrante:'),
                  const SizedBox(width: 12),
                  SegmentedButton<Quadrant>(
                    segments: [
                      for (final q in Quadrant.values)
                        ButtonSegment(
                            value: q, label: Text(q.name.toUpperCase())),
                    ],
                    selected: {_quadrant},
                    onSelectionChanged: (s) =>
                        setState(() => _quadrant = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Categoría (opcional)'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Guardar'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTitleChanged(String value) {
    ref
        .read(quickCaptureClassificationControllerProvider.notifier)
        .setInput(value);
    _classifyDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _classifyDebounce = Timer(
      const Duration(milliseconds: 260),
      () => _classifyNow(trimmed),
    );
  }

  Future<void> _classifyNow(String input) async {
    if (input.trim().isEmpty) return;
    await ref
        .read(quickCaptureClassificationControllerProvider.notifier)
        .classifyNow();
    if (!mounted) return;
    final preview =
        ref.read(quickCaptureClassificationControllerProvider).preview;
    if (preview?.categoryId != null && _categoryCtrl.text.trim().isEmpty) {
      final categories = ref.read(categoryConfigControllerProvider);
      CategoryConfig? category;
      for (final item in categories) {
        if (item.id == preview?.categoryId) {
          category = item;
          break;
        }
      }
      if (category != null) {
        _categoryCtrl.text = category.name;
      }
    }
  }

  Future<void> _openQuickCorrection(
    ClassificationMetadata metadata,
    List<CategoryConfig> categories,
  ) async {
    final result = await showModalBottomSheet<QuickReclassifyResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickReclassifySheet(
        metadata: metadata,
        categories: categories,
      ),
    );
    if (!mounted || result == null) return;
    await ref
        .read(quickCaptureClassificationControllerProvider.notifier)
        .applyUserCorrection(
          original: metadata,
          corrected: result.metadata,
          rememberDecision: true,
        );
    if (result.createRule) {
      await ref.read(classificationRulesControllerProvider.notifier).add(
            buildRuleFromReclassification(
              inputText: metadata.inputText,
              corrected: result.metadata,
            ),
          );
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final cat = _categoryCtrl.text.trim();

    _classifyDebounce?.cancel();
    final quickController =
        ref.read(quickCaptureClassificationControllerProvider.notifier);

    final id = await quickController.persistTaskWithClassification(
      rawText: title,
      quadrant: _quadrant,
      manualCategoryLabel: cat.isEmpty ? null : cat,
    );
    final preview =
        ref.read(quickCaptureClassificationControllerProvider).preview;
    final categories = ref.read(categoryConfigControllerProvider);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final hostContext = messenger.context;
    final container = ProviderScope.containerOf(context, listen: false);
    navigator.pop();
    _showPostSaveFeedback(
      messenger: messenger,
      // The context belongs to the parent ScaffoldMessenger, not this sheet.
      // ignore: use_build_context_synchronously
      hostContext: hostContext,
      container: container,
      taskId: id,
      metadata: preview,
      categories: categories,
    );
  }

  void _showPostSaveFeedback({
    required ScaffoldMessengerState messenger,
    required BuildContext hostContext,
    required ProviderContainer container,
    required String taskId,
    required ClassificationMetadata? metadata,
    required List<CategoryConfig> categories,
  }) {
    final feedback = _classificationFeedback(metadata, categories);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(feedback),
        action: metadata == null
            ? null
            : SnackBarAction(
                label: 'Corregir',
                onPressed: () => _correctSavedTask(
                  hostContext: hostContext,
                  container: container,
                  taskId: taskId,
                  original: metadata,
                ),
              ),
      ),
    );
  }

  String _classificationFeedback(
    ClassificationMetadata? metadata,
    List<CategoryConfig> categories,
  ) {
    if (metadata == null) return 'Tarea agregada';

    String? categoryName;
    for (final category in categories) {
      if (category.id == metadata.categoryId) {
        categoryName = category.name;
        break;
      }
    }
    final categoryPart = categoryName ?? 'sin categoría';
    return 'Tarea agregada · $categoryPart · ${metadata.entryKind.label}';
  }

  Future<void> _correctSavedTask({
    required BuildContext hostContext,
    required ProviderContainer container,
    required String taskId,
    required ClassificationMetadata original,
  }) async {
    final categories = container.read(categoryConfigControllerProvider);
    final result = await showModalBottomSheet<QuickReclassifyResult>(
      context: hostContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickReclassifySheet(
        metadata: original,
        categories: categories,
      ),
    );
    if (result == null) return;

    final corrected = result.metadata;
    container.read(matrixControllerProvider.notifier).updateTask(
          taskId,
          (task) => applyClassificationToTask(
            task: task,
            metadata: corrected,
            categories: container.read(categoryConfigControllerProvider),
          ),
        );
    await container
        .read(classificationReviewControllerProvider.notifier)
        .recordCorrection(
          inputText: original.inputText,
          original: original,
          corrected: corrected,
        );
    if (result.createRule) {
      await container.read(classificationRulesControllerProvider.notifier).add(
            buildRuleFromReclassification(
              inputText: original.inputText,
              corrected: corrected,
            ),
          );
    }
    if (!hostContext.mounted) return;
    ScaffoldMessenger.of(hostContext).showSnackBar(
      const SnackBar(content: Text('Clasificación corregida')),
    );
  }
}
