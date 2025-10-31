class LayoutConfig {
  const LayoutConfig({
    this.topKPerQuadrant = 20,
    this.minAreaNormalized = 0.00004,
    this.gamma = 1.0,
    this.quadrantPadding = 0.012,
  });
  final int topKPerQuadrant;
  final double minAreaNormalized;
  final double gamma;
  final double quadrantPadding;

  LayoutConfig copyWith({
    int? topKPerQuadrant,
    double? minAreaNormalized,
    double? gamma,
    double? quadrantPadding,
  }) =>
      LayoutConfig(
        topKPerQuadrant: topKPerQuadrant ?? this.topKPerQuadrant,
        minAreaNormalized: minAreaNormalized ?? this.minAreaNormalized,
        gamma: gamma ?? this.gamma,
        quadrantPadding: quadrantPadding ?? this.quadrantPadding,
      );
}
