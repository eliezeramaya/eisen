import 'package:flutter/material.dart';
import 'package:eisen/features/settings/presentation/section_bus.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:eisen/features/settings/presentation/settings_search.dart';

class SettingsPageDesktop extends StatefulWidget {
  const SettingsPageDesktop({super.key});
  @override
  State<SettingsPageDesktop> createState() => _SettingsPageDesktopState();
}

class _SettingsPageDesktopState extends State<SettingsPageDesktop> {
  String _section = 'General';
  bool _dirty = false;

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
            const _SettingsSidebar(),
            const VerticalDivider(width: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SettingsContent(
                  section: _section,
                  onDirty: (v) => setState(() => _dirty = _dirty || v),
                ),
              ),
            ),
            if (wide) ...[
              const VerticalDivider(width: 1),
              const SizedBox(width: 320, child: LivePreviewPane()),
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
    // TODO: Persist preferences and notify providers
    setState(() => _dirty = false);
  }

  void _cancelChanges() {
    // TODO: Reload initial state and discard cached changes
    setState(() => _dirty = false);
  }

  void _resetToDefaults() {
    // TODO: Set defaults and mark as dirty
    setState(() => _dirty = true);
  }
}

class _SettingsSidebar extends StatefulWidget {
  const _SettingsSidebar();
  @override
  State<_SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<_SettingsSidebar> {
  String _selected = 'General';
  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData)>[
      ('General', Icons.tune),
      ('Appearance', Icons.palette_outlined),
      ('Layout', Icons.grid_view_rounded),
      ('Accessibility', Icons.accessibility_new),
      ('Keyboard', Icons.keyboard_alt_outlined),
      ('Data & Privacy', Icons.privacy_tip_outlined),
      ('About', Icons.info_outline),
    ];
    return SizedBox(
      width: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemBuilder: (_, i) {
          final (label, icon) = items[i];
          final sel = label == _selected;
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            selected: sel,
            selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            onTap: () {
              setState(() => _selected = label);
              SettingsSectionBus.of(context).jumpTo(label);
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: items.length,
      ),
    );
  }
}

