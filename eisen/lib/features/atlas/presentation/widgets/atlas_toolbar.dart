import 'dart:async';

import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:eisen/features/atlas/domain/saved_atlas_view.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AtlasToolbar extends ConsumerWidget {
  const AtlasToolbar({
    super.key,
    this.config,
    this.onExportPng,
    this.isExporting = false,
    this.onExportPdf,
    this.isExportingPdf = false,
  });

  final AtlasResponsiveConfig? config;
  final VoidCallback? onExportPng;
  final bool isExporting;
  final VoidCallback? onExportPdf;
  final bool isExportingPdf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouping = ref.watch(atlasGroupingProvider);
    final hasFilters = ref.watch(atlasHasActiveFiltersProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final savedViews = ref.watch(savedAtlasViewsProvider);
    final activeSavedViewId = ref.watch(activeSavedAtlasViewProvider);
    final resolvedConfig = config ??
        atlasResponsiveConfigForWidth(MediaQuery.sizeOf(context).width);
    final deviceClass = deviceClassFromContext(context);
    final isCompact = deviceClass.isCompact;
    final theme = Theme.of(context);
    final groupingControl = DropdownMenu<AtlasGrouping>(
      initialSelection: grouping,
      label: const Text('Agrupar'),
      width: isCompact ? 210 : null,
      dropdownMenuEntries: [
        for (final item in AtlasGrouping.values)
          DropdownMenuEntry(value: item, label: item.label),
      ],
      onSelected: (value) {
        if (value != null) {
          ref.read(atlasGroupingProvider.notifier).update(value);
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Atlas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _ViewsMenu(
                      views: savedViews,
                      activeViewId: activeSavedViewId,
                      onApply: (view) {
                        unawaited(
                          ref
                              .read(savedAtlasViewsProvider.notifier)
                              .applyView(view),
                        );
                      },
                      onSave: (name) {
                        unawaited(
                          ref
                              .read(savedAtlasViewsProvider.notifier)
                              .saveCurrentView(name),
                        );
                      },
                      onRename: (view, name) {
                        unawaited(
                          ref
                              .read(savedAtlasViewsProvider.notifier)
                              .renameView(view.id, name),
                        );
                      },
                      onDelete: (view) {
                        unawaited(
                          ref
                              .read(savedAtlasViewsProvider.notifier)
                              .deleteView(view.id),
                        );
                      },
                    ),
                    _MoreActionsMenu(
                      hasFilters: hasFilters,
                      showArchived: showArchived,
                      onExportPng: onExportPng,
                      isExporting: isExporting,
                      onExportPdf: onExportPdf,
                      isExportingPdf: isExportingPdf,
                      onClearFilters: () => clearAtlasBackedFilters(ref),
                      onShowArchivedChanged: (value) {
                        ref.read(showArchivedProvider.notifier).update(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: groupingControl,
                ),
              ],
            )
          : Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atlas',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (resolvedConfig.showToolbarMicrocopy)
                        Text(
                          'Visualiza todas tus tareas en un solo mapa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                groupingControl,
                _ViewsMenu(
                  views: savedViews,
                  activeViewId: activeSavedViewId,
                  onApply: (view) {
                    unawaited(
                      ref
                          .read(savedAtlasViewsProvider.notifier)
                          .applyView(view),
                    );
                  },
                  onSave: (name) {
                    unawaited(
                      ref
                          .read(savedAtlasViewsProvider.notifier)
                          .saveCurrentView(name),
                    );
                  },
                  onRename: (view, name) {
                    unawaited(
                      ref
                          .read(savedAtlasViewsProvider.notifier)
                          .renameView(view.id, name),
                    );
                  },
                  onDelete: (view) {
                    unawaited(
                      ref
                          .read(savedAtlasViewsProvider.notifier)
                          .deleteView(view.id),
                    );
                  },
                ),
                OutlinedButton.icon(
                  onPressed: isExporting ? null : onExportPng,
                  icon: isExporting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined, size: 18),
                  label: Text(isExporting ? 'Exportando' : 'Exportar PNG'),
                ),
                OutlinedButton.icon(
                  onPressed: isExportingPdf ? null : onExportPdf,
                  icon: isExportingPdf
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(
                    isExportingPdf ? 'Generando PDF' : 'Exportar PDF',
                  ),
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

class _MoreActionsMenu extends StatelessWidget {
  const _MoreActionsMenu({
    required this.hasFilters,
    required this.showArchived,
    required this.onExportPng,
    required this.isExporting,
    required this.onExportPdf,
    required this.isExportingPdf,
    required this.onClearFilters,
    required this.onShowArchivedChanged,
  });

  final bool hasFilters;
  final bool showArchived;
  final VoidCallback? onExportPng;
  final bool isExporting;
  final VoidCallback? onExportPdf;
  final bool isExportingPdf;
  final VoidCallback onClearFilters;
  final ValueChanged<bool> onShowArchivedChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ToolbarAction>(
      tooltip: 'Más',
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) {
        switch (action) {
          case _ToolbarAction.exportPng:
            onExportPng?.call();
            break;
          case _ToolbarAction.exportPdf:
            onExportPdf?.call();
            break;
          case _ToolbarAction.toggleArchived:
            onShowArchivedChanged(!showArchived);
            break;
          case _ToolbarAction.clearFilters:
            onClearFilters();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ToolbarAction.exportPng,
          enabled: onExportPng != null && !isExporting,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: isExporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            title: Text(isExporting ? 'Exportando' : 'Exportar PNG'),
          ),
        ),
        PopupMenuItem(
          value: _ToolbarAction.exportPdf,
          enabled: onExportPdf != null && !isExportingPdf,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: isExportingPdf
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            title: Text(isExportingPdf ? 'Generando PDF' : 'Exportar PDF'),
          ),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: _ToolbarAction.toggleArchived,
          checked: showArchived,
          child: const Text('Mostrar archivadas'),
        ),
        if (hasFilters)
          const PopupMenuItem(
            value: _ToolbarAction.clearFilters,
            child: Text('Limpiar filtros'),
          ),
      ],
    );
  }
}

enum _ToolbarAction {
  exportPng,
  exportPdf,
  toggleArchived,
  clearFilters,
}

class _ViewsMenu extends StatelessWidget {
  const _ViewsMenu({
    required this.views,
    required this.activeViewId,
    required this.onApply,
    required this.onSave,
    required this.onRename,
    required this.onDelete,
  });

  final List<SavedAtlasView> views;
  final String? activeViewId;
  final ValueChanged<SavedAtlasView> onApply;
  final ValueChanged<String> onSave;
  final void Function(SavedAtlasView view, String name) onRename;
  final ValueChanged<SavedAtlasView> onDelete;

  @override
  Widget build(BuildContext context) {
    final activeView = _activeView;
    return PopupMenuButton<_ViewsMenuAction>(
      tooltip: 'Vistas',
      onSelected: (action) async {
        switch (action.kind) {
          case _ViewsMenuActionKind.apply:
            final view = action.view;
            if (view != null) onApply(view);
            break;
          case _ViewsMenuActionKind.save:
            final name = await _showAtlasViewNameDialog(
              context,
              title: 'Guardar vista',
            );
            if (name != null) onSave(name);
            break;
          case _ViewsMenuActionKind.rename:
            final view = action.view;
            if (view == null) return;
            final name = await _showAtlasViewNameDialog(
              context,
              title: 'Renombrar vista',
              initialName: view.name,
            );
            if (name != null) onRename(view, name);
            break;
          case _ViewsMenuActionKind.delete:
            final view = action.view;
            if (view != null) onDelete(view);
            break;
        }
      },
      itemBuilder: (context) => [
        for (final view in views)
          PopupMenuItem(
            value: _ViewsMenuAction.apply(view),
            child: Row(
              children: [
                Icon(
                  view.id == activeViewId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(view.name)),
              ],
            ),
          ),
        if (views.isNotEmpty) const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ViewsMenuAction.save(),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.bookmark_add_outlined),
            title: Text('Guardar vista actual'),
          ),
        ),
        PopupMenuItem(
          enabled: activeView != null,
          value: _ViewsMenuAction.rename(activeView),
          child: const ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.drive_file_rename_outline),
            title: Text('Renombrar vista activa'),
          ),
        ),
        PopupMenuItem(
          enabled: activeView != null,
          value: _ViewsMenuAction.delete(activeView),
          child: const ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Eliminar vista activa'),
          ),
        ),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.bookmarks_outlined, size: 18),
          label: Text(activeView?.name ?? 'Vistas'),
        ),
      ),
    );
  }

  SavedAtlasView? get _activeView {
    for (final view in views) {
      if (view.id == activeViewId) return view;
    }
    return null;
  }
}

enum _ViewsMenuActionKind {
  apply,
  save,
  rename,
  delete,
}

class _ViewsMenuAction {
  const _ViewsMenuAction._(this.kind, this.view);

  const _ViewsMenuAction.apply(SavedAtlasView view)
      : this._(_ViewsMenuActionKind.apply, view);

  const _ViewsMenuAction.save() : this._(_ViewsMenuActionKind.save, null);

  const _ViewsMenuAction.rename(SavedAtlasView? view)
      : this._(_ViewsMenuActionKind.rename, view);

  const _ViewsMenuAction.delete(SavedAtlasView? view)
      : this._(_ViewsMenuActionKind.delete, view);

  final _ViewsMenuActionKind kind;
  final SavedAtlasView? view;
}

Future<String?> _showAtlasViewNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
}) async {
  final controller = TextEditingController(text: initialName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.trim().isEmpty) return null;
  return result.trim();
}
