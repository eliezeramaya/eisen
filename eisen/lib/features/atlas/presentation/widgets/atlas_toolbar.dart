import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AtlasToolbar extends ConsumerWidget {
  const AtlasToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouping = ref.watch(atlasGroupingProvider);
    final hasFilters = ref.watch(atlasHasActiveFiltersProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? double.infinity : 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atlas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Visualiza todas tus tareas en un solo mapa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenu<AtlasGrouping>(
            initialSelection: grouping,
            label: const Text('Agrupar por'),
            dropdownMenuEntries: [
              for (final item in AtlasGrouping.values)
                DropdownMenuEntry(value: item, label: item.label),
            ],
            onSelected: (value) {
              if (value != null) {
                ref.read(atlasGroupingProvider.notifier).update(value);
              }
            },
          ),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: () => clearAtlasBackedFilters(ref),
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Limpiar filtros'),
            ),
          FilterChip(
            label: const Text('Mostrar archivadas'),
            selected: showArchived,
            onSelected: (value) {
              ref.read(showArchivedProvider.notifier).update(value);
            },
          ),
        ],
      ),
    );
  }
}
