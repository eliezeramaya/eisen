import 'dart:async';

import 'package:eisen/core/observability/observability_provider.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/atlas/application/atlas_export_filename.dart';
import 'package:eisen/features/atlas/application/atlas_export_service.dart';
import 'package:eisen/features/atlas/application/atlas_export_write_result.dart';
import 'package:eisen/features/atlas/application/atlas_export_writer.dart';
import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/application/atlas_zoom_controller.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_data.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_summary.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:eisen/features/atlas/presentation/screens/atlas_print_preview_screen.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_breadcrumb.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_canvas.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_detail_panel.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_export_frame.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_insights_strip.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_legend.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_toolbar.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_review_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/quick_reclassify_sheet.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/task_editor_page.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});

  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  final GlobalKey _atlasExportBoundaryKey = GlobalKey(
    debugLabel: 'atlas-export-boundary',
  );
  bool _isExportingAtlas = false;
  DateTime? _exportStartedAt;
  bool _isExportingPdf = false;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(atlasVisibleNodesProvider);
    final focusedIds = ref.watch(atlasFocusedTaskIdsProvider);
    final insightTaskIds = ref.watch(atlasInsightTaskIdsProvider);
    final insights = ref.watch(atlasInsightsProvider);
    final grouping = ref.watch(atlasGroupingProvider);
    final selectedTask = ref.watch(atlasSelectedTaskProvider);
    final labelStyle = ref.watch(
      uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle),
    );
    final allTasks = ref.watch(matrixTasksProvider);
    final atlasTasks = ref.watch(atlasTasksProvider);
    final hasFilters = ref.watch(atlasHasActiveFiltersProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final path = ref.watch(atlasResolvedDrilldownPathProvider);
    final zoomState = ref.watch(atlasZoomProvider);
    final width = MediaQuery.sizeOf(context).width;
    final config = atlasResponsiveConfigForWidth(width);
    final deviceClass = deviceClassOf(width);
    final showDetailPanel = config.enableSidePanel && deviceClass.isExpandedUp;
    final emptyKind = _emptyKind(
      allTasks: allTasks,
      atlasTasks: atlasTasks,
      hasFilters: hasFilters,
    );

    Future<void> openEdit(Task task) async {
      ref.read(matrixControllerProvider.notifier).select(task.id);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskEditorPage(task: task),
        ),
      );
    }

    Future<void> openReclassify(Task task) async {
      final categories = ref.read(categoryConfigControllerProvider);
      final original = _classificationMetadataForTask(task);
      final result = await showModalBottomSheet<QuickReclassifyResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => QuickReclassifySheet(
          metadata: original,
          categories: categories,
        ),
      );
      if (result == null) return;

      final corrected = result.metadata;
      Task? updatedTask;
      ref.read(matrixControllerProvider.notifier).updateTask(
        task.id,
        (current) {
          final classified = applyClassificationToTask(
            task: current,
            metadata: corrected,
            categories: ref.read(categoryConfigControllerProvider),
          );
          updatedTask = corrected.suggestedQuadrant == null
              ? classified
              : classified.copyWith(quadrant: corrected.suggestedQuadrant);
          return updatedTask!;
        },
      );
      if (updatedTask != null) {
        ref.read(atlasSelectedTaskIdProvider.notifier).select(updatedTask!.id);
      }

      await ref
          .read(classificationReviewControllerProvider.notifier)
          .recordCorrection(
            taskId: task.id,
            inputText: original.inputText,
            original: original,
            corrected: corrected,
          );
      if (result.createRule) {
        await ref.read(classificationRulesControllerProvider.notifier).add(
              buildRuleFromReclassification(
                inputText: original.inputText,
                corrected: corrected,
              ),
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clasificación corregida')),
      );
    }

    Task? taskForInsight(AtlasInsight insight) {
      final taskId = insight.primaryTaskId;
      if (taskId == null) return null;
      for (final candidate in atlasTasks) {
        if (candidate.id == taskId) return candidate;
      }
      return null;
    }

    void showAtlasFeedback(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    Future<void> exportAtlasPng() async {
      if (_isExportingAtlas) return;
      final startedAt = DateTime.now();
      setState(() {
        _isExportingAtlas = true;
        _exportStartedAt = startedAt;
      });

      try {
        await WidgetsBinding.instance.endOfFrame;
        final bytes = await const AtlasExportService().exportBoundaryToPng(
          repaintBoundaryKey: _atlasExportBoundaryKey,
          pixelRatio: AtlasExportPixelRatio.standard,
        );
        final filename = atlasExportFilename(date: startedAt);
        final result = await const AtlasExportWriter().writePng(
          bytes: bytes,
          filename: filename,
        );
        showAtlasFeedback(_atlasExportSuccessMessage(result));
      } on AtlasExportException catch (error) {
        final context = _atlasExportErrorContext(
          grouping: grouping,
          visibleTaskCount: atlasTasks.length,
          nodeCount: nodes.length,
          hasFilters: hasFilters,
          showArchived: showArchived,
          pixelRatio: AtlasExportPixelRatio.standard,
        );
        await ref.read(errorReporterProvider).captureMessage(
              'Atlas export failed: ${error.message}',
              context: context,
            );
        showAtlasFeedback(error.message);
      } on AtlasExportWriteException catch (error) {
        final context = _atlasExportErrorContext(
          grouping: grouping,
          visibleTaskCount: atlasTasks.length,
          nodeCount: nodes.length,
          hasFilters: hasFilters,
          showArchived: showArchived,
          pixelRatio: AtlasExportPixelRatio.standard,
        );
        await ref.read(errorReporterProvider).captureMessage(
              'Atlas export write failed: ${error.message}',
              context: context,
            );
        showAtlasFeedback(error.message);
      } catch (error, stackTrace) {
        final context = _atlasExportErrorContext(
          grouping: grouping,
          visibleTaskCount: atlasTasks.length,
          nodeCount: nodes.length,
          hasFilters: hasFilters,
          showArchived: showArchived,
          pixelRatio: AtlasExportPixelRatio.standard,
        );
        await ref.read(errorReporterProvider).captureException(
              error,
              stackTrace,
              context: context,
            );
        showAtlasFeedback(
          'No se pudo exportar Atlas. Intenta de nuevo cuando el mapa termine de cargar.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isExportingAtlas = false;
            _exportStartedAt = null;
          });
        }
      }
    }

    Future<void> exportAtlasPdf() async {
      if (_isExportingPdf) return;
      setState(() => _isExportingPdf = true);
      try {
        await WidgetsBinding.instance.endOfFrame;
        final bytes = await const AtlasExportService().exportBoundaryToPng(
          repaintBoundaryKey: _atlasExportBoundaryKey,
          pixelRatio: AtlasExportPixelRatio.standard,
        );
        final now = DateTime.now();
        final summaryQ = atlasSummaryByQuadrant(atlasTasks);
        final summaryC = atlasSummaryByCategory(atlasTasks);
        final pdfInsights = atlasPdfInsights(
          summaryByQuadrant: summaryQ,
          summaryByCategory: summaryC,
          visibleTaskCount: atlasTasks.length,
        );
        final data = AtlasPdfData(
          generatedAt: now,
          groupingLabel: grouping.label,
          visibleTaskCount: atlasTasks.length,
          totalTaskCount: allTasks.length,
          tasks: atlasTasks,
          atlasImageBytes: bytes,
          activeFiltersLabel: hasFilters
              ? _atlasExportFilterLabel(
                  hasFilters: hasFilters,
                  showArchived: showArchived,
                )
              : null,
          insights: pdfInsights,
          summaryByQuadrant: summaryQ,
          summaryByCategory: summaryC,
        );
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AtlasPrintPreviewScreen(
              data: data,
              initialOptions: const AtlasPdfOptions(),
            ),
          ),
        );
      } on AtlasExportException catch (error) {
        await ref.read(errorReporterProvider).captureMessage(
              'Atlas PDF export capture failed: ${error.message}',
            );
        if (context.mounted) {
          showAtlasFeedback(
            'No se pudo capturar Atlas. Intenta cuando el mapa termine de cargar.',
          );
        }
      } catch (error, stackTrace) {
        await ref.read(errorReporterProvider).captureException(
              error,
              stackTrace,
            );
        if (context.mounted) {
          showAtlasFeedback(
            'No se pudo exportar Atlas como PDF. Intenta de nuevo.',
          );
        }
      } finally {
        if (mounted) setState(() => _isExportingPdf = false);
      }
    }


    void selectTask(Task task) {
      ref.read(atlasSelectedTaskIdProvider.notifier).select(task.id);
      ref.read(matrixControllerProvider.notifier).select(task.id);
      if (!showDetailPanel) {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.66,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  final liveTask = ref.watch(atlasSelectedTaskProvider);
                  return AtlasDetailPanel(
                    task: liveTask ?? task,
                    labelStyle: labelStyle,
                    onComplete: () {
                      ref
                          .read(matrixControllerProvider.notifier)
                          .markTaskDone(task.id);
                      Navigator.of(context).pop();
                    },
                    onEdit: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => openEdit(task),
                      );
                    },
                    onReclassify: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => openReclassify(task),
                      );
                    },
                    onArchive: () {
                      ref
                          .read(matrixControllerProvider.notifier)
                          .archiveTask(task.id);
                      Navigator.of(context).pop();
                    },
                    onRestore: () {
                      ref
                          .read(matrixControllerProvider.notifier)
                          .restoreTask(task.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    Future<void> handleInsightAction(
      AtlasInsight insight,
      AtlasInsightAction action,
    ) async {
      final task = taskForInsight(insight);
      switch (action.kind) {
        case AtlasInsightActionKind.openPrimaryTask:
          if (task != null) selectTask(task);
          break;
        case AtlasInsightActionKind.editPrimaryTask:
          if (task == null) return;
          selectTask(task);
          await openEdit(task);
          break;
        case AtlasInsightActionKind.reclassifyPrimaryTask:
          if (task == null) return;
          selectTask(task);
          await openReclassify(task);
          break;
        case AtlasInsightActionKind.filterLowConfidence:
          await ref
              .read(activeConfidenceFiltersProvider.notifier)
              .update(const [ConfidenceLevel.low]);
          showAtlasFeedback('Mostrando tareas con baja confianza');
          break;
        case AtlasInsightActionKind.groupByQuadrant:
          ref
              .read(atlasGroupingProvider.notifier)
              .update(AtlasGrouping.quadrant);
          ref.read(atlasDrilldownPathProvider.notifier).clear();
          ref.read(atlasZoomProvider.notifier).reset();
          showAtlasFeedback('Atlas agrupado por cuadrante');
          break;
      }
    }

    void showQuickActions(Task task) {
      void close() => Navigator.of(context).pop();

      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Ver detalle'),
                onTap: () {
                  close();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => selectTask(task),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Completar'),
                onTap: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .markTaskDone(task.id);
                  close();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  close();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => openEdit(task),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Reclasificar'),
                onTap: () {
                  close();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => openReclassify(task),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_with),
                title: const Text('Mover cuadrante'),
                onTap: () {
                  close();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _showMoveQuadrantSheet(
                      context: context,
                      ref: ref,
                      task: task,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  task.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                title: Text(task.isArchived ? 'Restaurar' : 'Archivar'),
                onTap: () {
                  if (task.isArchived) {
                    ref
                        .read(matrixControllerProvider.notifier)
                        .restoreTask(task.id);
                  } else {
                    ref
                        .read(matrixControllerProvider.notifier)
                        .archiveTask(task.id);
                  }
                  close();
                },
              ),
            ],
          ),
        ),
      );
    }

    final canvas = RepaintBoundary(
      key: _atlasExportBoundaryKey,
      child: AtlasExportFrame(
        includeHeader: _isExportingAtlas,
        title: 'Atlas',
        subtitle: 'Reporte visual de tareas',
        date: _exportStartedAt,
        groupingLabel: grouping.label,
        filtersLabel: _atlasExportFilterLabel(
          hasFilters: hasFilters,
          showArchived: showArchived,
        ),
        visibleTaskCount: atlasTasks.length,
        insights: _exportInsightLabels(insights),
        footerLabel: 'Eisen',
        child: AtlasCanvas(
          nodes: nodes,
          focusedTaskIds: focusedIds,
          insightTaskIds: insightTaskIds,
          selectedTaskId: selectedTask?.id,
          emptyStateKind: emptyKind,
          onTaskSelected: selectTask,
          onTaskLongPress: showQuickActions,
          zoomState: zoomState,
          onZoomChanged: (scale, offset) {
            ref.read(atlasZoomProvider.notifier).updateFromTransform(
                  scale: scale,
                  offset: offset,
                );
          },
          onZoomIn: () => ref.read(atlasZoomProvider.notifier).zoomIn(),
          onZoomOut: () => ref.read(atlasZoomProvider.notifier).zoomOut(),
          onZoomReset: () => ref.read(atlasZoomProvider.notifier).reset(),
          exportMode: _isExportingAtlas,
          onGroupTap: (node) {
            ref.read(atlasZoomProvider.notifier).focusGroup(node.id);
            ref.read(atlasDrilldownPathProvider.notifier).enter(node);
          },
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtlasToolbar(
          config: config,
          isExporting: _isExportingAtlas,
          onExportPng: () => unawaited(exportAtlasPng()),
          isExportingPdf: _isExportingPdf,
          onExportPdf: () => unawaited(exportAtlasPdf()),
        ),
        AtlasInsightsStrip(
          insights: insights,
          compact: deviceClass.isCompact,
          onInsightSelected: (insight) {
            final task = taskForInsight(insight);
            if (task != null) selectTask(task);
          },
          onActionSelected: (insight, action) {
            unawaited(handleInsightAction(insight, action));
          },
        ),
        AtlasLegend(config: config, labelStyle: labelStyle),
        AtlasBreadcrumb(
          path: path,
          onRoot: () {
            ref.read(atlasZoomProvider.notifier).focusGroup(null);
            ref.read(atlasDrilldownPathProvider.notifier).clear();
          },
          onSelect: (index) {
            if (index < 0) {
              ref.read(atlasZoomProvider.notifier).focusGroup(null);
            }
            ref.read(atlasDrilldownPathProvider.notifier).jumpTo(index);
          },
        ),
        Expanded(
          child: showDetailPanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: canvas),
                    if (selectedTask != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: deviceClass.isLarge ? 340 : 300,
                        child: AtlasDetailPanel(
                          task: selectedTask,
                          labelStyle: labelStyle,
                          onClose: () {
                            ref
                                .read(atlasSelectedTaskIdProvider.notifier)
                                .select(null);
                          },
                          onComplete: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .markTaskDone(selectedTask.id);
                          },
                          onEdit: () => openEdit(selectedTask),
                          onReclassify: () => openReclassify(selectedTask),
                          onArchive: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .archiveTask(selectedTask.id);
                          },
                          onRestore: () {
                            ref
                                .read(matrixControllerProvider.notifier)
                                .restoreTask(selectedTask.id);
                          },
                        ),
                      ),
                    ],
                  ],
                )
              : canvas,
        ),
      ],
    );
  }

  void _showMoveQuadrantSheet({
    required BuildContext context,
    required WidgetRef ref,
    required Task task,
  }) {
    final labelStyle = ref.read(uiPrefsProvider).quadrantLabelStyle;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final quadrant in Quadrant.values)
              ListTile(
                leading: Icon(
                  task.quadrant == quadrant
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(getQuadrantLabel(quadrant, labelStyle).title),
                onTap: () {
                  ref
                      .read(matrixControllerProvider.notifier)
                      .moveTaskToQuadrant(task.id, quadrant);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  AtlasEmptyStateKind _emptyKind({
    required List<Task> allTasks,
    required List<Task> atlasTasks,
    required bool hasFilters,
  }) {
    if (atlasTasks.isNotEmpty) return AtlasEmptyStateKind.noTasks;
    if (hasFilters) return AtlasEmptyStateKind.filters;
    if (allTasks.isEmpty) return AtlasEmptyStateKind.noTasks;
    return AtlasEmptyStateKind.noActiveTasks;
  }

  ClassificationMetadata _classificationMetadataForTask(Task task) {
    final existing = task.classificationMetadata;
    if (existing != null) {
      return existing.copyWith(
        inputText: existing.inputText.isEmpty ? task.title : existing.inputText,
        normalizedText: existing.normalizedText.isEmpty
            ? task.title.trim().toLowerCase()
            : existing.normalizedText,
        suggestedQuadrant: existing.suggestedQuadrant ?? task.quadrant,
      );
    }

    return ClassificationMetadata(
      inputText: task.title,
      normalizedText: task.title.trim().toLowerCase(),
      categoryId: task.categoryId,
      entryKind: task.kind,
      timeHorizon: task.horizon ?? TimeHorizon.someday,
      energyLevel: task.energy ?? EnergyLevel.medium,
      priorityLevel: _priorityLevelForTask(task),
      confidenceScore: switch (task.classificationConfidence) {
        ConfidenceLevel.high => 0.86,
        ConfidenceLevel.medium => 0.62,
        ConfidenceLevel.low => 0.38,
        null => 0.45,
      },
      confidenceLevel: task.classificationConfidence ?? ConfidenceLevel.medium,
      matchedKeywords: [
        for (final tag in [...task.tags, ...task.autoTags])
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      suggestedQuadrant: task.quadrant,
      quadrantReason: 'Reclasificación iniciada desde Atlas.',
    );
  }

  PriorityLevel _priorityLevelForTask(Task task) {
    if (task.inferredPriority != null) return task.inferredPriority!;
    if (task.priority >= 9) return PriorityLevel.critical;
    if (task.priority >= 7) return PriorityLevel.high;
    if (task.priority >= 4) return PriorityLevel.medium;
    return PriorityLevel.low;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _atlasExportSuccessMessage(AtlasExportWriteResult result) {
    final size = _formatBytes(result.bytes);
    if (result.downloaded) {
      return '${result.filename} descargado ($size)';
    }
    final path = result.filePath;
    if (path != null && path.isNotEmpty) {
      return '${result.filename} guardado en $path ($size)';
    }
    return '${result.filename} generado ($size)';
  }

  String _atlasExportFilterLabel({
    required bool hasFilters,
    required bool showArchived,
  }) {
    if (hasFilters && showArchived) return 'Activos + archivadas';
    if (hasFilters) return 'Activos';
    if (showArchived) return 'Sin filtros + archivadas';
    return 'Sin filtros';
  }

  List<String> _exportInsightLabels(List<AtlasInsight> insights) {
    return [
      for (final insight in insights.take(3))
        if (insight.title.trim().isNotEmpty) insight.title.trim(),
    ];
  }

  Map<String, dynamic> _atlasExportErrorContext({
    required AtlasGrouping grouping,
    required int visibleTaskCount,
    required int nodeCount,
    required bool hasFilters,
    required bool showArchived,
    required double pixelRatio,
  }) {
    return <String, dynamic>{
      'feature': 'atlas_export',
      'grouping': grouping.name,
      'visible_task_count': visibleTaskCount,
      'root_node_count': nodeCount,
      'has_filters': hasFilters,
      'show_archived': showArchived,
      'pixel_ratio': pixelRatio,
      'include_header': true,
    };
  }
}
