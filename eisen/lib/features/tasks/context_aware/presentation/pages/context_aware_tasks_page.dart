import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/tasks/context_aware/application/context_aware_tasks_controller.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:eisen/features/tasks/context_aware/presentation/widgets/context_aware_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContextAwareTasksPage extends ConsumerStatefulWidget {
  const ContextAwareTasksPage({super.key});

  @override
  ConsumerState<ContextAwareTasksPage> createState() =>
      _ContextAwareTasksPageState();
}

class _ContextAwareTasksPageState extends ConsumerState<ContextAwareTasksPage> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(matrixTasksProvider).isEmpty) {
        ref.read(matrixControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';
    final controller = ref.read(contextAwareTasksControllerProvider.notifier);
    final contextState = ref.watch(contextAwareTasksControllerProvider);
    final rankedTasks = ref.watch(rankedContextAwareTasksProvider);
    final activePreset = contextPresetForTag(contextState.currentLocationTag);
    final filteredTasks = _showAll
        ? rankedTasks
        : rankedTasks.where((task) => task.score >= 0.34).take(8).toList();
    final hasNoTasks = rankedTasks.isEmpty;
    final width = MediaQuery.sizeOf(context).width;
    final useGrid = width >= 880;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEs ? 'Tareas por contexto' : 'Context-aware tasks',
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll
                  ? (isEs ? 'Ver sugeridas' : 'Top matches')
                  : (isEs ? 'Ver todas' : 'See all'),
            ),
          ),
          PopupMenuButton<ContextPermissionState>(
            icon: const Icon(Icons.tune_rounded),
            onSelected: controller.setPermissionState,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ContextPermissionState.granted,
                child: Text(isEs ? 'Permiso otorgado' : 'Permission granted'),
              ),
              PopupMenuItem(
                value: ContextPermissionState.denied,
                child: Text(isEs ? 'Permiso denegado' : 'Permission denied'),
              ),
              PopupMenuItem(
                value: ContextPermissionState.unknown,
                child: Text(isEs ? 'Permiso incierto' : 'Permission unknown'),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _HeroHeader(
                contextState: contextState,
                title: isEs
                    ? 'Lo mas relevante para donde estas'
                    : 'What matters most where you are',
                subtitle: activePreset.subtitleFor(locale),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isEs ? 'Modo automatico' : 'Automatic mode'),
                      subtitle: Text(
                        contextState.isAutoMode
                            ? (isEs
                                ? 'El contexto se ajusta solo'
                                : 'Context updates automatically')
                            : (isEs
                                ? 'Tu decides el contexto activo'
                                : 'You force the active context'),
                      ),
                      value: contextState.isAutoMode,
                      onChanged: controller.setAutoMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: contextState.isAutoMode
                        ? controller.refreshAutomaticContext
                        : null,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(isEs ? 'Actualizar' : 'Refresh'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: contextState.isAutoMode &&
                      contextState.permissionState ==
                          ContextPermissionState.denied
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _PermissionBanner(
                        onSwitchToManual: () => controller.setAutoMode(false),
                        onAllow: () => controller
                            .setPermissionState(ContextPermissionState.granted),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: contextState.isAutoMode
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _ManualContextSelector(
                        selectedTag: contextState.currentLocationTag,
                        onSelected: controller.selectManualContext,
                      ),
                    ),
            ),
          ),
          if (hasNoTasks)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: isEs ? 'Todavia no hay tareas' : 'No tasks yet',
                subtitle: isEs
                    ? 'La pantalla usa las tareas reales del repositorio. Puedes cargar el set demo para probar el ranking contextual.'
                    : 'This screen reads the real task list. Load the demo set to inspect contextual ranking.',
                actionLabel: isEs ? 'Cargar demo' : 'Load demo',
                onAction: () =>
                    ref.read(matrixControllerProvider.notifier).resetToDemo(),
              ),
            )
          else if (filteredTasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: isEs
                    ? 'No hay coincidencias fuertes'
                    : 'No strong contextual matches',
                subtitle: isEs
                    ? 'Prueba otro contexto o usa "Ver todas" para revisar el backlog completo.'
                    : 'Try another context or use "See all" to inspect the full backlog.',
                actionLabel: isEs ? 'Ver todas' : 'See all',
                onAction: () => setState(() => _showAll = true),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: useGrid
                  ? SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 250,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final rankedTask = filteredTasks[index];
                        return _AnimatedTaskCard(
                          index: index,
                          child: ContextAwareTaskCard(rankedTask: rankedTask),
                        );
                      },
                    )
                  : SliverList.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final rankedTask = filteredTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AnimatedTaskCard(
                            index: index,
                            child: ContextAwareTaskCard(rankedTask: rankedTask),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.contextState,
    required this.title,
    required this.subtitle,
  });

  final ContextState contextState;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final modeLabel = contextState.isAutoMode ? 'AUTO' : 'MANUAL';
    final permissionLabel = switch (contextState.permissionState) {
      ContextPermissionState.granted => 'GPS OK',
      ContextPermissionState.denied => 'NO GPS',
      ContextPermissionState.unknown => 'GPS ?',
    };
    final contextLabel = localizedContextTag(
      context,
      contextState.currentLocationTag,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.18),
            cs.secondary.withValues(alpha: 0.14),
            cs.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                  label: modeLabel, icon: Icons.motion_photos_auto_rounded),
              _HeaderChip(label: contextLabel, icon: Icons.place_rounded),
              _HeaderChip(label: permissionLabel, icon: Icons.shield_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.onSwitchToManual,
    required this.onAllow,
  });

  final VoidCallback onSwitchToManual;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEs ? 'Ubicacion no disponible' : 'Location unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isEs
                ? 'El ranking baja a prioridad general. Puedes conceder permiso o pasar a modo manual para fijar el contexto.'
                : 'Ranking falls back to general priority. Grant permission or switch to manual mode to force a context.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: onAllow,
                child: Text(isEs ? 'Permitir' : 'Allow'),
              ),
              OutlinedButton(
                onPressed: onSwitchToManual,
                child: Text(isEs ? 'Usar manual' : 'Use manual'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualContextSelector extends StatelessWidget {
  const _ManualContextSelector({
    required this.selectedTag,
    required this.onSelected,
  });

  final String selectedTag;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEs = locale.languageCode == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEs ? 'Contexto manual' : 'Manual context',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in contextLocationPresets)
              ChoiceChip(
                label: Text(preset.labelFor(locale)),
                selected: selectedTag == preset.tag,
                onSelected: (_) => onSelected(preset.tag),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Icon(
                    Icons.layers_clear_rounded,
                    size: 34,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTaskCard extends StatelessWidget {
  const _AnimatedTaskCard({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 180 + (index * 45).clamp(0, 260)),
      tween: Tween(begin: 0.96, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
