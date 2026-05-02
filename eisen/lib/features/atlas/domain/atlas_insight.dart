import 'package:equatable/equatable.dart';

enum AtlasInsightKind {
  overload,
  focusOpportunity,
  classificationReview,
  stalePlan,
  quadrantImbalance,
}

enum AtlasInsightPriority {
  low,
  medium,
  high,
}

enum AtlasInsightActionKind {
  openPrimaryTask,
  editPrimaryTask,
  reclassifyPrimaryTask,
  filterLowConfidence,
  groupByQuadrant,
}

class AtlasInsightAction extends Equatable {
  const AtlasInsightAction({
    required this.kind,
    required this.label,
  });

  final AtlasInsightActionKind kind;
  final String label;

  @override
  List<Object?> get props => [kind, label];
}

class AtlasInsight extends Equatable {
  const AtlasInsight({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.message,
    this.primaryTaskId,
    this.taskIds = const <String>[],
    this.actions = const <AtlasInsightAction>[],
  });

  final String id;
  final AtlasInsightKind kind;
  final AtlasInsightPriority priority;
  final String title;
  final String message;
  final String? primaryTaskId;
  final List<String> taskIds;
  final List<AtlasInsightAction> actions;

  @override
  List<Object?> get props => [
        id,
        kind,
        priority,
        title,
        message,
        primaryTaskId,
        taskIds,
        actions,
      ];
}
