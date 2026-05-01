import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'layout_config.dart';

class TreemapDensityProfiles {
  const TreemapDensityProfiles._();

  static const String airy = 'airy';
  static const String balanced = 'balanced';
  static const String compact = 'compact';
  static const String detailed = 'detailed';
  static const String custom = 'custom';

  static const Set<String> allowed = <String>{
    airy,
    balanced,
    compact,
    detailed,
    custom,
  };

  static String sanitize(String? value) {
    if (allowed.contains(value)) {
      return value!;
    }
    return balanced;
  }
}

class ResolvedTreemapDensity {
  const ResolvedTreemapDensity({
    required this.profile,
    required this.topKPerQuadrant,
    required this.gamma,
    required this.minAreaNormalized,
    required this.quadrantPadding,
    required this.minTileSizePx,
    required this.compactDensity,
    required this.description,
    required this.isDesktopProfile,
  });

  final String profile;
  final int topKPerQuadrant;
  final double gamma;
  final double minAreaNormalized;
  final double quadrantPadding;
  final double minTileSizePx;
  final bool compactDensity;
  final String description;
  final bool isDesktopProfile;

  LayoutConfig get layoutConfig => LayoutConfig(
        topKPerQuadrant: topKPerQuadrant,
        gamma: gamma,
        minAreaNormalized: minAreaNormalized,
        quadrantPadding: quadrantPadding,
      );
}

class TreemapDensityResolver {
  const TreemapDensityResolver._();

  static const double _maxMinTileSizePx = 44.0;
  static const double _desktopMinTileFloor = 30.0;
  static const double _mobileMinTileFloor = 40.0;
  static const Size fallbackScreenSize = Size(720, 900);

  static ResolvedTreemapDensity resolve({
    required UiPrefsData prefs,
    required Size screenSize,
  }) {
    final profile = TreemapDensityProfiles.sanitize(
      prefs.treemapDensityProfile,
    );
    final isDesktopProfile = usesDesktopProfile(screenSize);
    final gamma = (prefs.gamma.clamp(0.70, 1.0) as num).toDouble();

    if (profile == TreemapDensityProfiles.custom) {
      return _resolveCustom(
        prefs: prefs,
        gamma: gamma,
        screenSize: screenSize,
      );
    }

    final presetMap = isDesktopProfile ? _desktopProfiles : _mobileProfiles;
    final preset =
        presetMap[profile] ?? presetMap[TreemapDensityProfiles.balanced]!;

    return ResolvedTreemapDensity(
      profile: profile,
      topKPerQuadrant: preset.topKPerQuadrant,
      gamma: gamma,
      minAreaNormalized: preset.minAreaNormalized,
      quadrantPadding: preset.quadrantPadding,
      minTileSizePx: (preset.minTileSizePx.clamp(
              _minTileFloorForSize(screenSize), _maxMinTileSizePx) as num)
          .toDouble(),
      compactDensity: preset.compactDensity,
      description: descriptionForProfile(profile),
      isDesktopProfile: isDesktopProfile,
    );
  }

  static bool usesDesktopProfile(Size screenSize) =>
      deviceClassOf(screenSize.width).isExpandedUp;

  static String descriptionForProfile(String profile) {
    return switch (TreemapDensityProfiles.sanitize(profile)) {
      TreemapDensityProfiles.airy =>
        'Fewer visible tasks, larger tiles, easier scanning.',
      TreemapDensityProfiles.balanced => 'Recommended default.',
      TreemapDensityProfiles.compact =>
        'More visible tasks with moderate compression.',
      TreemapDensityProfiles.detailed =>
        'Maximum information density for larger screens.',
      TreemapDensityProfiles.custom => 'Fine-tuned manually.',
      _ => 'Recommended default.',
    };
  }

  static String inferLegacyProfile({
    required int topKPerQuadrant,
    required double minAreaNormalized,
    required double quadrantPadding,
    required double minTileSizePx,
  }) {
    const defaultTopK = 20;
    const defaultMinArea = 0.00004;
    const defaultPadding = 0.012;
    const defaultMinTileSize = 44.0;

    final looksUntouched = topKPerQuadrant == defaultTopK &&
        (minAreaNormalized - defaultMinArea).abs() < 0.0000001 &&
        (quadrantPadding - defaultPadding).abs() < 0.0000001 &&
        (minTileSizePx - defaultMinTileSize).abs() < 0.001;
    return looksUntouched
        ? TreemapDensityProfiles.balanced
        : TreemapDensityProfiles.custom;
  }

  static ResolvedTreemapDensity _resolveCustom({
    required UiPrefsData prefs,
    required double gamma,
    required Size screenSize,
  }) {
    final isDesktopProfile = usesDesktopProfile(screenSize);
    final topK = (prefs.topKPerQuadrant.clamp(5, 100) as num).toInt();
    final minArea =
        (prefs.minAreaNormalized.clamp(0.00002, 0.0002) as num).toDouble();
    final quadrantPadding =
        (prefs.quadrantPadding.clamp(0.0, 0.02) as num).toDouble();
    final minTileSizePx = (prefs.minTileSizePx
            .clamp(_minTileFloorForSize(screenSize), _maxMinTileSizePx) as num)
        .toDouble();

    final compactDensity = isDesktopProfile
        ? (topK >= 28 || minTileSizePx <= 36.0 || minArea <= 0.00004)
        : (topK >= 16 || minArea <= 0.00005);

    return ResolvedTreemapDensity(
      profile: TreemapDensityProfiles.custom,
      topKPerQuadrant: topK,
      gamma: gamma,
      minAreaNormalized: minArea,
      quadrantPadding: quadrantPadding,
      minTileSizePx: minTileSizePx,
      compactDensity: compactDensity,
      description: descriptionForProfile(TreemapDensityProfiles.custom),
      isDesktopProfile: isDesktopProfile,
    );
  }

  static double _minTileFloorForSize(Size screenSize) {
    return usesDesktopProfile(screenSize)
        ? _desktopMinTileFloor
        : _mobileMinTileFloor;
  }

  static const Map<String, _DensityPresetValues> _desktopProfiles =
      <String, _DensityPresetValues>{
    TreemapDensityProfiles.airy: _DensityPresetValues(
      topKPerQuadrant: 12,
      minAreaNormalized: 0.00010,
      quadrantPadding: 0.014,
      minTileSizePx: 44.0,
      compactDensity: false,
    ),
    TreemapDensityProfiles.balanced: _DensityPresetValues(
      topKPerQuadrant: 20,
      minAreaNormalized: 0.00006,
      quadrantPadding: 0.012,
      minTileSizePx: 40.0,
      compactDensity: false,
    ),
    TreemapDensityProfiles.compact: _DensityPresetValues(
      topKPerQuadrant: 28,
      minAreaNormalized: 0.00004,
      quadrantPadding: 0.010,
      minTileSizePx: 34.0,
      compactDensity: true,
    ),
    TreemapDensityProfiles.detailed: _DensityPresetValues(
      topKPerQuadrant: 40,
      minAreaNormalized: 0.00002,
      quadrantPadding: 0.008,
      minTileSizePx: 30.0,
      compactDensity: true,
    ),
  };

  static const Map<String, _DensityPresetValues> _mobileProfiles =
      <String, _DensityPresetValues>{
    TreemapDensityProfiles.airy: _DensityPresetValues(
      topKPerQuadrant: 8,
      minAreaNormalized: 0.00012,
      quadrantPadding: 0.014,
      minTileSizePx: 44.0,
      compactDensity: false,
    ),
    TreemapDensityProfiles.balanced: _DensityPresetValues(
      topKPerQuadrant: 12,
      minAreaNormalized: 0.00008,
      quadrantPadding: 0.012,
      minTileSizePx: 42.0,
      compactDensity: false,
    ),
    TreemapDensityProfiles.compact: _DensityPresetValues(
      topKPerQuadrant: 16,
      minAreaNormalized: 0.00005,
      quadrantPadding: 0.010,
      minTileSizePx: 40.0,
      compactDensity: true,
    ),
    TreemapDensityProfiles.detailed: _DensityPresetValues(
      topKPerQuadrant: 20,
      minAreaNormalized: 0.00003,
      quadrantPadding: 0.009,
      minTileSizePx: 40.0,
      compactDensity: true,
    ),
  };
}

class _DensityPresetValues {
  const _DensityPresetValues({
    required this.topKPerQuadrant,
    required this.minAreaNormalized,
    required this.quadrantPadding,
    required this.minTileSizePx,
    required this.compactDensity,
  });

  final int topKPerQuadrant;
  final double minAreaNormalized;
  final double quadrantPadding;
  final double minTileSizePx;
  final bool compactDensity;
}

final treemapDensityForSizeProvider =
    Provider.autoDispose.family<ResolvedTreemapDensity, Size>((ref, size) {
  final prefs = ref.watch(uiPrefsProvider);
  return TreemapDensityResolver.resolve(
    prefs: prefs,
    screenSize: size,
  );
});
