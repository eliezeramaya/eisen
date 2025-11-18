import 'package:eisen/features/settings/application/settings_controller.dart';
import 'package:eisen/features/settings/presentation/sections/general_panel.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile-first Settings scaffold with a simple category list.
///
/// Each category opens a [SettingsCategoryPage] with a breadcrumb
/// "Settings ▸ {Category}" and its corresponding content.
class SettingsMobileScaffold extends ConsumerWidget {
  const SettingsMobileScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const items = <(String, IconData, String)>[
      ('General', Icons.tune, 'general'),
      ('Appearance', Icons.palette_outlined, 'appearance'),
      ('Layout', Icons.grid_view_rounded, 'layout'),
      ('Calendar/Gantt', Icons.view_timeline, 'calendar'),
      ('Notifications', Icons.notifications_none, 'notifications'),
      ('Language', Icons.language, 'language'),
      ('Accessibility', Icons.accessibility_new, 'accessibility'),
      ('Data & Privacy', Icons.privacy_tip_outlined, 'privacy'),
      ('About', Icons.info_outline, 'about'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Center(child: AppLogoHomeButton()),
            const SizedBox(height: 8),
            Text(
              'Settings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemBuilder: (_, i) {
                  final (label, icon, id) = items[i];
                  return ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .bumpCategoryUsage(id);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsCategoryPage(
                            title: label,
                            categoryId: id,
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-category Settings page used on mobile.
class SettingsCategoryPage extends ConsumerWidget {
  const SettingsCategoryPage({
    super.key,
    required this.title,
    required this.categoryId,
  });

  final String title;
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    Widget body;
    switch (categoryId) {
      case 'general':
        body = const GeneralPanel();
        break;
      // Future iterations: wire dedicated panels for each category.
      default:
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Esta sección de ajustes se está preparando.\n\nPor ahora, puedes cambiar estas opciones desde la vista de escritorio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings ▸ $title',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: body,
      ),
    );
  }
}

