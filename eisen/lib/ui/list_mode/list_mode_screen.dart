import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_settings.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/classification/presentation/category_color_service_factory.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:eisen/features/classification/presentation/widgets/classification_grouping_bar.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/filters/presentation/widgets/category_filters_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modern list mode screen showing tasks as horizontal bars with visual weight
class ListModeScreen extends ConsumerWidget {
  const ListModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(visibleMatrixTasksProvider);
    final settings = ref.watch(classificationSettingsControllerProvider);
    final categories = ref.watch(categoryConfigControllerProvider);
    final categoryColorService = buildClassificationCategoryColorService(
      categories: categories,
    );

    // Group tasks by quadrant
    final quadrants = <Quadrant, List<Task>>{};
    for (final task in tasks) {
      if (task.completedAt == null) {
        quadrants.putIfAbsent(task.quadrant, () => []).add(task);
      }
    }

    // Sort tasks within each quadrant by weight (descending)
    for (final q in quadrants.keys) {
      quadrants[q]!.sort((a, b) {
        final weightA = _calculateWeight(a);
        final weightB = _calculateWeight(b);
        return weightB.compareTo(weightA);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE6E6E6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'List Mode',
          style: TextStyle(
            color: Color(0xFFE6E6E6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF7C7C7C)),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  child: SizedBox(
                    width: 640,
                    child: CategoryFiltersBar(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? _buildEmptyState()
          : _buildResponsiveLayout(
              context,
              quadrants,
              ref,
              categoryColorService: categoryColorService,
              settings: settings,
              categories: categories,
            ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    Map<Quadrant, List<Task>> quadrants,
    WidgetRef ref, {
    required CategoryColorService categoryColorService,
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
  }) {
    // Unificar todas las tareas en una sola lista
    final allTasks = <Task>[];

    // Agregar todas las tareas de todos los cuadrantes
    allTasks.addAll(quadrants[Quadrant.q1] ?? []);
    allTasks.addAll(quadrants[Quadrant.q2] ?? []);
    allTasks.addAll(quadrants[Quadrant.q3] ?? []);
    allTasks.addAll(quadrants[Quadrant.q4] ?? []);

    // Ordenar todas las tareas por peso (mayor a menor)
    allTasks.sort((a, b) {
      final weightA = _calculateWeight(a);
      final weightB = _calculateWeight(b);
      return weightB.compareTo(weightA);
    });

    // Calcular peso máximo para normalización
    final maxWeight = allTasks.isEmpty
        ? 1.0
        : allTasks
            .map(_calculateWeight)
            .fold<double>(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CategoryFiltersBar(
            padding: EdgeInsets.only(bottom: 20),
          ),
          ClassificationGroupingBar(
            tasks: allTasks,
            categories: categories,
            settings: settings,
            padding: const EdgeInsets.only(bottom: 16),
          ),
          // Header con contador de tareas
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                const Text(
                  'Todas las tareas',
                  style: TextStyle(
                    color: Color(0xFFE6E6E6),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allTasks.length}',
                    style: const TextStyle(
                      color: Color(0xFF7C7C7C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Ordenadas por importancia y urgencia',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          ..._buildGroupedTaskBars(
            allTasks: allTasks,
            maxWeight: maxWeight,
            ref: ref,
            settings: settings,
            categories: categories,
            categoryColorService: categoryColorService,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _getQuadrantColor(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return const Color(0xFFE84545); // Rojo - Urgente e Importante
      case Quadrant.q2:
        return const Color(0xFFF4996E); // Naranja - No Urgente e Importante
      case Quadrant.q3:
        return const Color(0xFF2563EB); // Azul - Urgente y No Importante
      case Quadrant.q4:
        return const Color(0xFFA3A3A3); // Gris - Ni Urgente ni Importante
    }
  }

  List<Widget> _buildGroupedTaskBars({
    required List<Task> allTasks,
    required double maxWeight,
    required WidgetRef ref,
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
    required CategoryColorService categoryColorService,
  }) {
    final grouped = _groupTasksForList(
      allTasks,
      settings: settings,
      categories: categories,
    );
    var animationIndex = 0;
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      if (grouped.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              '${entry.key} · ${entry.value.length}',
              style: const TextStyle(
                color: Color(0xFFA3A3A3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      }

      for (final task in entry.value) {
        final weight = _calculateWeight(task);
        final fallbackColor = _getQuadrantColor(task.quadrant);
        final category = categoryForTask(categories, task);
        final color = settings.colorByCategory && category != null
            ? categoryColorService.getColorForCategory(category.name)
            : fallbackColor;
        final index = animationIndex++;

        widgets.add(
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 30)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: _buildTaskBar(
              task: task,
              color: color,
              weight: weight,
              maxWeight: maxWeight,
              onTap: () => _handleTaskTap(ref, task),
              settings: settings,
              categories: categories,
              categoryColorService: categoryColorService,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Map<String, List<Task>> _groupTasksForList(
    List<Task> tasks, {
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
  }) {
    String Function(Task task)? labelFor;
    if (settings.allowGroupingByCategory) {
      labelFor = (task) =>
          categoryForTask(categories, task)?.name ??
          task.category ??
          'Sin categoría';
    } else if (settings.allowGroupingByKind) {
      labelFor = (task) => task.kind.label;
    } else if (settings.allowGroupingByHorizon) {
      labelFor = (task) => task.horizon?.label ?? 'Sin horizonte';
    } else if (settings.allowGroupingByEnergy) {
      labelFor = (task) => task.energy?.label ?? 'Sin energía';
    }

    if (labelFor == null) return {'Todas': tasks};
    final grouped = <String, List<Task>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(labelFor(task), () => <Task>[]).add(task);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
  }

  Widget _buildTaskBar({
    required Task task,
    required Color color,
    required double weight,
    required double maxWeight,
    required VoidCallback onTap,
    required ClassificationSettings settings,
    required List<CategoryConfig> categories,
    required CategoryColorService categoryColorService,
  }) {
    final widthFactor = (weight / maxWeight).clamp(0.15, 1.0);
    final category = categoryForTask(categories, task);
    final showReviewMarker = settings.showConfidenceIndicators &&
        task.classificationConfidence == ConfidenceLevel.low;
    final showAutoTag = settings.showAutoTags && task.autoTags.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * widthFactor;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: barWidth,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Indicador de cuadrante
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Título de la tarea
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                color: Color(0xFFE6E6E6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _getQuadrantLabel(task.quadrant),
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                if (category != null)
                                  _buildInfoChip(
                                    category.name,
                                    background: categoryColorService
                                        .getLightVariant(category.name,
                                            opacity: 0.22),
                                    border: categoryColorService.getDarkVariant(
                                        category.name,
                                        opacity: 0.55),
                                  ),
                                if (showReviewMarker)
                                  Tooltip(
                                    message: 'Clasificación de baja confianza',
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFFB020),
                                      ),
                                    ),
                                  ),
                                if (showAutoTag)
                                  _buildInfoChip(
                                    task.autoTags.first,
                                    background: const Color(0x332563EB),
                                    border: const Color(0x882563EB),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Indicador de tiempo
                      if (task.due != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDueDate(task.due!),
                            style: const TextStyle(
                              color: Color(0xFF7C7C7C),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getQuadrantLabel(Quadrant q) {
    final label = getQuadrantLabel(q, QuadrantLabelStyle.professional);
    return '${label.title} · ${label.subtitle}';
  }

  String _formatDueDate(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 0) return '${diff.abs()}d atrás';
    if (diff < 7) return '${diff}d';
    return '${(diff / 7).ceil()}sem';
  }

  Widget _buildInfoChip(
    String label, {
    required Color background,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE6E6E6),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: const Color(0xFF7C7C7C).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay tareas',
            style: TextStyle(
              color: Color(0xFF7C7C7C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tareas desde la vista Matrix',
            style: TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _handleTaskTap(WidgetRef ref, Task task) {
    ref.read(matrixControllerProvider.notifier).select(task.id);
    // Could open a detail view or drawer here
  }

  double _calculateWeight(Task task) {
    final importance = _getImportanceScore(task.quadrant);
    final urgency = _getUrgencyScore(task.quadrant);
    final time = task.minutes.toDouble();
    return (importance * 0.7 + urgency * 0.3) * (time / 60.0);
  }

  double _getImportanceScore(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 10.0;
      case Quadrant.q2:
        return 8.0;
      case Quadrant.q3:
        return 5.0;
      case Quadrant.q4:
        return 3.0;
    }
  }

  double _getUrgencyScore(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 10.0;
      case Quadrant.q2:
        return 4.0;
      case Quadrant.q3:
        return 8.0;
      case Quadrant.q4:
        return 2.0;
    }
  }
}
