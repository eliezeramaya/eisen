import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_weight.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';

List<AtlasNode> buildAtlasNodes({
  required List<Task> tasks,
  required AtlasGrouping grouping,
  QuadrantLabelStyle quadrantLabelStyle = QuadrantLabelStyle.professional,
}) {
  final buckets = <String, List<Task>>{};
  final labels = <String, String>{};

  for (final task in tasks) {
    final label = atlasGroupLabelForTask(
      task,
      grouping,
      quadrantLabelStyle: quadrantLabelStyle,
    );
    final key = label.trim().toLowerCase();
    labels[key] = label;
    buckets.putIfAbsent(key, () => <Task>[]).add(task);
  }

  final groups = <AtlasNode>[];
  for (final entry in buckets.entries) {
    final children = entry.value.map(_taskNode).toList()
      ..sort(_compareNodesByWeight);
    final groupWeight = children.fold<double>(
      0,
      (sum, node) => sum + node.weight,
    );
    groups.add(
      AtlasNode(
        id: 'group:${grouping.name}:${entry.key}',
        label: labels[entry.key] ?? 'Sin grupo',
        weight: groupWeight,
        children: children,
        type: AtlasNodeType.group,
      ),
    );
  }

  groups.sort(_compareNodesByWeight);
  return groups;
}

String atlasGroupLabelForTask(
  Task task,
  AtlasGrouping grouping, {
  QuadrantLabelStyle quadrantLabelStyle = QuadrantLabelStyle.professional,
}) {
  return switch (grouping) {
    AtlasGrouping.category => _categoryLabel(task),
    AtlasGrouping.quadrant => getQuadrantLabel(
        task.quadrant,
        quadrantLabelStyle,
      ).title,
    AtlasGrouping.horizon => _horizonLabel(task.horizon),
    AtlasGrouping.energy => _energyLabel(task.energy),
    AtlasGrouping.kind => _kindLabel(task.kind),
  };
}

AtlasNode _taskNode(Task task) {
  return AtlasNode(
    id: 'task:${task.id}',
    label: task.title,
    weight: computeAtlasTaskWeight(task),
    children: const <AtlasNode>[],
    task: task,
    type: AtlasNodeType.task,
  );
}

int _compareNodesByWeight(AtlasNode a, AtlasNode b) {
  final byWeight = b.weight.compareTo(a.weight);
  if (byWeight != 0) return byWeight;
  return a.label.compareTo(b.label);
}

String _categoryLabel(Task task) {
  final category = task.category?.trim();
  if (category != null && category.isNotEmpty) return category;
  for (final item in task.categories) {
    final value = item.trim();
    if (value.isNotEmpty) return value;
  }
  final categoryId = task.categoryId?.trim();
  if (categoryId != null && categoryId.isNotEmpty) return categoryId;
  return 'Sin categoría';
}

String _horizonLabel(TimeHorizon? horizon) {
  return switch (horizon) {
    TimeHorizon.today => 'Hoy',
    TimeHorizon.thisWeek => 'Esta semana',
    TimeHorizon.thisMonth => 'Este mes',
    TimeHorizon.someday => 'Algún día',
    null => 'Sin horizonte',
  };
}

String _energyLabel(EnergyLevel? energy) {
  return switch (energy) {
    EnergyLevel.low => 'Baja energía',
    EnergyLevel.medium => 'Energía media',
    EnergyLevel.high => 'Alta energía',
    null => 'Sin energía',
  };
}

String _kindLabel(EntryKind kind) {
  return switch (kind) {
    EntryKind.task => 'Tarea',
    EntryKind.idea => 'Idea',
    EntryKind.habit => 'Hábito',
    EntryKind.reminder => 'Recordatorio',
    EntryKind.project => 'Proyecto',
    EntryKind.shoppingItem => 'Compra',
  };
}
