import 'package:flutter/material.dart';

class AppToolbar extends StatefulWidget {
  final VoidCallback onNew;
  final VoidCallback onToggleTheme;
  final void Function(String) onQuery;
  final VoidCallback onToggleDensity;
  final bool compact;
  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onToggleTheme,
    required this.onQuery,
    required this.onToggleDensity,
    required this.compact,
  });

  @override
  State<AppToolbar> createState() => _AppToolbarState();
}

class _AppToolbarState extends State<AppToolbar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: _controller,
        onChanged: widget.onQuery,
        decoration: const InputDecoration(
          hintText: 'Search or filter by tag…',
          border: InputBorder.none,
        ),
      ),
      actions: [
        IconButton(onPressed: widget.onToggleDensity, tooltip: widget.compact ? 'Comfortable' : 'Compact', icon: const Icon(Icons.density_medium)),
        IconButton(onPressed: widget.onToggleTheme, tooltip: 'Theme', icon: const Icon(Icons.brightness_6)),
        FilledButton.icon(onPressed: widget.onNew, icon: const Icon(Icons.add), label: const Text('New task')),
      ],
    );
  }
}

