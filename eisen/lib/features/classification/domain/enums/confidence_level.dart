enum ConfidenceLevel {
  low,
  medium,
  high;

  String get label => switch (this) {
        ConfidenceLevel.low => 'Baja',
        ConfidenceLevel.medium => 'Media',
        ConfidenceLevel.high => 'Alta',
      };
}
