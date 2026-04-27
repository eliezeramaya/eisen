enum EnergyLevel {
  low,
  medium,
  high;

  String get label => switch (this) {
        EnergyLevel.low => 'Baja',
        EnergyLevel.medium => 'Media',
        EnergyLevel.high => 'Alta',
      };
}
