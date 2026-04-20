import 'dart:math' as math;

import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:flutter/material.dart';

enum ContextTreemapGroup {
  home,
  office,
  errands,
  study,
  wellness,
  unknown,
}

class ContextTreemapSection {
  const ContextTreemapSection({
    required this.group,
    required this.tasks,
    required this.totalWeight,
    required this.averageScore,
    required this.isActive,
  });

  final ContextTreemapGroup group;
  final List<ContextTreemapTileSeed> tasks;
  final double totalWeight;
  final double averageScore;
  final bool isActive;
}

class ContextTreemapTileSeed {
  const ContextTreemapTileSeed({
    required this.rankedTask,
    required this.visualWeight,
    required this.group,
  });

  final RankedContextTask rankedTask;
  final double visualWeight;
  final ContextTreemapGroup group;
}

class ContextTreemapLayout {
  const ContextTreemapLayout({
    required this.sections,
  });

  final List<ContextTreemapSectionLayout> sections;

  List<ContextTreemapGroup> get availableGroups =>
      sections.map((section) => section.group).toList(growable: false);

  RankedContextTask? get topRankedTask {
    RankedContextTask? best;
    for (final section in sections) {
      for (final tile in section.tiles) {
        if (best == null || tile.seed.rankedTask.score > best.score) {
          best = tile.seed.rankedTask;
        }
      }
    }
    return best;
  }
}

class ContextTreemapSectionLayout {
  const ContextTreemapSectionLayout({
    required this.group,
    required this.rect01,
    required this.tiles,
    required this.totalWeight,
    required this.averageScore,
    required this.isActive,
  });

  final ContextTreemapGroup group;
  final Rect rect01;
  final List<ContextTreemapTileLayout> tiles;
  final double totalWeight;
  final double averageScore;
  final bool isActive;
}

class ContextTreemapTileLayout {
  const ContextTreemapTileLayout({
    required this.seed,
    required this.rect01,
  });

  final ContextTreemapTileSeed seed;
  final Rect rect01;
}

List<ContextTreemapSection> buildContextTreemapSections({
  required List<RankedContextTask> rankedTasks,
  required ContextState context,
}) {
  final grouped = <ContextTreemapGroup, List<ContextTreemapTileSeed>>{};

  for (final rankedTask in rankedTasks) {
    final group = inferContextTreemapGroup(rankedTask.task);
    grouped.putIfAbsent(group, () => <ContextTreemapTileSeed>[]).add(
          ContextTreemapTileSeed(
            rankedTask: rankedTask,
            visualWeight: computeContextualVisualWeight(rankedTask),
            group: group,
          ),
        );
  }

  final activeGroup = contextTagToTreemapGroup(context.currentLocationTag);
  final sections = grouped.entries.map((entry) {
    final tasks = [...entry.value]..sort((a, b) {
        final byWeight = b.visualWeight.compareTo(a.visualWeight);
        if (byWeight != 0) return byWeight;
        return a.rankedTask.task.title.compareTo(b.rankedTask.task.title);
      });

    final totalWeight =
        tasks.fold<double>(0, (sum, task) => sum + task.visualWeight);
    final averageScore = tasks.isEmpty
        ? 0.0
        : tasks.fold<double>(0, (sum, task) => sum + task.rankedTask.score) /
            tasks.length;

    return ContextTreemapSection(
      group: entry.key,
      tasks: tasks,
      totalWeight: totalWeight,
      averageScore: averageScore,
      isActive: entry.key == activeGroup,
    );
  }).toList()
    ..sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      final byWeight = b.totalWeight.compareTo(a.totalWeight);
      if (byWeight != 0) return byWeight;
      return a.group.index.compareTo(b.group.index);
    });

  return sections;
}

ContextTreemapLayout buildContextTreemapLayout({
  required List<ContextTreemapSection> sections,
  ContextTreemapGroup? focusedGroup,
}) {
  final visibleSections = focusedGroup == null
      ? sections
      : sections.where((section) => section.group == focusedGroup).toList();

  if (visibleSections.isEmpty) {
    return const ContextTreemapLayout(
        sections: <ContextTreemapSectionLayout>[]);
  }

  final sectionRects = _computeStableRectangles<ContextTreemapSection>(
    visibleSections
        .map(
          (section) => _WeightedNode<ContextTreemapSection>(
            id: 'section_${section.group.name}',
            weight: _sectionWeight(section),
            value: section,
          ),
        )
        .toList(growable: false),
    const Rect.fromLTWH(0, 0, 1, 1),
  );

  final layouts = sectionRects.map((sectionRect) {
    final tileRects = _computeStableRectangles<ContextTreemapTileSeed>(
      sectionRect.value.tasks
          .map(
            (task) => _WeightedNode<ContextTreemapTileSeed>(
              id: task.rankedTask.task.id,
              weight: task.visualWeight,
              value: task,
            ),
          )
          .toList(growable: false),
      const Rect.fromLTWH(0, 0, 1, 1),
    );

    return ContextTreemapSectionLayout(
      group: sectionRect.value.group,
      rect01: sectionRect.rect01,
      totalWeight: sectionRect.value.totalWeight,
      averageScore: sectionRect.value.averageScore,
      isActive: sectionRect.value.isActive,
      tiles: tileRects
          .map(
            (tileRect) => ContextTreemapTileLayout(
              seed: tileRect.value,
              rect01: tileRect.rect01,
            ),
          )
          .toList(growable: false),
    );
  }).toList(growable: false);

  return ContextTreemapLayout(sections: layouts);
}

double computeContextualVisualWeight(RankedContextTask rankedTask) {
  final task = rankedTask.task;
  final quickWinBonus =
      (1 - ((task.minutes.clamp(10, 180) - 10) / 170)).clamp(0.0, 1.0);

  var visualWeight = (rankedTask.score * 0.60) +
      (task.priorityNorm * 0.25) +
      (quickWinBonus * 0.15);

  if (task.isBlocked) {
    visualWeight *= 0.58;
  }
  if (task.isCompleted) {
    visualWeight *= 0.32;
  }

  return math.pow(math.max(visualWeight, 0.05), 1.20).toDouble();
}

ContextTreemapGroup contextTagToTreemapGroup(String? tag) {
  switch (tag) {
    case 'home':
      return ContextTreemapGroup.home;
    case 'office':
      return ContextTreemapGroup.office;
    case 'errands':
      return ContextTreemapGroup.errands;
    case 'study':
      return ContextTreemapGroup.study;
    case 'wellness':
      return ContextTreemapGroup.wellness;
    default:
      return ContextTreemapGroup.unknown;
  }
}

String localizedTreemapGroupLabel(
  BuildContext context,
  ContextTreemapGroup group,
) {
  switch (group) {
    case ContextTreemapGroup.home:
      return localizedContextTag(context, 'home');
    case ContextTreemapGroup.office:
      return localizedContextTag(context, 'office');
    case ContextTreemapGroup.errands:
      return localizedContextTag(context, 'errands');
    case ContextTreemapGroup.study:
      return localizedContextTag(context, 'study');
    case ContextTreemapGroup.wellness:
      return localizedContextTag(context, 'wellness');
    case ContextTreemapGroup.unknown:
      return localizedContextTag(context, 'unknown');
  }
}

ContextTreemapGroup inferContextTreemapGroup(Task task) {
  final fromTag = contextTagToTreemapGroup(task.locationTag);
  if (fromTag != ContextTreemapGroup.unknown) {
    return fromTag;
  }

  final haystack = <String>[
    if (task.category != null) task.category!,
    ...task.categories,
    ...task.tags,
    task.description,
    task.title,
  ].join(' ').toLowerCase();

  if (_matchesAny(
    haystack,
    const [
      'salud',
      'wellness',
      'health',
      'yoga',
      'medit',
      'descanso',
      'cardio'
    ],
  )) {
    return ContextTreemapGroup.wellness;
  }

  if (_matchesAny(
    haystack,
    const [
      'study',
      'estudio',
      'learn',
      'aprendiz',
      'curso',
      'leer',
      'doc',
      'api'
    ],
  )) {
    return ContextTreemapGroup.study;
  }

  if (_matchesAny(
    haystack,
    const ['home', 'casa', 'hogar', 'ropa', 'desk', 'escritorio'],
  )) {
    return ContextTreemapGroup.home;
  }

  if (_matchesAny(
    haystack,
    const ['office', 'oficina', 'trabajo', 'cliente', 'backend', 'reunion'],
  )) {
    return ContextTreemapGroup.office;
  }

  if (_matchesAny(
    haystack,
    const ['errands', 'recados', 'compra', 'llamada', 'tramite', 'gestio'],
  )) {
    return ContextTreemapGroup.errands;
  }

  return ContextTreemapGroup.unknown;
}

bool _matchesAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) return true;
  }
  return false;
}

double _sectionWeight(ContextTreemapSection section) {
  final activeBoost = section.isActive ? 1.18 : 1.0;
  final scoreBoost = 0.85 + (section.averageScore * 0.35);
  return math.max(0.10, section.totalWeight * activeBoost * scoreBoost);
}

List<_WeightedRect<T>> _computeStableRectangles<T>(
  List<_WeightedNode<T>> nodes,
  Rect bounds,
) {
  if (nodes.isEmpty) return <_WeightedRect<T>>[];

  final normalized = nodes
      .map(
        (node) => _WeightedNode<T>(
          id: node.id,
          weight: math.max(node.weight, 0.0001),
          value: node.value,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      return a.id.compareTo(b.id);
    });

  final totalWeight =
      normalized.fold<double>(0, (sum, node) => sum + node.weight);
  final items = normalized
      .map(
        (node) => _LayoutItem<T>(
          id: node.id,
          area: (node.weight / totalWeight) * bounds.width * bounds.height,
          value: node.value,
        ),
      )
      .toList(growable: false);

  var cursor = bounds;
  final result = <_WeightedRect<T>>[];
  var row = <_LayoutItem<T>>[];

  double worst(List<_LayoutItem<T>> rowItems, double shortSide) {
    final rowArea = rowItems.fold<double>(0, (sum, item) => sum + item.area);
    final maxArea =
        rowItems.fold<double>(0, (max, item) => math.max(max, item.area));
    final minArea = rowItems.fold<double>(
      double.infinity,
      (min, item) => math.min(min, item.area),
    );
    if (rowArea == 0 || minArea == 0) return double.infinity;
    final rowAreaSquared = rowArea * rowArea;
    final shortSideSquared = shortSide * shortSide;
    return math.max(
      (shortSideSquared * maxArea) / rowAreaSquared,
      rowAreaSquared / (shortSideSquared * minArea),
    );
  }

  void layoutRow(List<_LayoutItem<T>> rowItems, Rect rowBounds) {
    if (rowItems.isEmpty) return;

    final rowArea = rowItems.fold<double>(0, (sum, item) => sum + item.area);
    final shortSide = math.min(rowBounds.width, rowBounds.height);
    var horizontal = rowBounds.width >= rowBounds.height;
    if (worst(rowItems, shortSide) > 20) {
      horizontal = !horizontal;
    }

    if (horizontal) {
      final height = rowArea / rowBounds.width;
      var x = rowBounds.left;
      for (final item in rowItems) {
        final width = item.area / height;
        result.add(
          _WeightedRect<T>(
            rect01: _snapRect(Rect.fromLTWH(x, rowBounds.top, width, height)),
            value: item.value,
          ),
        );
        x += width;
      }
      cursor = Rect.fromLTWH(
        rowBounds.left,
        rowBounds.top + height,
        rowBounds.width,
        math.max(0, rowBounds.height - height),
      );
      return;
    }

    final width = rowArea / rowBounds.height;
    var y = rowBounds.top;
    for (final item in rowItems) {
      final height = item.area / width;
      result.add(
        _WeightedRect<T>(
          rect01: _snapRect(Rect.fromLTWH(rowBounds.left, y, width, height)),
          value: item.value,
        ),
      );
      y += height;
    }
    cursor = Rect.fromLTWH(
      rowBounds.left + width,
      rowBounds.top,
      math.max(0, rowBounds.width - width),
      rowBounds.height,
    );
  }

  for (final item in items) {
    if (row.isEmpty) {
      row = <_LayoutItem<T>>[item];
      continue;
    }

    final shortSide = math.min(cursor.width, cursor.height);
    final candidate = [...row, item];
    if (worst(candidate, shortSide) <= worst(row, shortSide)) {
      row.add(item);
    } else {
      layoutRow(row, cursor);
      row = <_LayoutItem<T>>[item];
    }
  }

  layoutRow(row, cursor);
  return result;
}

Rect _snapRect(Rect rect) {
  double snap(double value) => (value * 2000).roundToDouble() / 2000;
  final left = snap(rect.left);
  final top = snap(rect.top);
  final right = snap(rect.right);
  final bottom = snap(rect.bottom);
  return Rect.fromLTWH(
    left,
    top,
    math.max(0.0, right - left),
    math.max(0.0, bottom - top),
  );
}

class _WeightedNode<T> {
  const _WeightedNode({
    required this.id,
    required this.weight,
    required this.value,
  });

  final String id;
  final double weight;
  final T value;
}

class _LayoutItem<T> {
  const _LayoutItem({
    required this.id,
    required this.area,
    required this.value,
  });

  final String id;
  final double area;
  final T value;
}

class _WeightedRect<T> {
  const _WeightedRect({
    required this.rect01,
    required this.value,
  });

  final Rect rect01;
  final T value;
}
