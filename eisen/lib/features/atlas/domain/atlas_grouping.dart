enum AtlasGrouping {
  category,
  quadrant,
  horizon,
  energy,
  kind,
}

AtlasGrouping atlasGroupingFromName(String? name) {
  for (final grouping in AtlasGrouping.values) {
    if (grouping.name == name) return grouping;
  }
  return AtlasGrouping.category;
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
