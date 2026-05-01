import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TreemapLayoutPanel avanzado monta sin excepciones',
      (tester) async {
    var profile = TreemapDensityProfiles.balanced;
    var topK = 20;
    var gamma = 1.0;
    var minArea = 0.00006;
    var padding = 0.012;
    var minTileSize = 42.0;
    var preview = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TreemapLayoutPanel(
                treemapDensityProfile: profile,
                topK: topK,
                gamma: gamma,
                minArea: minArea,
                padding: padding,
                minTileSizePx: minTileSize,
                onTreemapDensityProfileChanged: (value) {
                  setState(() => profile = value);
                },
                onTopK: (value) {
                  setState(() => topK = value);
                },
                onGamma: (value) {
                  setState(() => gamma = value);
                },
                onMinArea: (value) {
                  setState(() => minArea = value);
                },
                onPadding: (value) {
                  setState(() => padding = value);
                },
                onMinTileSize: (value) {
                  setState(() => minTileSize = value);
                },
                preview: preview,
                onPreview: (value) {
                  setState(() => preview = value);
                },
                advancedInitiallyExpanded: true,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
