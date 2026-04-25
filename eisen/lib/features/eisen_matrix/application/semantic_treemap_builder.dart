import 'dart:math' as math;

import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/services/task_classification_mapper.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';

class TreemapSemanticNode {
  const TreemapSemanticNode({
    required this.id,
    required this.label,
    required this.level,
    required this.tasks,
    required this.totalWeight,
    this.subtitle,
    this.categoryId,
    this.categoryLabel,
    this.loadShare = 0,
    this.lowConfidenceCount = 0,
    this.matchedSearch = false,
    this.tags = const <String>[],
  });

  final String id;
  final String label;
  final String? subtitle;
  final TreemapZoomLevel level;
  final List<Task> tasks;
  final double totalWeight;
  final String? categoryId;
  final String? categoryLabel;
  final double loadShare;
  final int lowConfidenceCount;
  final bool matchedSearch;
  final List<String> tags;

  int get taskCount => tasks.length;
  int get totalMinutes =>
      tasks.fold<int>(0, (sum, task) => sum + task.minutes.clamp(0, 1440));

  Task? get topTask => tasks.isEmpty
      ? null
      : ([...tasks]..sort((a, b) => weight(b).compareTo(weight(a)))).first;

  bool get isTaskLeaf => level == TreemapZoomLevel.task && tasks.length == 1;
}

class TreemapSemanticScene {
  const TreemapSemanticScene({
    required this.viewport,
    required this.nodes,
    required this.scopedTasks,
    required this.quickFilterCount,
    required this.lowConfidenceCount,
    required this.breadcrumbs,
    required this.title,
    required this.subtitle,
    this.exactTaskMatch,
  });

  final TreemapViewportState viewport;
  final List<TreemapSemanticNode> nodes;
  final List<Task> scopedTasks;
  final int quickFilterCount;
  final int lowConfidenceCount;
  final List<String> breadcrumbs;
  final String title;
  final String subtitle;
  final Task? exactTaskMatch;

  bool get isEmpty => scopedTasks.isEmpty;
}

TreemapSemanticScene buildSemanticTreemapScene({
  required List<Task> tasks,
  required List<CategoryConfig> categories,
  required TreemapViewportState viewport,
  required String searchQuery,
}) {
  final filtered = _applyQuickFilter(tasks, viewport.quickFilter);
  final scoped = _applyViewportScope(filtered, viewport, categories);
  final normalizedQuery = normalizeMatrixSearchText(searchQuery.trim());
  final exactTask = _findExactTaskMatch(scoped, normalizedQuery);
  final totalWeight = scoped.fold<double>(0, (sum, task) => sum + weight(task));
  final lowConfidenceCount = scoped
      .where((task) => task.classificationConfidence == ConfidenceLevel.low)
      .length;

  final nodes = switch (viewport.zoomLevel) {
    TreemapZoomLevel.global => const <TreemapSemanticNode>[],
    TreemapZoomLevel.category => _buildCategoryNodes(
        tasks: scoped,
        categories: categories,
        totalWeight: totalWeight,
        searchQuery: normalizedQuery,
      ),
    TreemapZoomLevel.subcategory => _buildGroupingNodes(
        tasks: scoped,
        categories: categories,
        grouping: viewport.grouping,
        totalWeight: totalWeight,
        searchQuery: normalizedQuery,
        level: TreemapZoomLevel.subcategory,
      ),
    TreemapZoomLevel.group => _buildCompactGroupNodes(
        tasks: scoped,
        categories: categories,
        totalWeight: totalWeight,
        searchQuery: normalizedQuery,
      ),
    TreemapZoomLevel.task => _buildTaskNodes(
        tasks: scoped,
        categories: categories,
        totalWeight: totalWeight,
        searchQuery: normalizedQuery,
      ),
  };

  return TreemapSemanticScene(
    viewport: viewport,
    nodes: nodes,
    scopedTasks: scoped,
    quickFilterCount: filtered.length,
    lowConfidenceCount: lowConfidenceCount,
    breadcrumbs: viewport.breadcrumbPath,
    exactTaskMatch: exactTask,
    title: _sceneTitle(viewport),
    subtitle: _sceneSubtitle(viewport, scoped.length, lowConfidenceCount),
  );
}

List<Task> _applyQuickFilter(
  List<Task> tasks,
  TreemapQuickFilter? filter,
) {
  if (filter == null) {
    return tasks;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekLimit = today.add(const Duration(days: 7));
  return tasks.where((task) {
    switch (filter) {
      case TreemapQuickFilter.today:
        final due = task.due;
        if (due == null) return false;
        final day = DateTime(due.year, due.month, due.day);
        return !day.isAfter(today);
      case TreemapQuickFilter.week:
        final due = task.due;
        if (due == null) return false;
        final day = DateTime(due.year, due.month, due.day);
        return !day.isBefore(today) && !day.isAfter(weekLimit);
      case TreemapQuickFilter.highPriority:
        return task.priority >= 8;
      case TreemapQuickFilter.lowConfidence:
        return task.classificationConfidence == ConfidenceLevel.low;
      case TreemapQuickFilter.lowEnergy:
        return task.energy == EnergyLevel.low;
    }
  }).toList(growable: false);
}

List<Task> _applyViewportScope(
  List<Task> tasks,
  TreemapViewportState viewport,
  List<CategoryConfig> categories,
) {
  Iterable<Task> scoped = tasks;

  final selectedQuadrant = viewport.selectedQuadrant;
  if (selectedQuadrant != null &&
      viewport.zoomLevel != TreemapZoomLevel.global) {
    scoped = scoped.where((task) => task.quadrant == selectedQuadrant);
  }

  final selectedCategoryId = viewport.selectedCategoryId;
  if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
    scoped = scoped.where(
      (task) => _categoryKey(task, categories) == selectedCategoryId,
    );
  }

  final selectedSubcategoryId = viewport.selectedSubcategoryId;
  if (selectedSubcategoryId != null && selectedSubcategoryId.isNotEmpty) {
    scoped = scoped.where(
      (task) =>
          _groupingKey(task, viewport.grouping, categories).id ==
          selectedSubcategoryId,
    );
  }

  final selectedGroupId = viewport.selectedGroupId;
  if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
    scoped = scoped.where(
      (task) => _smallGroupId(task, categories) == selectedGroupId,
    );
  }

  final selectedTaskId = viewport.selectedTaskId;
  if (selectedTaskId != null &&
      selectedTaskId.isNotEmpty &&
      viewport.zoomLevel == TreemapZoomLevel.task) {
    final selected = scoped.where((task) => task.id == selectedTaskId).toList();
    if (selected.isNotEmpty) {
      return selected;
    }
  }

  return scoped.toList(growable: false);
}

List<TreemapSemanticNode> _buildCategoryNodes({
  required List<Task> tasks,
  required List<CategoryConfig> categories,
  required double totalWeight,
  required String searchQuery,
}) {
  final groups = <String, List<Task>>{};
  for (final task in tasks) {
    final key = _categoryKey(task, categories);
    groups.putIfAbsent(key, () => <Task>[]).add(task);
  }
  return _buildNodesFromGroups(
    groups: groups,
    categories: categories,
    totalWeight: totalWeight,
    searchQuery: searchQuery,
    level: TreemapZoomLevel.category,
    labelFor: (key, tasks) => _categoryLabel(tasks.first, categories),
    subtitleFor: (_, items) => '${items.length} tareas',
  );
}

List<TreemapSemanticNode> _buildGroupingNodes({
  required List<Task> tasks,
  required List<CategoryConfig> categories,
  required TreemapGrouping grouping,
  required double totalWeight,
  required String searchQuery,
  required TreemapZoomLevel level,
}) {
  final groups = <String, List<Task>>{};
  final labels = <String, String>{};
  for (final task in tasks) {
    final token = _groupingKey(task, grouping, categories);
    labels[token.id] = token.label;
    groups.putIfAbsent(token.id, () => <Task>[]).add(task);
  }
  return _buildNodesFromGroups(
    groups: groups,
    categories: categories,
    totalWeight: totalWeight,
    searchQuery: searchQuery,
    level: level,
    labelFor: (key, _) => labels[key] ?? key,
    subtitleFor: (_, items) => _groupSubtitle(items),
  );
}

List<TreemapSemanticNode> _buildCompactGroupNodes({
  required List<Task> tasks,
  required List<CategoryConfig> categories,
  required double totalWeight,
  required String searchQuery,
}) {
  final groups = <String, List<Task>>{};
  final labels = <String, String>{};
  for (final task in tasks) {
    final id = _smallGroupId(task, categories);
    labels[id] = _smallGroupLabel(task, categories);
    groups.putIfAbsent(id, () => <Task>[]).add(task);
  }
  return _buildNodesFromGroups(
    groups: groups,
    categories: categories,
    totalWeight: totalWeight,
    searchQuery: searchQuery,
    level: TreemapZoomLevel.group,
    labelFor: (key, _) => labels[key] ?? key,
    subtitleFor: (_, items) =>
        '${items.length} tareas · ${_minutesLabel(items)}',
  );
}

List<TreemapSemanticNode> _buildTaskNodes({
  required List<Task> tasks,
  required List<CategoryConfig> categories,
  required double totalWeight,
  required String searchQuery,
}) {
  final sorted = [...tasks]..sort((a, b) => weight(b).compareTo(weight(a)));
  return [
    for (final task in sorted)
      TreemapSemanticNode(
        id: task.id,
        label: task.title,
        level: TreemapZoomLevel.task,
        tasks: <Task>[task],
        totalWeight: weight(task),
        categoryId: _categoryKey(task, categories),
        categoryLabel: _categoryLabel(task, categories),
        loadShare: totalWeight <= 0 ? 0 : weight(task) / totalWeight,
        lowConfidenceCount:
            task.classificationConfidence == ConfidenceLevel.low ? 1 : 0,
        matchedSearch: _taskMatchesQuery(task, searchQuery),
        subtitle: _taskSubtitle(task),
        tags: _visibleTags(task),
      ),
  ];
}

List<TreemapSemanticNode> _buildNodesFromGroups({
  required Map<String, List<Task>> groups,
  required List<CategoryConfig> categories,
  required double totalWeight,
  required String searchQuery,
  required TreemapZoomLevel level,
  required String Function(String key, List<Task> tasks) labelFor,
  required String Function(String key, List<Task> tasks) subtitleFor,
}) {
  final nodes = <TreemapSemanticNode>[];
  for (final entry in groups.entries) {
    final nodeTasks = entry.value;
    final nodeWeight =
        nodeTasks.fold<double>(0, (sum, task) => sum + weight(task));
    final dominant = _dominantCategory(nodeTasks, categories);
    nodes.add(
      TreemapSemanticNode(
        id: entry.key,
        label: labelFor(entry.key, nodeTasks),
        subtitle: subtitleFor(entry.key, nodeTasks),
        level: level,
        tasks: nodeTasks,
        totalWeight: math.max(0.0001, nodeWeight),
        categoryId: dominant?.id,
        categoryLabel:
            dominant?.name ?? _categoryLabel(nodeTasks.first, categories),
        loadShare: totalWeight <= 0 ? 0 : nodeWeight / totalWeight,
        lowConfidenceCount: nodeTasks
            .where(
              (task) => task.classificationConfidence == ConfidenceLevel.low,
            )
            .length,
        matchedSearch:
            nodeTasks.any((task) => _taskMatchesQuery(task, searchQuery)),
        tags: _topGroupTags(nodeTasks),
      ),
    );
  }
  nodes.sort((a, b) => b.totalWeight.compareTo(a.totalWeight));
  return nodes;
}

CategoryConfig? _dominantCategory(
  List<Task> tasks,
  List<CategoryConfig> categories,
) {
  final counts = <String, int>{};
  for (final task in tasks) {
    final key = _categoryKey(task, categories);
    counts.update(key, (value) => value + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) {
    return null;
  }
  final best = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final bestKey = best.first.key;
  for (final category in categories) {
    if (category.id == bestKey) {
      return category;
    }
  }
  return null;
}

String _categoryKey(Task task, List<CategoryConfig> categories) {
  final category = categoryForTask(categories, task);
  if (category != null) {
    return category.id;
  }
  final raw = (task.categoryId ?? task.category ?? 'sin-categoria').trim();
  if (raw.isEmpty) {
    return 'sin-categoria';
  }
  return normalizeMatrixSearchText(raw).replaceAll(' ', '-');
}

String _categoryLabel(Task task, List<CategoryConfig> categories) {
  final category = categoryForTask(categories, task);
  if (category != null) {
    return category.name;
  }
  final raw = (task.category ?? task.categoryId ?? 'Sin categoría').trim();
  return raw.isEmpty ? 'Sin categoría' : raw;
}

({String id, String label}) _groupingKey(
  Task task,
  TreemapGrouping grouping,
  List<CategoryConfig> categories,
) {
  switch (grouping) {
    case TreemapGrouping.category:
      return (
        id: _categoryKey(task, categories),
        label: _categoryLabel(task, categories),
      );
    case TreemapGrouping.kind:
      return (
        id: 'kind:${_slug(task.kind.name)}',
        label: task.kind.label,
      );
    case TreemapGrouping.horizon:
      final label = task.horizon?.label ?? 'Sin horizonte';
      return (id: 'horizon:${_slug(label)}', label: label);
    case TreemapGrouping.energy:
      final label = task.energy?.label ?? 'Sin energía';
      return (id: 'energy:${_slug(label)}', label: label);
    case TreemapGrouping.client:
      final client = _clientLabel(task);
      return (id: 'client:${_slug(client)}', label: client);
    case TreemapGrouping.project:
      final project = task.projectId?.trim();
      final label =
          (project == null || project.isEmpty) ? 'Sin proyecto' : project;
      return (id: 'project:${_slug(label)}', label: label);
    case TreemapGrouping.tag:
      final visible = _visibleTags(task);
      final tag = visible.isEmpty ? 'Sin tags' : visible.first;
      return (id: 'tag:${_slug(tag)}', label: tag);
    case TreemapGrouping.confidence:
      final label = _confidenceLabel(task.classificationConfidence);
      return (
        id: 'confidence:${_slug(label)}',
        label: label,
      );
    case TreemapGrouping.context:
      final label = _contextLabel(task.locationTag);
      return (id: 'context:${_slug(label)}', label: label);
  }
}

String _sceneTitle(TreemapViewportState viewport) {
  return switch (viewport.zoomLevel) {
    TreemapZoomLevel.global => 'Mapa global',
    TreemapZoomLevel.category => 'Categorías',
    TreemapZoomLevel.subcategory => 'Subcategorías',
    TreemapZoomLevel.group => 'Grupos',
    TreemapZoomLevel.task => 'Tareas',
  };
}

String _sceneSubtitle(
  TreemapViewportState viewport,
  int taskCount,
  int lowConfidenceCount,
) {
  final base = '$taskCount tareas visibles';
  if (viewport.quickFilter == TreemapQuickFilter.lowConfidence) {
    return '$base · revisión prioritaria';
  }
  if (lowConfidenceCount > 0) {
    return '$base · $lowConfidenceCount con baja confianza';
  }
  return base;
}

Task? _findExactTaskMatch(List<Task> tasks, String normalizedQuery) {
  if (normalizedQuery.isEmpty) {
    return null;
  }
  for (final task in tasks) {
    if (normalizeMatrixSearchText(task.title) == normalizedQuery) {
      return task;
    }
  }
  return null;
}

bool _taskMatchesQuery(Task task, String normalizedQuery) {
  if (normalizedQuery.isEmpty) {
    return true;
  }
  return taskMatchesSearchQuery(task, normalizedQuery);
}

String _groupSubtitle(List<Task> tasks) {
  final minutes = _minutesLabel(tasks);
  return '${tasks.length} tareas · $minutes';
}

String _minutesLabel(List<Task> tasks) {
  final total = tasks.fold<int>(0, (sum, task) => sum + task.minutes);
  if (total >= 60) {
    final hours = total / 60;
    return '${hours.toStringAsFixed(hours >= 10 ? 0 : 1)}h';
  }
  return '${total}m';
}

String _clientLabel(Task task) {
  final project = task.projectId?.trim();
  if (project != null && project.isNotEmpty) {
    return project;
  }
  final tokens = <String>[
    ...task.tags,
    ...task.autoTags,
    if (task.category != null) task.category!,
    if (task.notes != null) task.notes!,
    task.title,
  ];
  for (final token in tokens) {
    final normalized = normalizeMatrixSearchText(token);
    if (normalized.contains('cliente')) {
      return token.trim();
    }
  }
  return 'General';
}

String _contextLabel(String? locationTag) {
  if (locationTag == null || locationTag.trim().isEmpty) {
    return 'Sin contexto';
  }
  final normalized = normalizeMatrixSearchText(locationTag);
  if (normalized == 'office' || normalized == 'oficina') return 'Oficina';
  if (normalized == 'home' || normalized == 'casa') return 'Casa';
  if (normalized == 'study' || normalized == 'estudio') return 'Estudio';
  if (normalized == 'errands' || normalized == 'mandados') return 'Mandados';
  if (normalized == 'wellness' || normalized == 'salud') return 'Salud';
  return locationTag;
}

String _confidenceLabel(ConfidenceLevel? level) {
  return switch (level) {
    ConfidenceLevel.high => 'Alta confianza',
    ConfidenceLevel.medium => 'Confianza media',
    ConfidenceLevel.low => 'Revisar',
    null => 'Sin clasificar',
  };
}

String _smallGroupId(Task task, List<CategoryConfig> categories) {
  final base = _smallGroupLabel(task, categories);
  return _slug(base);
}

String _smallGroupLabel(Task task, List<CategoryConfig> categories) {
  final tags = _visibleTags(task);
  if (tags.isNotEmpty) {
    return tags.first;
  }
  final project = task.projectId?.trim();
  if (project != null && project.isNotEmpty) {
    return project;
  }
  final context = task.locationTag?.trim();
  if (context != null && context.isNotEmpty) {
    return _contextLabel(context);
  }
  if (task.due != null) {
    final now = DateTime.now();
    final diff = task.due!.difference(now).inDays;
    if (diff <= 0) return 'Hoy';
    if (diff <= 7) return 'Esta semana';
  }
  if (task.priority >= 8) return 'Prioridad alta';
  if (task.priority >= 5) return 'Prioridad media';
  final category = _categoryLabel(task, categories);
  return category;
}

String _taskSubtitle(Task task) {
  final parts = <String>[
    if (task.category != null && task.category!.trim().isNotEmpty)
      task.category!,
    if (task.horizon != null) task.horizon!.label,
    if (task.energy != null) task.energy!.label,
  ];
  if (parts.isEmpty) {
    parts.add('P${task.priority}');
  }
  return parts.take(3).join(' · ');
}

List<String> _visibleTags(Task task) {
  final tags = <String>{...task.tags, ...task.autoTags};
  return tags.where((tag) => tag.trim().isNotEmpty).take(3).toList();
}

List<String> _topGroupTags(List<Task> tasks) {
  final counts = <String, int>{};
  for (final task in tasks) {
    for (final tag in _visibleTags(task)) {
      counts.update(tag, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final ordered = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return ordered.take(3).map((entry) => entry.key).toList(growable: false);
}

String normalizeMatrixSearchText(String value) {
  final lower = value.trim().toLowerCase();
  const mapping = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final codeUnit in lower.runes) {
    final ch = String.fromCharCode(codeUnit);
    buffer.write(mapping[ch] ?? ch);
  }
  return buffer.toString();
}

bool taskMatchesSearchQuery(Task task, String normalizedQuery) {
  final title = normalizeMatrixSearchText(task.title);
  final notes = normalizeMatrixSearchText(task.notes ?? '');
  final category = normalizeMatrixSearchText(task.category ?? '');
  final categoryId = normalizeMatrixSearchText(task.categoryId ?? '');
  final categories = normalizeMatrixSearchText(task.categories.join(' '));
  final tags = normalizeMatrixSearchText(task.tags.join(' '));
  final autoTags = normalizeMatrixSearchText(task.autoTags.join(' '));
  final kind = normalizeMatrixSearchText(task.kind.label);
  final horizon = normalizeMatrixSearchText(task.horizon?.label ?? '');
  final energy = normalizeMatrixSearchText(task.energy?.label ?? '');
  return title.contains(normalizedQuery) ||
      notes.contains(normalizedQuery) ||
      category.contains(normalizedQuery) ||
      categoryId.contains(normalizedQuery) ||
      categories.contains(normalizedQuery) ||
      tags.contains(normalizedQuery) ||
      autoTags.contains(normalizedQuery) ||
      kind.contains(normalizedQuery) ||
      horizon.contains(normalizedQuery) ||
      energy.contains(normalizedQuery);
}

String _slug(String value) =>
    normalizeMatrixSearchText(value).replaceAll(' ', '-');
