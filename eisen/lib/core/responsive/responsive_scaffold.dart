import 'package:flutter/material.dart';
import 'app_breakpoints.dart';
import 'responsive_extensions.dart';

/// A minimal adaptive scaffold that switches navigation affordances across sizes.
/// - compact/medium: Bottom NavigationBar
/// - expanded: NavigationRail
/// - large: Permanent Drawer/Sidebar
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.floatingActionButton,
    this.endDrawer,
  });
  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<AppNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? floatingActionButton;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    final deviceClass = context.deviceClass;
    if (deviceClass.isLarge) {
      // Sidebar layout
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationDrawer(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              children: [
                const SizedBox(height: 8),
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
      );
    } else if (deviceClass.isExpanded) {
      // NavigationRail layout
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
      );
    }

    // Bottom nav (xs/sm)
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            ),
        ],
      ),
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
}
