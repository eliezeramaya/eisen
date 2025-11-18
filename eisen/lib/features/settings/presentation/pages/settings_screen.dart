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
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 720) {
      return const SettingsMobileScaffold();
    }
    return const SettingsPageDesktop();
  }
}
