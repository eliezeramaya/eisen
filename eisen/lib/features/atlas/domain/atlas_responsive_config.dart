import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

class AtlasResponsiveConfig {
  const AtlasResponsiveConfig({
    required this.canvasPadding,
    required this.tileGap,
    required this.groupHeaderHeight,
    required this.minReadableTileSize,
    required this.minInteractiveTileSize,
    required this.showLegendExpandedByDefault,
    required this.showToolbarMicrocopy,
    required this.enableHover,
    required this.enableSidePanel,
    required this.enableDenseMode,
    required this.maxWidgetTilesBeforeCompact,
    required this.maxWidgetTilesBeforePainter,
  });

  final EdgeInsets canvasPadding;
  final double tileGap;
  final double groupHeaderHeight;
  final Size minReadableTileSize;
  final Size minInteractiveTileSize;
  final bool showLegendExpandedByDefault;
  final bool showToolbarMicrocopy;
  final bool enableHover;
  final bool enableSidePanel;
  final bool enableDenseMode;
  final int maxWidgetTilesBeforeCompact;
  final int maxWidgetTilesBeforePainter;
}

AtlasResponsiveConfig atlasResponsiveConfigForWidth(double width) {
  return atlasResponsiveConfigForDeviceClass(deviceClassOf(width));
}

AtlasResponsiveConfig atlasResponsiveConfigForDeviceClass(DeviceClass device) {
  return switch (device) {
    DeviceClass.compact => const AtlasResponsiveConfig(
        canvasPadding: EdgeInsets.all(10),
        tileGap: 6,
        groupHeaderHeight: 22,
        minReadableTileSize: Size(72, 44),
        minInteractiveTileSize: Size(56, 40),
        showLegendExpandedByDefault: false,
        showToolbarMicrocopy: false,
        enableHover: false,
        enableSidePanel: false,
        enableDenseMode: false,
        maxWidgetTilesBeforeCompact: 80,
        maxWidgetTilesBeforePainter: 220,
      ),
    DeviceClass.medium => const AtlasResponsiveConfig(
        canvasPadding: EdgeInsets.all(12),
        tileGap: 5,
        groupHeaderHeight: 24,
        minReadableTileSize: Size(64, 40),
        minInteractiveTileSize: Size(48, 36),
        showLegendExpandedByDefault: false,
        showToolbarMicrocopy: true,
        enableHover: false,
        enableSidePanel: false,
        enableDenseMode: false,
        maxWidgetTilesBeforeCompact: 120,
        maxWidgetTilesBeforePainter: 260,
      ),
    DeviceClass.expanded => const AtlasResponsiveConfig(
        canvasPadding: EdgeInsets.all(14),
        tileGap: 4,
        groupHeaderHeight: 24,
        minReadableTileSize: Size(56, 34),
        minInteractiveTileSize: Size(40, 28),
        showLegendExpandedByDefault: true,
        showToolbarMicrocopy: true,
        enableHover: true,
        enableSidePanel: true,
        enableDenseMode: true,
        maxWidgetTilesBeforeCompact: 160,
        maxWidgetTilesBeforePainter: 300,
      ),
    DeviceClass.large => const AtlasResponsiveConfig(
        canvasPadding: EdgeInsets.all(16),
        tileGap: 3,
        groupHeaderHeight: 26,
        minReadableTileSize: Size(52, 32),
        minInteractiveTileSize: Size(36, 26),
        showLegendExpandedByDefault: true,
        showToolbarMicrocopy: true,
        enableHover: true,
        enableSidePanel: true,
        enableDenseMode: true,
        maxWidgetTilesBeforeCompact: 200,
        maxWidgetTilesBeforePainter: 360,
      ),
  };
}
