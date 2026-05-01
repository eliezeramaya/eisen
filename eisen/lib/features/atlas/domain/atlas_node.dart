import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:equatable/equatable.dart';

enum AtlasNodeType {
  root,
  group,
  task,
}

class AtlasNode extends Equatable {
  const AtlasNode({
    required this.id,
    required this.label,
    required this.weight,
    required this.children,
    required this.type,
    this.task,
  });

  final String id;
  final String label;
  final double weight;
  final List<AtlasNode> children;
  final Task? task;
  final AtlasNodeType type;

  bool get isLeaf => type == AtlasNodeType.task || children.isEmpty;

  @override
  List<Object?> get props => [id, label, weight, children, task, type];
}
