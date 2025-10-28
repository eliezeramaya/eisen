import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/settings/presentation/section_bus.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:eisen/features/settings/presentation/settings_search.dart';
import 'package:eisen/features/settings/presentation/live_preview_pane.dart';

class SettingsPageDesktop extends ConsumerStatefulWidget {
  const SettingsPageDesktop({super.key});
  @override
  ConsumerState<SettingsPageDesktop> createState() => _SettingsPageDesktopState();
}

class _SettingsPageDesktopState extends ConsumerState<SettingsPageDesktop> {
  String _section = 'General';
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

  @override
  void initState() {
    super.initState();
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
      _dirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    return SettingsSectionBus(
      jumpTo: (s) => setState(() => _section = s),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(
                context: context,
                delegate: SettingsSearchDelegate(onJumpTo: (s) => setState(() => _section = s)),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            Container(
              width: 240,
              color: cs.surfaceContainerHigh,
              child: _SettingsSidebar(selected: _section, onSelect: (s) => setState(() => _section = s)),
            ),
            Container(width: 1, color: cs.outlineVariant.withValues(alpha: 0.28)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SettingsContent(
                  section: _section,
                  onDirty: (v) => setState(() => _dirty = _dirty || v),
                  themeMode: _stagedTheme,
                  compact: _stagedCompact,
                  minimal: _stagedMinimal,
                  showAxisLegends: _stagedAxis,
                  onThemeChanged: (m) => setState(() => _stagedTheme = m),
                  onCompactChanged: (v) => setState(() => _stagedCompact = v),
                  onMinimalChanged: (v) => setState(() => _stagedMinimal = v),
                  onAxisLegendsChanged: (v) => setState(() => _stagedAxis = v),
                  topK: _stagedTopK,
                  gamma: _stagedGamma,
                  minAreaNormalized: _stagedMinArea,
                  quadrantPadding: _stagedPadding,
                  onTopKChanged: (v) => setState(() => _stagedTopK = v),
                  onGammaChanged: (v) => setState(() => _stagedGamma = v),
                  onMinAreaChanged: (v) => setState(() => _stagedMinArea = v),
                  onPaddingChanged: (v) => setState(() => _stagedPadding = v),
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
                  onGanttCompactLanesChanged: (v) => setState(() => _stagedGanttCompact = v),
                  onGanttWorkweekOnlyChanged: (v) => setState(() => _stagedGanttWorkweek = v),
                  onGanttShowTodayLineChanged: (v) => setState(() => _stagedGanttToday = v),
                ),
              ),
            ),
            if (wide) ...[
              const VerticalDivider(width: 1),
              SizedBox(
                width: 320,
                child: LivePreviewPane(
                  enabled: _previewEnabled,
                  topK: _stagedTopK,
                  gamma: _stagedGamma,
                  minArea: _stagedMinArea,
                  qPad: _stagedPadding,
                ),
              ),
            ],
          ],
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

  void _applyChanges() {
    // Apply staged values to providers and persist
    final ctrl = ref.read(matrixControllerProvider.notifier);
    // ThemeMode: cycle toggle until desired (max 3 steps)
    int guard = 0;
    while (ref.read(matrixControllerProvider).themeMode != _stagedTheme && guard < 3) {
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
        )
        .then((_) => uiCtl.applyGanttPrefs(
              timeScale: _stagedGanttScale,
              showBadges: _stagedGanttBadges,
              compactLanes: _stagedGanttCompact,
              workweekOnly: _stagedGanttWorkweek,
              showTodayLine: _stagedGanttToday,
            ))
        .whenComplete(() {
      ref.read(matrixControllerProvider.notifier).notifyLayoutRecompute();
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
        // No originals stored for Gantt yet; not used in Cancel
      });
      ScaffoldMessenger.of(context).showSnackBar(
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
      _dirty = false;
    });
  }

  void _resetToDefaults() {
    setState(() {
      _stagedTheme = ThemeMode.system;
      _stagedCompact = false;
      _stagedMinimal = false;
      _stagedAxis = true;
      _stagedTopK = const UiPrefsData().topKPerQuadrant;
      _stagedGamma = const UiPrefsData().gamma;
      _stagedMinArea = const UiPrefsData().minAreaNormalized;
      _stagedPadding = const UiPrefsData().quadrantPadding;
      _dirty = true;
    });
  }
}

class _SettingsSidebar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _SettingsSidebar({super.key, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData)>[
      ('General', Icons.tune),
      ('Appearance', Icons.palette_outlined),
      ('Layout', Icons.grid_view_rounded),
      ('Calendar/Gantt', Icons.view_timeline),
      ('Accessibility', Icons.accessibility_new),
      ('Keyboard', Icons.keyboard_alt_outlined),
      ('Data & Privacy', Icons.privacy_tip_outlined),
      ('About', Icons.info_outline),
    ];
    return SizedBox(
      width: 240,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemBuilder: (_, i) {
          final (label, icon) = items[i];
          final sel = label == selected;
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            selected: sel,
            selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            onTap: () => onSelect(label),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: items.length,
      ),
    );
  }
}
