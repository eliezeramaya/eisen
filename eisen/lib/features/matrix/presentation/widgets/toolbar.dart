import 'package:flutter/material.dart';
import 'package:eisen/l10n/app_localizations.dart';

class AppToolbar extends StatefulWidget {
  final VoidCallback onNew;
  final VoidCallback onToggleTheme;
  final void Function(String) onQuery;
  final VoidCallback onToggleDensity;
  final bool compact;
  final VoidCallback? onEdit;
  final bool canEdit;
  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onToggleTheme,
    required this.onQuery,
    required this.onToggleDensity,
    required this.compact,
    this.onEdit,
    this.canEdit = false,
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
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchHint,
          border: InputBorder.none,
        ),
      ),
      actions: [
        IconButton(
          onPressed: widget.canEdit ? widget.onEdit : null,
          tooltip: 'Edit',
          icon: const Icon(Icons.edit),
        ),
        IconButton(onPressed: widget.onToggleDensity, tooltip: widget.compact ? 'Comfortable' : 'Compact', icon: const Icon(Icons.density_medium)),
        IconButton(onPressed: widget.onToggleTheme, tooltip: 'Theme', icon: const Icon(Icons.brightness_6)),
        FilledButton.icon(onPressed: widget.onNew, icon: const Icon(Icons.add), label: Text(AppLocalizations.of(context).newTask)),
      ],
    );
  }
}
