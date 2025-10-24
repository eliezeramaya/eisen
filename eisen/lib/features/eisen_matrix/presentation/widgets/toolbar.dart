import 'dart:ui';
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

    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface.withOpacity(0.65);
    final border = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.75)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onQuery,
                    style: theme.textTheme.titleMedium,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchHint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (widget.canExitZoom && widget.onExitZoom != null)
                  actionButton(onPressed: widget.onExitZoom, icon: Icons.fullscreen_exit, label: fullViewLabel),
                if (widget.onOpenStats != null)
                  actionButton(onPressed: widget.onOpenStats, icon: Icons.insights, label: statsLabel),
                actionButton(
                  onPressed: widget.onToggleTheme,
                  icon: widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  label: themeLabel,
                ),
                // Minimalista se movió al menú inferior (SettingsSheet)
                if (widget.onOpenSettings != null)
                  actionButton(onPressed: widget.onOpenSettings, icon: Icons.settings, label: settingsLabel),
                if (widget.onOpenProfile != null)
                  actionButton(onPressed: widget.onOpenProfile, icon: Icons.account_circle, label: profileLabel),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
