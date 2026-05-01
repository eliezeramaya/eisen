import 'package:eisen/core/responsive/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: navigationShell,
      destinations: _destinations,
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }
}

const List<AppNavDestination> _destinations = [
  AppNavDestination(
    icon: Icon(Icons.grid_view_outlined),
    selectedIcon: Icon(Icons.grid_view_rounded),
    label: 'Matrix',
  ),
  AppNavDestination(
    icon: Icon(Icons.insert_chart_outlined_rounded),
    selectedIcon: Icon(Icons.insert_chart_rounded),
    label: 'Stats',
  ),
  AppNavDestination(
    icon: Icon(Icons.timer_outlined),
    selectedIcon: Icon(Icons.timer),
    label: 'Focus',
  ),
  AppNavDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    label: 'Settings',
  ),
];
