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
    this.onOpenCompletedTasks,
    this.onOpenSpaces,
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
  final VoidCallback? onOpenCompletedTasks;
  final VoidCallback? onOpenSpaces;
  final bool minimal;
  final ThemeMode themeMode;
  final bool showWorkflowPlan;

  @override
  State<AppToolbar> createState() => _AppToolbarState();
}

class _AppToolbarState extends State<AppToolbar> {
  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final statsLabel = isEs ? 'Stats' : 'Stats';
    final workflowLabel = isEs ? 'Workflow' : 'Workflow';
    final settingsLabel = isEs ? 'Ajustes' : 'Settings';
    final profileLabel = isEs ? 'Perfil' : 'Profile';
    final completedLabel = isEs ? 'Completed' : 'Completed';
    final viewLabel = isEs ? 'Vista' : 'View';

    Widget actionButton({
      required VoidCallback? onPressed,
      required IconData icon,
      required String label,
    }) {
      final colorScheme = Theme.of(context).colorScheme;
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.onOpenStats != null)
              actionButton(
                onPressed: widget.onOpenStats,
                icon: Icons.bar_chart_rounded,
                label: statsLabel,
              ),
            if (widget.onOpenCompletedTasks != null)
              actionButton(
                onPressed: widget.onOpenCompletedTasks,
                icon: Icons.history,
                label: completedLabel,
              ),
            actionButton(
              onPressed: widget.onToggleMinimal ?? () {},
              icon: Icons.visibility_outlined,
              label: viewLabel,
            ),
            if (widget.showWorkflowPlan && widget.onOpenWorkflow != null)
              actionButton(
                onPressed: widget.onOpenWorkflow,
                icon: Icons.view_timeline,
                label: workflowLabel,
              ),
            if (widget.onOpenSettings != null)
              actionButton(
                onPressed: widget.onOpenSettings,
                icon: Icons.settings,
                label: settingsLabel,
              ),
            if (widget.onOpenProfile != null)
              actionButton(
                onPressed: widget.onOpenProfile,
                icon: Icons.account_circle,
                label: profileLabel,
              ),
          ],
        ),
      ),
    );
  }
}
