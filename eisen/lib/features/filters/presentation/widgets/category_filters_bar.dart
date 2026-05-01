import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryFiltersBar extends ConsumerWidget {
  const CategoryFiltersBar({
    super.key,
    this.padding = const EdgeInsets.all(8),
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryConfigControllerProvider).where((item) => !item.isHidden).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final activeCategories = ref.watch(activeCategoryFiltersProvider);
    final activeKinds = ref.watch(activeKindFiltersProvider);
    final activeHorizons = ref.watch(activeHorizonFiltersProvider);
    final activeEnergies = ref.watch(activeEnergyFiltersProvider);
    final activeConfidences = ref.watch(activeConfidenceFiltersProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    CategoryConfig? activeSingle;
    if (activeCategories.length == 1) {
      try {
        activeSingle = categories.firstWhere(
          (c) => c.id == activeCategories.first,
        );
      } catch (_) {}
    }

    final catLabel = activeCategories.isEmpty
        ? 'Categoría'
        : activeCategories.length == 1
            ? (activeSingle?.name ?? 'Categoría')
            : 'Categoría (${activeCategories.length})';

    final smartCount = activeKinds.length + activeHorizons.length + activeEnergies.length + activeConfidences.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Seleccionar categorías',
            offset: const Offset(0, 44),
            itemBuilder: (_) => [
              for (final category in categories)
                CheckedPopupMenuItem<String>(
                  value: category.id,
                  checked: activeCategories.contains(category.id),
                  child: Text(category.name),
                ),
            ],
            onSelected: (id) {
              final next = [...activeCategories];
              if (next.contains(id)) {
                next.remove(id);
              } else {
                next.add(id);
              }
              ref.read(activeCategoryFiltersProvider.notifier).update(next.toSet().toList());
            },
            child: _DropdownPill(
              label: catLabel,
              hasActive: activeCategories.isNotEmpty,
              cs: cs,
              tt: tt,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('btn_manage_filters'),
            onPressed: () => _openDialog(context),
            icon: smartCount > 0
                ? Badge(
                    label: Text('$smartCount'),
                    child: const Icon(Icons.tune, size: 18),
                  )
                : const Icon(Icons.tune, size: 18),
            label: const Text('Smart filters'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _ManageFiltersDialog(),
    );
  }
}

class _ManageFiltersDialog extends ConsumerWidget {
  const _ManageFiltersDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryConfigControllerProvider).where((item) => !item.isHidden).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final activeCategories = ref.watch(activeCategoryFiltersProvider);
    final activeKinds = ref.watch(activeKindFiltersProvider);
    final activeHorizons = ref.watch(activeHorizonFiltersProvider);
    final activeEnergies = ref.watch(activeEnergyFiltersProvider);
    final activeConfidences = ref.watch(activeConfidenceFiltersProvider);

    return AlertDialog(
      title: const Text('Smart filters'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Section(
                title: 'Categoría',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      FilterChip(
                        label: Text(category.name),
                        selected: activeCategories.contains(category.id),
                        onSelected: (selected) {
                          final next = [...activeCategories];
                          if (selected) {
                            next.add(category.id);
                          } else {
                            next.remove(category.id);
                          }
                          ref.read(activeCategoryFiltersProvider.notifier).update(next.toSet().toList());
                        },
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Tipo',
                child: _enumWrap<EntryKind>(
                  values: EntryKind.values,
                  selected: activeKinds,
                  labelFor: (item) => item.label,
                  onChanged: (next) => ref.read(activeKindFiltersProvider.notifier).update(next),
                ),
              ),
              _Section(
                title: 'Horizonte',
                child: _enumWrap<TimeHorizon>(
                  values: TimeHorizon.values,
                  selected: activeHorizons,
                  labelFor: (item) => item.label,
                  onChanged: (next) => ref.read(activeHorizonFiltersProvider.notifier).update(next),
                ),
              ),
              _Section(
                title: 'Energía',
                child: _enumWrap<EnergyLevel>(
                  values: EnergyLevel.values,
                  selected: activeEnergies,
                  labelFor: (item) => item.label,
                  onChanged: (next) => ref.read(activeEnergyFiltersProvider.notifier).update(next),
                ),
              ),
              _Section(
                title: 'Confianza',
                child: _enumWrap<ConfidenceLevel>(
                  values: ConfidenceLevel.values,
                  selected: activeConfidences,
                  labelFor: (item) => item.label,
                  onChanged: (next) => ref.read(activeConfidenceFiltersProvider.notifier).update(next),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(activeCategoryFiltersProvider.notifier).update(const []);
            ref.read(activeKindFiltersProvider.notifier).update(const []);
            ref.read(activeHorizonFiltersProvider.notifier).update(const []);
            ref.read(activeEnergyFiltersProvider.notifier).update(const []);
            ref.read(activeConfidenceFiltersProvider.notifier).update(const []);
          },
          child: const Text('Limpiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _enumWrap<T extends Enum>({
    required List<T> values,
    required List<T> selected,
    required String Function(T value) labelFor,
    required ValueChanged<List<T>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(labelFor(value)),
            selected: selected.contains(value),
            onSelected: (isSelected) {
              final next = [...selected];
              if (isSelected) {
                next.add(value);
              } else {
                next.remove(value);
              }
              onChanged(next.toSet().toList());
            },
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({
    required this.label,
    required this.hasActive,
    required this.cs,
    required this.tt,
  });

  final String label;
  final bool hasActive;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: hasActive ? cs.secondaryContainer : null,
        border: Border.all(
          color: hasActive ? cs.secondary : cs.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: hasActive ? cs.onSecondaryContainer : cs.onSurface,
              fontWeight: hasActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: hasActive ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
