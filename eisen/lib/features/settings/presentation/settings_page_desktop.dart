import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/treemap_density_resolver.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/settings/application/appearance_preview_controller.dart';
import 'package:eisen/features/settings/application/settings_controller.dart';
import 'package:eisen/features/settings/presentation/live_preview_pane.dart';
import 'package:eisen/features/settings/presentation/section_bus.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPageDesktop extends ConsumerStatefulWidget {
  const SettingsPageDesktop({
    super.key,
    this.initialSection = 'General',
    this.useShellNavigation = false,
  });

  final String initialSection;
  final bool useShellNavigation;
  @override
  ConsumerState<SettingsPageDesktop> createState() =>
      _SettingsPageDesktopState();
}

class _SettingsPageDesktopState extends ConsumerState<SettingsPageDesktop> {
  late String _section;
  bool _dirty = false;
  bool _previewEnabled = false;
  // Staged values - initialized with defaults, will be updated from providers
  ThemeMode _stagedTheme = ThemeMode.system;
  bool _stagedCompact = false;
  bool _stagedMinimal = false;
  bool _stagedAxis = true;
  int _stagedTopK = 20;
  double _stagedGamma = 1.0;
  double _stagedMinArea = 0.00004;
  double _stagedPadding = 0.012;
  double _stagedMinTileSize = 44.0;
  String _stagedDensity = 'auto'; // 'auto' | 'comfy' | 'compact' | 'ultra'
  String _stagedTreemapDensityProfile = 'balanced';
  // Staged Gantt values
  String _stagedGanttScale = 'weeks';
  bool _stagedGanttBadges = true;
  bool _stagedGanttCompact = false;
  bool _stagedGanttWorkweek = false;
  bool _stagedGanttToday = true;

  // Original snapshot for rollback
  ThemeMode? _origTheme;
  bool? _origCompact;
  bool? _origMinimal;
  bool? _origAxis;
  int? _origTopK;
  double? _origGamma;
  double? _origMinArea;
  double? _origPadding;
  double? _origMinTileSize;
  String? _origDensity;
  String? _origTreemapDensityProfile;

  @override
  void initState() {
    super.initState();
    _section = _normalizeSection(widget.initialSection);
    // Initialize from providers after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProviders());
  }

  void _loadFromProviders() {
    final ms = ref.read(matrixControllerProvider);
    final ui = ref.read(uiPrefsControllerProvider);
    setState(() {
      _stagedTheme = ms.themeMode;
      _stagedCompact = ms.compact;
      _stagedMinimal = ms.minimal;
      _stagedAxis = ms.showAxisLegends;
      _stagedTopK = ui.topKPerQuadrant;
      _stagedGamma = ui.gamma;
      _stagedMinArea = ui.minAreaNormalized;
      _stagedPadding = ui.quadrantPadding;
      _stagedMinTileSize = ui.minTileSizePx;
      _stagedDensity = ui.densityPreset;
      _stagedTreemapDensityProfile = ui.treemapDensityProfile;
      // Gantt prefs
      _stagedGanttScale = ui.ganttTimeScale;
      _stagedGanttBadges = ui.ganttShowBadges;
      _stagedGanttCompact = ui.ganttCompactLanes;
      _stagedGanttWorkweek = ui.ganttWorkweekOnly;
      _stagedGanttToday = ui.ganttShowTodayLine;
      // Save originals
      _origTheme = _stagedTheme;
      _origCompact = _stagedCompact;
      _origMinimal = _stagedMinimal;
      _origAxis = _stagedAxis;
      _origTopK = _stagedTopK;
      _origGamma = _stagedGamma;
      _origMinArea = _stagedMinArea;
      _origPadding = _stagedPadding;
      _origMinTileSize = _stagedMinTileSize;
      _origDensity = _stagedDensity;
      _origTreemapDensityProfile = _stagedTreemapDensityProfile;
      _dirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final deviceClass = deviceClassOf(size.width);
    final isWide = deviceClass.isLarge;
    final isNarrow = !deviceClass.isExpandedUp;
    return SettingsSectionBus(
      jumpTo: (s) => setState(() => _section = s),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.useShellNavigation,
          leadingWidth: widget.useShellNavigation ? null : 72,
          leading: widget.useShellNavigation
              ? null
              : const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: AppLogoHomeButton(),
                ),
          title: Text('Settings · $_section'),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0.5,
        ),
        body: SafeArea(
          top: false,
          child: isNarrow
              // Mobile/narrow: categorías arriba, contenido apilado debajo.
              ? Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: _SettingsSidebar(
                        selected: _section,
                        onSelect: (s) =>
                            setState(() => _section = _normalizeSection(s)),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.28),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: _buildAnimatedContent(),
                      ),
                    ),
                  ],
                )
              // Desktop/wide: sidebar + panel maestro-detalle.
              : Row(
                  children: [
                    Container(
                      width: 240,
                      color: cs.surfaceContainerHigh,
                      child: _SettingsSidebar(
                          selected: _section,
                          onSelect: (s) =>
                              setState(() => _section = _normalizeSection(s))),
                    ),
                    Container(
                        width: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.28)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: _buildAnimatedContent(),
                      ),
                    ),
                    if (isWide) ...[
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 320,
                        child: LivePreviewPane(
                          enabled: _previewEnabled,
                          screenSize: size,
                          treemapDensityProfile: _stagedTreemapDensityProfile,
                          topK: _stagedTopK,
                          gamma: _stagedGamma,
                          minArea: _stagedMinArea,
                          qPad: _stagedPadding,
                          minTileSizePx: _stagedMinTileSize,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Reset to defaults',
                  child: TextButton(
                    onPressed: _dirty ? _resetToDefaults : null,
                    child: const Text('Reset to defaults'),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Cancel changes',
                  child: OutlinedButton(
                    onPressed: _dirty ? _cancelChanges : null,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Apply changes',
                  child: FilledButton(
                    onPressed: _dirty ? _applyChanges : null,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeSection(String value) {
    const allowed = <String>{
      'General',
      'Appearance',
      'Layout',
      'Calendar/Gantt',
      'Smart Classification',
      'Notifications',
      'Language',
      'Accessibility',
      'Keyboard',
      'Data & Privacy',
      'About',
    };
    if (allowed.contains(value)) return value;
    return 'General';
  }

  void _applyChanges() {
    final messenger = ScaffoldMessenger.of(context);
    // Apply staged values to providers and persist
    final ctrl = ref.read(matrixControllerProvider.notifier);
    // ThemeMode: cycle toggle until desired (max 3 steps)
    int guard = 0;
    while (ref.read(matrixControllerProvider).themeMode != _stagedTheme &&
        guard < 3) {
      ctrl.toggleTheme();
      guard++;
    }
    // Booleans
    final current = ref.read(matrixControllerProvider);
    if (current.compact != _stagedCompact) ctrl.toggleCompact();
    if (current.minimal != _stagedMinimal) ctrl.toggleMinimal();
    if (current.showAxisLegends != _stagedAxis) ctrl.toggleAxisLegends();

    final uiCtl = ref.read(uiPrefsControllerProvider.notifier);
    uiCtl
        .applyLayoutPrefs(
          topKPerQuadrant: _stagedTopK,
          gamma: _stagedGamma,
          minAreaNormalized: _stagedMinArea,
          quadrantPadding: _stagedPadding,
          minTileSizePx: _stagedMinTileSize,
          treemapDensityProfile: _stagedTreemapDensityProfile,
          isDesktop: deviceClassFromContext(context).isExpandedUp,
        )
        .then((_) => uiCtl.setDensityPreset(_stagedDensity))
        .then((_) => uiCtl.applyGanttPrefs(
              timeScale: _stagedGanttScale,
              showBadges: _stagedGanttBadges,
              compactLanes: _stagedGanttCompact,
              workweekOnly: _stagedGanttWorkweek,
              showTodayLine: _stagedGanttToday,
            ))
        .whenComplete(() {
      ref.read(matrixControllerProvider.notifier).notifyLayoutRecompute();
      // Keep SettingsController in sync with the latest persisted UiPrefs.
      ref.read(settingsControllerProvider.notifier).applyChanges();
      setState(() {
        _dirty = false;
        // Refresh originals to current staged (now applied)
        _origTheme = _stagedTheme;
        _origCompact = _stagedCompact;
        _origMinimal = _stagedMinimal;
        _origAxis = _stagedAxis;
        _origTopK = _stagedTopK;
        _origGamma = _stagedGamma;
        _origMinArea = _stagedMinArea;
        _origPadding = _stagedPadding;
        _origMinTileSize = _stagedMinTileSize;
        _origDensity = _stagedDensity;
        _origTreemapDensityProfile = _stagedTreemapDensityProfile;
        // No originals stored for Gantt yet; not used in Cancel
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings applied')),
      );
    });
  }

  void _cancelChanges() {
    setState(() {
      // Rollback to original snapshot
      _stagedTheme = _origTheme ?? ThemeMode.system;
      _stagedCompact = _origCompact ?? false;
      _stagedMinimal = _origMinimal ?? false;
      _stagedAxis = _origAxis ?? true;
      _stagedTopK = _origTopK ?? 20;
      _stagedGamma = _origGamma ?? 1.0;
      _stagedMinArea = _origMinArea ?? 0.00004;
      _stagedPadding = _origPadding ?? 0.012;
      _stagedMinTileSize = _origMinTileSize ?? 44.0;
      _stagedDensity = _origDensity ?? 'auto';
      _stagedTreemapDensityProfile = _origTreemapDensityProfile ?? 'balanced';
      _dirty = false;
    });
    // Re-synchronize settings preview and domain controller with persisted prefs.
    ref.read(appearancePreviewProvider.notifier).resetFromPrefs();
    ref.read(settingsControllerProvider.notifier).reload();
  }

  void _resetToDefaults() {
    final defaults =
        ref.read(settingsControllerProvider.notifier).resetToDefaultsDraft();
    setState(() {
      _stagedTheme = defaults.themeMode;
      _stagedCompact = defaults.compact;
      _stagedMinimal = defaults.minimal;
      _stagedAxis = defaults.showAxisLegends;
      _stagedTopK = defaults.topKPerQuadrant;
      _stagedGamma = defaults.gamma;
      _stagedMinArea = defaults.minAreaNormalized;
      _stagedPadding = defaults.quadrantPadding;
      _stagedMinTileSize = defaults.minTileSizePx;
      _stagedDensity = defaults.densityPreset;
      _stagedTreemapDensityProfile = defaults.treemapDensityProfile;
      _dirty = true;
    });
  }

  Widget _buildAnimatedContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(_section),
        child: _buildSettingsContent(),
      ),
    );
  }

  SettingsContent _buildSettingsContent() {
    return SettingsContent(
      section: _section,
      onDirty: (v) => setState(() => _dirty = _dirty || v),
      themeMode: _stagedTheme,
      compact: _stagedCompact,
      minimal: _stagedMinimal,
      showAxisLegends: _stagedAxis,
      densityPreset: _stagedDensity,
      treemapDensityProfile: _stagedTreemapDensityProfile,
      onThemeChanged: (m) => setState(() => _stagedTheme = m),
      onCompactChanged: (v) => setState(() => _stagedCompact = v),
      onMinimalChanged: (v) => setState(() => _stagedMinimal = v),
      onAxisLegendsChanged: (v) => setState(() => _stagedAxis = v),
      onDensityPresetChanged: (v) => setState(() => _stagedDensity = v),
      topK: _stagedTopK,
      gamma: _stagedGamma,
      minAreaNormalized: _stagedMinArea,
      quadrantPadding: _stagedPadding,
      minTileSizePx: _stagedMinTileSize,
      onTopKChanged: (v) => setState(() => _stagedTopK = v),
      onGammaChanged: (v) => setState(() => _stagedGamma = v),
      onMinAreaChanged: (v) => setState(() => _stagedMinArea = v),
      onPaddingChanged: (v) => setState(() => _stagedPadding = v),
      onTreemapDensityProfileChanged: (v) => setState(() {
        _stagedTreemapDensityProfile = v;
        if (v != 'custom') {
          final simulated = ref.read(uiPrefsProvider).copyWith(
                topKPerQuadrant: _stagedTopK,
                gamma: _stagedGamma,
                minAreaNormalized: _stagedMinArea,
                quadrantPadding: _stagedPadding,
                minTileSizePx: _stagedMinTileSize,
                treemapDensityProfile: v,
              );
          final resolvedForSelection = TreemapDensityResolver.resolve(
            prefs: simulated,
            screenSize: MediaQuery.sizeOf(context),
          );
          _stagedTopK = resolvedForSelection.topKPerQuadrant;
          _stagedMinArea = resolvedForSelection.minAreaNormalized;
          _stagedPadding = resolvedForSelection.quadrantPadding;
          _stagedMinTileSize = resolvedForSelection.minTileSizePx;
        }
      }),
      onMinTileSizeChanged: (v) => setState(() => _stagedMinTileSize = v),
      previewEnabled: _previewEnabled,
      onPreviewChanged: (v) => setState(() => _previewEnabled = v),
      // Gantt staged
      ganttTimeScale: _stagedGanttScale,
      ganttShowBadges: _stagedGanttBadges,
      ganttCompactLanes: _stagedGanttCompact,
      ganttWorkweekOnly: _stagedGanttWorkweek,
      ganttShowTodayLine: _stagedGanttToday,
      onGanttTimeScaleChanged: (v) => setState(() => _stagedGanttScale = v),
      onGanttShowBadgesChanged: (v) => setState(() => _stagedGanttBadges = v),
      onGanttCompactLanesChanged: (v) =>
          setState(() => _stagedGanttCompact = v),
      onGanttWorkweekOnlyChanged: (v) =>
          setState(() => _stagedGanttWorkweek = v),
      onGanttShowTodayLineChanged: (v) => setState(() => _stagedGanttToday = v),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData)>[
      ('General', Icons.tune),
      ('Appearance', Icons.palette_outlined),
      ('Notifications', Icons.notifications_none),
      ('Language', Icons.language),
      ('Layout', Icons.grid_view_rounded),
      ('Calendar/Gantt', Icons.view_timeline),
      ('Smart Classification', Icons.auto_awesome_outlined),
      ('Accessibility', Icons.accessibility_new),
      ('Keyboard', Icons.keyboard_alt_outlined),
      ('Data & Privacy', Icons.privacy_tip_outlined),
      ('About', Icons.info_outline),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemBuilder: (_, i) {
        final (label, icon) = items[i];
        final sel = label == selected;
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          selected: sel,
          selectedTileColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          onTap: () {
            if (label == 'Smart Classification') {
              GoRouter.of(context).push('/classification-settings');
              return;
            }
            onSelect(label);
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemCount: items.length,
    );
  }
}
