import 'package:flutter/material.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class AppToolbar extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final void Function(String) onQuery;
  final VoidCallback? onExitZoom;
  final bool canExitZoom;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenStats;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onToggleMinimal;
  final bool minimal;
  final ThemeMode themeMode;
  const AppToolbar({
    super.key,
    required this.onToggleTheme,
    required this.onQuery,
    required this.themeMode,
    this.onExitZoom,
    this.canExitZoom = false,
    this.onOpenSettings,
    this.onOpenStats,
    this.onOpenProfile,
    this.onToggleMinimal,
    this.minimal = false,
  });

  @override
  State<AppToolbar> createState() => _AppToolbarState();
}

class _AppToolbarState extends State<AppToolbar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final fullViewLabel = isEs ? 'Vista completa' : 'Full view';
    final statsLabel = isEs ? 'Estadísticas' : 'Stats';
    final settingsLabel = isEs ? 'Ajustes' : 'Settings';
    final profileLabel = isEs ? 'Mi perfil' : 'My profile';
    final themeLabel = isEs
        ? (widget.themeMode == ThemeMode.dark ? 'Claro' : 'Oscuro')
        : (widget.themeMode == ThemeMode.dark ? 'Light' : 'Dark');
    final minimalLabel = isEs ? 'Minimalista' : 'Minimal';

    final width = MediaQuery.of(context).size.width;
    final compactActions = width < 1100; // icons-only when narrow

    Widget actionButton({required VoidCallback? onPressed, required IconData icon, required String label}) {
      return compactActions
          ? IconButton(onPressed: onPressed, tooltip: label, icon: Icon(icon))
          : TextButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
    }

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
        if (widget.canExitZoom && widget.onExitZoom != null)
          actionButton(onPressed: widget.onExitZoom, icon: Icons.fullscreen_exit, label: fullViewLabel),
        if (widget.onOpenStats != null)
          actionButton(onPressed: widget.onOpenStats, icon: Icons.insights, label: statsLabel),
        actionButton(
          onPressed: widget.onToggleTheme,
          icon: widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
          label: themeLabel,
        ),
        if (widget.onToggleMinimal != null)
          actionButton(onPressed: widget.onToggleMinimal, icon: Icons.filter_b_and_w, label: minimalLabel),
        if (widget.onOpenSettings != null)
          actionButton(onPressed: widget.onOpenSettings, icon: Icons.settings, label: settingsLabel),
        if (widget.onOpenProfile != null)
          actionButton(onPressed: widget.onOpenProfile, icon: Icons.account_circle, label: profileLabel),
      ],
    );
  }
}
