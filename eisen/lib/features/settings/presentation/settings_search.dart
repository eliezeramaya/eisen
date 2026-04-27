import 'package:flutter/material.dart';

class SettingsSearchDelegate extends SearchDelegate<String?> {
  SettingsSearchDelegate({required this.onJumpTo});
  final void Function(String section) onJumpTo;

  final Map<String, List<String>> _index = const {
    'General': ['language', 'locale', 'time', 'date'],
    'Appearance': ['theme', 'dark', 'minimal', 'contrast'],
    'Layout': [
      'treemap density',
      'airy',
      'balanced',
      'compact',
      'detailed',
      'custom',
      'top-k',
      'gamma',
      'padding',
      'min area',
      'min tile size',
      'treemap',
    ],
    'Accessibility': ['focus', 'screen reader', 'semantics', 'font size'],
    'Keyboard': ['shortcut', 'keybindings', 'hotkeys'],
    'Data & Privacy': ['export', 'import', 'telemetry', 'reset'],
    'About': ['version', 'licenses', 'credits'],
  };

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList();
  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final items = _index.entries
        .expand((e) => e.value
            .where((k) => k.contains(query.toLowerCase()))
            .map((_) => e.key))
        .toSet()
        .toList();
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final section = items[i];
        return ListTile(
          leading: const Icon(Icons.arrow_right),
          title: Text(section),
          onTap: () {
            onJumpTo(section);
            close(context, section);
          },
        );
      },
    );
  }
}
