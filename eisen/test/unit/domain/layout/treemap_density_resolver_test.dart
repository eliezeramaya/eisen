import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TreemapDensityResolver', () {
    test('maps balanced desktop profile to recommended defaults', () {
      final resolved = TreemapDensityResolver.resolve(
        prefs: const UiPrefsData(
          treemapDensityProfile: TreemapDensityProfiles.balanced,
        ),
        screenSize: const Size(1440, 900),
      );

      expect(resolved.profile, TreemapDensityProfiles.balanced);
      expect(resolved.isDesktopProfile, isTrue);
      expect(resolved.topKPerQuadrant, 20);
      expect(resolved.minAreaNormalized, 0.00006);
      expect(resolved.quadrantPadding, 0.012);
      expect(resolved.minTileSizePx, 40.0);
      expect(resolved.compactDensity, isFalse);
    });

    test('keeps mobile detailed profile touch-safe', () {
      final resolved = TreemapDensityResolver.resolve(
        prefs: const UiPrefsData(
          treemapDensityProfile: TreemapDensityProfiles.detailed,
        ),
        screenSize: const Size(430, 900),
      );

      expect(resolved.profile, TreemapDensityProfiles.detailed);
      expect(resolved.isDesktopProfile, isFalse);
      expect(resolved.topKPerQuadrant, 20);
      expect(resolved.minAreaNormalized, 0.00003);
      expect(resolved.minTileSizePx, greaterThanOrEqualTo(40.0));
      expect(resolved.compactDensity, isTrue);
    });

    test('custom profile preserves manual values inside safe bounds', () {
      final resolved = TreemapDensityResolver.resolve(
        prefs: const UiPrefsData(
          treemapDensityProfile: TreemapDensityProfiles.custom,
          topKPerQuadrant: 33,
          gamma: 0.82,
          minAreaNormalized: 0.00005,
          quadrantPadding: 0.011,
          minTileSizePx: 31,
        ),
        screenSize: const Size(430, 900),
      );

      expect(resolved.profile, TreemapDensityProfiles.custom);
      expect(resolved.topKPerQuadrant, 33);
      expect(resolved.gamma, 0.82);
      expect(resolved.minAreaNormalized, 0.00005);
      expect(resolved.quadrantPadding, 0.011);
      expect(resolved.minTileSizePx, 40.0);
      expect(resolved.compactDensity, isTrue);
    });
  });
}
