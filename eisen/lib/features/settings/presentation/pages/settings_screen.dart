import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/features/settings/presentation/pages/settings_mobile_scaffold.dart';
import 'package:eisen/features/settings/presentation/settings_page_desktop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level Settings screen that chooses the appropriate layout.
///
/// For now, it delegates to [SettingsPageDesktop], which already implements
/// a responsive layout (sidebar + panel on wide screens, stacked layout on
/// narrow/mobile widths). This wrapper exists so that future iterations can
/// plug in a dedicated mobile flow with category list + breadcrumbs without
/// changing routing or call sites.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.initialSection,
    this.useShellNavigation = false,
  });

  final String? initialSection;
  final bool useShellNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceClass = deviceClassFromContext(context);
    final section =
        initialSection?.isNotEmpty == true ? initialSection! : 'General';
    if (!deviceClass.isExpandedUp) {
      return SettingsMobileScaffold(
        initialSection: section,
        useShellNavigation: useShellNavigation,
      );
    }
    return SettingsPageDesktop(
      initialSection: section,
      useShellNavigation: useShellNavigation,
    );
  }
}
