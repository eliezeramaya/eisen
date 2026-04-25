enum PriorityLevel {
  low,
  medium,
  high,
  critical;

  String get label => switch (this) {
        PriorityLevel.low => 'Baja',
        PriorityLevel.medium => 'Media',
        PriorityLevel.high => 'Alta',
        PriorityLevel.critical => 'Crítica',
      };
}
