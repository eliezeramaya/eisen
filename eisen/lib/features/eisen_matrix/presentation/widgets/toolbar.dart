import 'dart:ui';

import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:eisen/core/responsive/responsive_wrapper.dart';
import 'package:eisen/core/ui/app_text_scale.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class AppToolbar extends StatefulWidget {
  const AppToolbar({
    super.key,
    required this.onToggleTheme,
    required this.onQuery,
    required this.themeMode,
    this.onExitZoom,
    this.canExitZoom = false,
    this.onOpenSettings,
    this.onOpenStats,
    this.onOpenWorkflow,
    this.onOpenProfile,
    this.onToggleMinimal,
    this.minimal = false,
    this.showWorkflowPlan = false,
  });
  final VoidCallback onToggleTheme;
  final void Function(String) onQuery;
  final VoidCallback? onExitZoom;
  final bool canExitZoom;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenStats;
  final VoidCallback? onOpenWorkflow;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onToggleMinimal;
  final bool minimal;
  final ThemeMode themeMode;
  final bool showWorkflowPlan;

  @override
  State<AppToolbar> createState() => _AppToolbarState();
}

class _AppToolbarState extends State<AppToolbar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    // If parent already applies AppTextScale via MediaQuery, this is a no-op; otherwise it ensures consistency
    final prefs = ProviderScope.containerOf(context, listen: false).read(uiPrefsControllerProvider);
    final uiTsf = AppTextScale.of(context, prefs);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final fullViewLabel = isEs ? 'Vista completa' : 'Full view';
    final statsLabel = isEs ? 'Estadísticas' : 'Stats';
    final workflowLabel = isEs ? 'Plan' : 'Workflow';
    final settingsLabel = isEs ? 'Ajustes' : 'Settings';
    final profileLabel = isEs ? 'Mi perfil' : 'My profile';
    final minimalLabel = isEs
        ? (widget.minimal ? 'Normal' : 'Minimalista')
        : (widget.minimal ? 'Normal' : 'Minimal');
    final themeLabel = isEs
        ? (widget.themeMode == ThemeMode.dark ? 'Claro' : 'Oscuro')
        : (widget.themeMode == ThemeMode.dark ? 'Light' : 'Dark');
    final viewLabel = isEs ? 'Vista' : 'View';

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final compactActions = width < 1100; // icons-only when narrow
    final isWide = width >= 600; // show logo + name on wide screens

    Widget actionButton({required VoidCallback? onPressed, required IconData icon, required String label}) {
      return compactActions
          ? IconButton(onPressed: onPressed, tooltip: label, icon: Icon(icon))
          : TextButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
    }

    final theme = Theme.of(context);
  final bg = theme.colorScheme.surface.withValues(alpha: 0.65);
    final border = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm * r.paddingScale,
        (AppSpacing.sm - AppSpacing.xxs / 2) * r.paddingScale,
        AppSpacing.sm * r.paddingScale,
        (AppSpacing.xs * 0.75) * r.paddingScale,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: uiTsf), // AppTextScale applied
            child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: AppSpacing.sm * r.spacingScale),
                // Logo: isotipo solo en compacto, isotipo + nombre en pantallas anchas
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm * r.spacingScale),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (isWide) ...[
                        SizedBox(width: AppSpacing.xs * r.spacingScale),
                        Text(
                          'eisen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Search bar removed: filters are handled via chips in page body
                if (widget.canExitZoom && widget.onExitZoom != null)
                  actionButton(onPressed: widget.onExitZoom, icon: Icons.fullscreen_exit, label: fullViewLabel),
                if (widget.onOpenStats != null)
                  actionButton(onPressed: widget.onOpenStats, icon: Icons.insights, label: statsLabel),
                if (widget.showWorkflowPlan && widget.onOpenWorkflow != null)
                  actionButton(onPressed: widget.onOpenWorkflow, icon: Icons.view_timeline, label: workflowLabel),
                actionButton(
                  onPressed: widget.onToggleTheme,
                  icon: widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  label: themeLabel,
                ),
                // View mode (Treemap/List)
                const _ViewModeMenu(),
                if (widget.onToggleMinimal != null)
                  actionButton(
                    onPressed: widget.onToggleMinimal,
                    icon: widget.minimal ? Icons.visibility : Icons.filter_b_and_w,
                    label: minimalLabel,
                  ),
                if (widget.onOpenSettings != null)
                  actionButton(onPressed: widget.onOpenSettings, icon: Icons.settings, label: settingsLabel),
                if (widget.onOpenProfile != null)
                  actionButton(onPressed: widget.onOpenProfile, icon: Icons.account_circle, label: profileLabel),
                SizedBox(width: AppSpacing.xs * r.spacingScale),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _ViewModeMenu extends ConsumerStatefulWidget {
  const _ViewModeMenu();
  @override
  ConsumerState<_ViewModeMenu> createState() => _ViewModeMenuState();
}

class _ViewModeMenuState extends ConsumerState<_ViewModeMenu> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    final current = prefs.viewMode; // 'treemap' | 'list'
    final width = MediaQuery.sizeOf(context).width;
    final isCompactBar = width < 1100;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final label = isEs ? 'Vista' : 'View';
    final icon = const Icon(Icons.view_agenda_outlined);

    if (isCompactBar) {
      return PopupMenuButton<String>(
        tooltip: label,
        icon: icon,
        initialValue: current,
        onSelected: (v) => ref.read(uiPrefsControllerProvider.notifier).setViewMode(v),
        itemBuilder: (ctx) => _entries(ctx, current),
      );
    }
    return MenuAnchor(
      builder: (ctx, controller, child) => TextButton.icon(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: icon,
        label: Text(label),
      ),
      menuChildren: _menuItems(context, current),
    );
  }

  List<PopupMenuEntry<String>> _entries(BuildContext context, String current) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final treemap = isEs ? 'Treemap' : 'Treemap';
    final list = isEs ? 'Lista' : 'List';
    return [
      CheckedPopupMenuItem(value: 'treemap', checked: current == 'treemap', child: Text(treemap)),
      CheckedPopupMenuItem(value: 'list', checked: current == 'list', child: Text(list)),
    ];
  }

  List<Widget> _menuItems(BuildContext context, String current) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final items = [
      ('treemap', isEs ? 'Treemap' : 'Treemap'),
      ('list', isEs ? 'Lista' : 'List'),
    ];
    return items
        .map(
          (e) => MenuItemButton(
            onPressed: () => ref.read(uiPrefsControllerProvider.notifier).setViewMode(e.$1),
            leadingIcon: current == e.$1 ? const Icon(Icons.check, size: 16) : null,
            child: Text(e.$2),
          ),
        )
        .toList();
  }
}
