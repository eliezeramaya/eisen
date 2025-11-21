import 'package:flutter/material.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';

class AppToolbar extends StatefulWidget {
  const AppToolbar({
    super.key,
    required this.onToggleTheme,
    required this.onQuery,
    required this.themeMode,
    required this.isSearchOpen,
    required this.searchQuery,
    required this.onToggleSearch,
    this.onExitZoom,
    this.canExitZoom = false,
    this.onOpenSettings,
    this.onOpenStats,
    this.onOpenWorkflow,
    this.onOpenProfile,
    this.onToggleMinimal,
    this.onOpenCompletedTasks,
    this.onOpenSpaces,
    this.onOpenFocus,
    this.minimal = false,
    this.showWorkflowPlan = false,
  });
  final VoidCallback onToggleTheme;
  final void Function(String) onQuery;
  final bool isSearchOpen;
  final String searchQuery;
  final VoidCallback onToggleSearch;
  final VoidCallback? onExitZoom;
  final bool canExitZoom;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenStats;
  final VoidCallback? onOpenWorkflow;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onToggleMinimal;
  final VoidCallback? onOpenCompletedTasks;
  final VoidCallback? onOpenSpaces;
  final VoidCallback? onOpenFocus;
  final bool minimal;
  final ThemeMode themeMode;
  final bool showWorkflowPlan;

  @override
  State<AppToolbar> createState() => _AppToolbarState();
}

class _AppToolbarState extends State<AppToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AppToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setThemeMode(ThemeMode target) {
    var current = widget.themeMode;
    var steps = 0;
    while (current != target && steps < 3) {
      switch (current) {
        case ThemeMode.system:
          current = ThemeMode.light;
          break;
        case ThemeMode.light:
          current = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          current = ThemeMode.system;
          break;
      }
      steps++;
    }
    for (var i = 0; i < steps; i++) {
      widget.onToggleTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final searchLabel = isEs ? 'Buscar' : 'Search';
    final statsLabel = isEs ? 'Stats' : 'Stats';
    final workflowLabel = isEs ? 'Workflow' : 'Workflow';
    final focusLabel = isEs ? 'Focus' : 'Focus';
    final settingsLabel = isEs ? 'Ajustes' : 'Settings';
    final profileLabel = isEs ? 'Perfil' : 'Profile';
    final completedLabel = isEs ? 'Completed' : 'Completed';
    final themeLabel = isEs ? 'Tema' : 'Theme';

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
              Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
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
      // SafeArea already applies top padding in the Scaffold's appBar,
      // so we keep this zero to avoid double insets and overflow.
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 70,
            child: isMobile
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Col 0: Settings (antes Search; alineado con Stats inferior)
                        if (widget.onOpenSettings != null)
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 5,
                            child: Center(
                              child: actionButton(
                                onPressed: widget.onOpenSettings,
                                icon: Icons.settings,
                                label: settingsLabel,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 5,
                            child: Center(
                              child: actionButton(
                                onPressed: widget.onToggleSearch,
                                icon: Icons.search,
                                label: searchLabel,
                              ),
                            ),
                          ),
                        // Col 1: Tema (alineado con Completed inferior)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 5,
                          child: Center(
                            child: _ThemeMenuButton(
                              label: themeLabel,
                              themeMode: widget.themeMode,
                              onSelect: _setThemeMode,
                            ),
                          ),
                        ),
                        // Col 2: logo de la app (alineado con FAB central inferior)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 5,
                          child: const Center(
                            child: AppLogoHomeButton(),
                          ),
                        ),
                        // Col 3: Search (antes Settings; alineado con Workflow inferior)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 5,
                          child: Center(
                            child: actionButton(
                              onPressed: widget.onToggleSearch,
                              icon: Icons.search,
                              label: searchLabel,
                            ),
                          ),
                        ),
                        // Col 4: Profile (alineado con Settings inferior)
                        if (widget.onOpenProfile != null)
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 5,
                            child: Center(
                              child: actionButton(
                                onPressed: widget.onOpenProfile,
                                icon: Icons.account_circle,
                                label: profileLabel,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Settings button (antes Search; advanced settings)
                        if (widget.onOpenSettings != null)
                          actionButton(
                            onPressed: widget.onOpenSettings,
                            icon: Icons.settings,
                            label: settingsLabel,
                          ),
                        if (widget.onOpenStats != null)
                          actionButton(
                            onPressed: widget.onOpenStats,
                            icon: Icons.bar_chart_rounded,
                            label: statsLabel,
                          ),
                        if (widget.onOpenFocus != null)
                          actionButton(
                            onPressed: widget.onOpenFocus,
                            icon: Icons.bolt,
                            label: focusLabel,
                          ),
                        if (widget.onOpenCompletedTasks != null)
                          actionButton(
                            onPressed: widget.onOpenCompletedTasks,
                            icon: Icons.history,
                            label: completedLabel,
                          ),
                        _ThemeMenuButton(
                          label: themeLabel,
                          themeMode: widget.themeMode,
                          onSelect: _setThemeMode,
                        ),
                        if (widget.showWorkflowPlan &&
                            widget.onOpenWorkflow != null)
                          actionButton(
                            onPressed: widget.onOpenWorkflow,
                            icon: Icons.view_timeline,
                            label: workflowLabel,
                          ),
                        if (widget.onOpenProfile != null)
                          actionButton(
                            onPressed: widget.onOpenProfile,
                            icon: Icons.account_circle,
                            label: profileLabel,
                          ),
                        // Search button (advanced search) moved al final
                        actionButton(
                          onPressed: widget.onToggleSearch,
                          icon: Icons.search,
                          label: searchLabel,
                        ),
                      ],
                    ),
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isSearchOpen
                ? _SearchBar(
                    controller: _searchController,
                    onChanged: widget.onQuery,
                    onClose: () {
                      _searchController.clear();
                      widget.onQuery('');
                      widget.onToggleSearch();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ThemeMenuButton extends StatelessWidget {
  const _ThemeMenuButton({
    required this.label,
    required this.themeMode,
    required this.onSelect,
  });

  final String label;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final icon = switch (themeMode) {
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.system => Icons.brightness_4_outlined,
    };

    return PopupMenuButton<ThemeMode>(
      onSelected: onSelect,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text(isEs ? 'Sistema' : 'System'),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text(isEs ? 'Claro' : 'Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text(isEs ? 'Oscuro' : 'Dark'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
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
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final hint = isEs ? 'Buscar tareas…' : 'Search tasks…';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
