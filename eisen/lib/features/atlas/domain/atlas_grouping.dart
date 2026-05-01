enum AtlasGrouping {
  category,
  quadrant,
  horizon,
  energy,
  kind,
}

extension AtlasGroupingLabel on AtlasGrouping {
  String get label => switch (this) {
        AtlasGrouping.category => 'Categoría',
        AtlasGrouping.quadrant => 'Cuadrante',
        AtlasGrouping.horizon => 'Horizonte',
        AtlasGrouping.energy => 'Energía',
        AtlasGrouping.kind => 'Tipo',
      };
}
