import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/settings/presentation/live_preview_pane.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LayoutMobilePanel extends ConsumerStatefulWidget {
  const LayoutMobilePanel({super.key});

  @override
  ConsumerState<LayoutMobilePanel> createState() => _LayoutMobilePanelState();
}

class _LayoutMobilePanelState extends ConsumerState<LayoutMobilePanel> {
  bool _previewEnabled = false;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    final size = MediaQuery.sizeOf(context);
    final uiPrefs = ref.read(uiPrefsControllerProvider.notifier);
    final matrix = ref.read(matrixControllerProvider.notifier);

    Future<void> saveLayout({
      int? topK,
      double? gamma,
      double? minArea,
      double? padding,
      double? minTileSizePx,
      String? profile,
    }) async {
      await uiPrefs.applyLayoutPrefs(
        topKPerQuadrant: topK ?? prefs.topKPerQuadrant,
        gamma: gamma ?? prefs.gamma,
        minAreaNormalized: minArea ?? prefs.minAreaNormalized,
        quadrantPadding: padding ?? prefs.quadrantPadding,
        minTileSizePx: minTileSizePx ?? prefs.minTileSizePx,
        treemapDensityProfile: profile ?? prefs.treemapDensityProfile,
        isDesktop: size.width >= 900,
      );
      matrix.notifyLayoutRecompute();
    }

    return TreemapLayoutPanel(
      treemapDensityProfile: prefs.treemapDensityProfile,
      topK: prefs.topKPerQuadrant,
      gamma: prefs.gamma,
      minArea: prefs.minAreaNormalized,
      padding: prefs.quadrantPadding,
      minTileSizePx: prefs.minTileSizePx,
      onTreemapDensityProfileChanged: (profile) async {
        if (profile == 'custom') {
          await uiPrefs.setTreemapDensityProfile(profile);
        } else {
          await uiPrefs.applyTreemapDensityProfile(
            profile: profile,
            screenSize: size,
          );
        }
        matrix.notifyLayoutRecompute();
      },
      onTopK: (value) => saveLayout(
        topK: value,
        profile: 'custom',
      ),
      onGamma: (value) => saveLayout(
        gamma: value,
        profile: 'custom',
      ),
      onMinArea: (value) => saveLayout(
        minArea: value,
        profile: 'custom',
      ),
      onPadding: (value) => saveLayout(
        padding: value,
        profile: 'custom',
      ),
      onMinTileSize: (value) => saveLayout(
        minTileSizePx: value,
        profile: 'custom',
      ),
      preview: _previewEnabled,
      onPreview: (value) => setState(() => _previewEnabled = value),
      inlinePreview: LivePreviewPane(
        enabled: _previewEnabled,
        screenSize: size,
        treemapDensityProfile: prefs.treemapDensityProfile,
        topK: prefs.topKPerQuadrant,
        gamma: prefs.gamma,
        minArea: prefs.minAreaNormalized,
        qPad: prefs.quadrantPadding,
        minTileSizePx: prefs.minTileSizePx,
      ),
      advancedInitiallyExpanded: prefs.treemapDensityProfile == 'custom',
    );
  }
}
