import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassificationResult {
  const ClassificationResult({
    required this.kind,
    required this.category,
    required this.horizon,
    required this.energy,
    required this.priority,
    required this.confidence,
    required this.autoTags,
    required this.matchedKeywords,
    required this.confidenceReason,
    this.suggestedQuadrant,
    this.urgencyScore = 0.0,
    this.importanceScore = 0.0,
    this.quadrantReason = '',
  });

  final EntryKind kind;
  final String? category;
  final TimeHorizon horizon;
  final EnergyLevel energy;
  final PriorityLevel priority;
  final ConfidenceLevel confidence;
  final List<String> autoTags;
  final List<String> matchedKeywords;
  final String confidenceReason;
  final Quadrant? suggestedQuadrant;
  final double urgencyScore;
  final double importanceScore;
  final String quadrantReason;
}
