enum RulePriority {
  low,
  normal,
  high,
  critical;

  String get label => switch (this) {
        RulePriority.low => 'Baja',
        RulePriority.normal => 'Normal',
        RulePriority.high => 'Alta',
        RulePriority.critical => 'Crítica',
      };

  double get weight => switch (this) {
        RulePriority.low => 0.6,
        RulePriority.normal => 1.0,
        RulePriority.high => 1.4,
        RulePriority.critical => 1.8,
      };
}
