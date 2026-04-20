import 'package:eisen/features/settings/application/settings_controller.dart';
import 'package:eisen/features/settings/presentation/sections/appearance_mobile_panel.dart';
import 'package:eisen/features/settings/presentation/sections/general_panel.dart';
import 'package:eisen/features/settings/presentation/sections/layout_mobile_panel.dart';
import 'package:eisen/features/settings/presentation/settings_content.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mobile-first Settings scaffold with a simple category list.
///
/// Each category opens a [SettingsCategoryPage] with a breadcrumb
/// "Settings ▸ {Category}" and its corresponding content.
class SettingsMobileScaffold extends ConsumerStatefulWidget {
  const SettingsMobileScaffold({super.key, this.initialSection = 'General'});

  final String initialSection;

  @override
  ConsumerState<SettingsMobileScaffold> createState() =>
      _SettingsMobileScaffoldState();
}

class _SettingsMobileScaffoldState
    extends ConsumerState<SettingsMobileScaffold> {
  @override
  void initState() {
    super.initState();
    // Track category usage once when widget is initialized
    final initial = _sectionToId(widget.initialSection);
    if (initial != 'general') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(settingsControllerProvider.notifier)
              .bumpCategoryUsage(initial);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = <({String label, IconData icon, String id})>[
      (label: 'General', icon: Icons.tune, id: 'general'),
      (label: 'Appearance', icon: Icons.palette_outlined, id: 'appearance'),
      (label: 'Layout', icon: Icons.grid_view_rounded, id: 'layout'),
      (label: 'Calendar/Gantt', icon: Icons.view_timeline, id: 'calendar'),
      (
        label: 'Notifications',
        icon: Icons.notifications_none,
        id: 'notifications'
      ),
      (label: 'Language', icon: Icons.language, id: 'language'),
      (
        label: 'Accessibility',
        icon: Icons.accessibility_new,
        id: 'accessibility'
      ),
      (
        label: 'Data & Privacy',
        icon: Icons.privacy_tip_outlined,
        id: 'privacy'
      ),
      (label: 'About', icon: Icons.info_outline, id: 'about'),
    ];

    final initial = _sectionToId(widget.initialSection);

    if (initial != 'general') {
      final match = items.firstWhere(
        (it) => it.id == initial,
        orElse: () => (label: 'General', icon: Icons.tune, id: 'general'),
      );
      return SettingsCategoryPage(
        title: match.label,
        categoryId: match.id,
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Settings'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLogoHomeButton(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemBuilder: (_, i) {
            final (label: label, icon: icon, id: id) = items[i];
            return ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref
                    .read(settingsControllerProvider.notifier)
                    .bumpCategoryUsage(id);
                context.push(_pathFor(id, label));
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        ),
      ),
    );
  }
}

String _pathFor(String id, String label) {
  switch (id) {
    case 'general':
      return '/settings';
    case 'appearance':
      return '/settings/appearance';
    case 'notifications':
      return '/settings/notifications';
    case 'language':
      return '/settings/language';
    case 'accessibility':
      return '/settings/accessibility';
    default:
      final encoded = Uri.encodeComponent(_sectionLabel(id, label));
      return '/settings?section=$encoded';
  }
}

String _sectionLabel(String id, String label) {
  switch (id) {
    case 'layout':
      return 'Layout';
    case 'calendar':
      return 'Calendar/Gantt';
    case 'privacy':
      return 'Data & Privacy';
    case 'about':
      return 'About';
    default:
      return label;
  }
}

String _sectionToId(String section) {
  final lower = section.toLowerCase();
  switch (lower) {
    case 'appearance':
      return 'appearance';
    case 'layout':
      return 'layout';
    case 'calendar/gantt':
      return 'calendar';
    case 'notifications':
      return 'notifications';
    case 'language':
      return 'language';
    case 'accessibility':
      return 'accessibility';
    case 'data & privacy':
    case 'data and privacy':
      return 'privacy';
    case 'about':
      return 'about';
    case 'general':
    default:
      return 'general';
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
      case 'appearance':
        body = const AppearanceMobilePanel();
        break;
      case 'layout':
        body = const LayoutMobilePanel();
        break;
      case 'notifications':
        body = const NotificationsPanel();
        break;
      case 'language':
        body = const LanguageRegionPanel();
        break;
      case 'accessibility':
        body = const AccessibilityPanel();
        break;
      case 'privacy':
        body = const DataPrivacyPanel();
        break;
      case 'about':
        body = const AboutPanel();
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
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
