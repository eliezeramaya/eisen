import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';

class AppToolbar extends StatefulWidget {
  const AppToolbar({
    super.key,
    this.onToggleTheme,
    required this.onQuery,
    this.themeMode = ThemeMode.system,
    required this.isSearchOpen,
    required this.searchQuery,
    required this.onToggleSearch,
    this.onExitZoom,
    this.canExitZoom = false,
    this.onOpenSettings,
    this.onOpenStats,
    this.onOpenWorkflow,
    this.onOpenProfile,
    this.onOpenContextTasks,
    this.onToggleMinimal,
    this.onOpenCompletedTasks,
    this.onOpenSpaces,
    this.onOpenFocus,
    this.onToggleViewMode,
    this.taskViewModeSwitch,
    this.viewMode = 'treemap',
    this.showViewModeToggle = false,
    this.minimal = false,
    this.showWorkflowPlan = false,
    this.onOpenAtlas,
  });
  final VoidCallback? onToggleTheme;
  final VoidCallback? onOpenAtlas;
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
  final VoidCallback? onOpenContextTasks;
  final VoidCallback? onToggleMinimal;
  final VoidCallback? onOpenCompletedTasks;
  final VoidCallback? onOpenSpaces;
  final VoidCallback? onOpenFocus;
  final VoidCallback? onToggleViewMode;
  final Widget? taskViewModeSwitch;
  final String viewMode; // 'treemap' | 'list'
  final bool showViewModeToggle; // Show toggle on desktop (≥1240px)
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

  @override
  Widget build(BuildContext context) {
    final isMobile = deviceClassFromContext(context).isCompact;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final searchLabel = isEs ? 'Buscar' : 'Search';
    final statsLabel = isEs ? 'Stats' : 'Stats';
    final workflowLabel = isEs ? 'Workflow' : 'Workflow';
    final focusLabel = isEs ? 'Focus' : 'Focus';
    final contextLabel = isEs ? 'Contexto' : 'Context';
    final settingsLabel = isEs ? 'Ajustes' : 'Settings';
    final profileLabel = isEs ? 'Perfil' : 'Profile';
    final completedLabel = isEs ? 'Completed' : 'Completed';
    final atlasLabel = isEs ? 'Atlas' : 'Atlas';
    final backLabel = isEs ? 'Volver' : 'Back';
    final viewLabel = widget.viewMode == 'list'
        ? (isEs ? 'Lista' : 'List')
        : (isEs ? 'Matriz' : 'Matrix');
    final viewIcon = widget.viewMode == 'list'
        ? Icons.view_list_rounded
        : Icons.grid_view_rounded;

    Widget actionButton({
      Key? key,
      bool expand = false,
      required VoidCallback? onPressed,
      required IconData icon,
      required String label,
    }) {
      final colorScheme = Theme.of(context).colorScheme;
      final content = Container(
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
      );

      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: key,
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: expand
                  ? SizedBox.expand(child: Center(child: content))
                  : content,
            ),
          ),
        ),
      );
    }

    Widget mobileSlot({
      required Widget child,
    }) {
      return SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: child,
      );
    }

    Widget mobileCenteredAction({
      Key? key,
      required VoidCallback? onPressed,
      required IconData icon,
      required String label,
    }) {
      return mobileSlot(
        child: actionButton(
          key: key,
          expand: true,
          onPressed: onPressed,
          icon: icon,
          label: label,
        ),
      );
    }

    Widget mobileSettingsOrBackSlot() {
      if (widget.canExitZoom && widget.onExitZoom != null) {
        return mobileCenteredAction(
          key: const Key('toolbar-back-button'),
          onPressed: widget.onExitZoom,
          icon: Icons.arrow_back_rounded,
          label: backLabel,
        );
      }

      if (widget.onOpenSettings != null) {
        return mobileCenteredAction(
          onPressed: widget.onOpenSettings,
          icon: Icons.settings,
          label: settingsLabel,
        );
      }

      return mobileCenteredAction(
        onPressed: widget.onToggleSearch,
        icon: Icons.search,
        label: searchLabel,
      );
    }

    Widget desktopBackAction() {
      if (!widget.canExitZoom || widget.onExitZoom == null) {
        return const SizedBox.shrink();
      }

      return actionButton(
        key: const Key('toolbar-back-button'),
        onPressed: widget.onExitZoom,
        icon: Icons.arrow_back_rounded,
        label: backLabel,
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
                        mobileSettingsOrBackSlot(),
                        mobileCenteredAction(
                          onPressed: widget.onOpenAtlas,
                          icon: Icons.map_outlined,
                          label: atlasLabel,
                        ),
                        mobileSlot(
                          child: const AppLogoHomeButton(
                            key: Key('toolbar-home-button'),
                          ),
                        ),
                        mobileCenteredAction(
                          onPressed: widget.onOpenContextTasks ??
                              widget.onToggleSearch,
                          icon: widget.onOpenContextTasks != null
                              ? Icons.place_rounded
                              : Icons.search,
                          label: widget.onOpenContextTasks != null
                              ? contextLabel
                              : searchLabel,
                        ),
                        if (widget.taskViewModeSwitch != null)
                          SizedBox(
                            width: 190,
                            child: Center(child: widget.taskViewModeSwitch),
                          ),
                        if (widget.onOpenProfile != null)
                          mobileCenteredAction(
                            onPressed: widget.onOpenProfile,
                            icon: Icons.account_circle,
                            label: profileLabel,
                          ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.canExitZoom && widget.onExitZoom != null)
                          desktopBackAction(),
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
                        if (widget.onOpenContextTasks != null)
                          actionButton(
                            onPressed: widget.onOpenContextTasks,
                            icon: Icons.place_rounded,
                            label: contextLabel,
                          ),
                        if (widget.onOpenCompletedTasks != null)
                          actionButton(
                            onPressed: widget.onOpenCompletedTasks,
                            icon: Icons.history,
                            label: completedLabel,
                          ),
                        actionButton(
                          onPressed: widget.onOpenAtlas,
                          icon: Icons.map_outlined,
                          label: atlasLabel,
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
                        // View Mode Toggle (Matrix/List) - Desktop only
                        if (widget.showViewModeToggle &&
                            widget.onToggleViewMode != null)
                          actionButton(
                            onPressed: widget.onToggleViewMode,
                            icon: viewIcon,
                            label: viewLabel,
                          ),
                        if (widget.taskViewModeSwitch != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: widget.taskViewModeSwitch,
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
          color: cs.surfaceContainerHighest,
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
