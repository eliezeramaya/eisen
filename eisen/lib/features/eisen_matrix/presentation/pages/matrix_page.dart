import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/legend.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/minimap.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/profile_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/inspector_drawer.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/task_editor_page.dart';
import 'package:eisen/l10n/app_localizations.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/stats_page.dart';

class MatrixPage extends ConsumerStatefulWidget {
  const MatrixPage({super.key});

  @override
  ConsumerState<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends ConsumerState<MatrixPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _inlineEditId;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(matrixControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final ctrl = ref.read(matrixControllerProvider.notifier);
    // Minimize rebuild noise via .select
    final zoom = ref.watch(matrixZoomProvider);
    final themeMode = ref.watch(matrixControllerProvider.select((s) => s.themeMode));
    final query = ref.watch(matrixControllerProvider.select((s) => s.query));
    final compact = ref.watch(matrixControllerProvider.select((s) => s.compact));
    final showAxisLegends = ref.watch(matrixControllerProvider.select((s) => s.showAxisLegends));
    final minimal = ref.watch(matrixControllerProvider.select((s) => s.minimal));
    final tasks = ref.watch(matrixTasksProvider);
    final selectedId = ref.watch(matrixControllerProvider.select((s) => s.selectedId));
    final layout = ctrl.layout();

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppToolbar(
          onToggleTheme: ctrl.toggleTheme,
          onQuery: ctrl.setQuery,
          themeMode: themeMode,
          minimal: minimal,
          onToggleMinimal: ctrl.toggleMinimal,
          onOpenStats: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsPage())),
          onOpenProfile: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => const ProfileSheet(),
          ),
          onExitZoom: () {
            ctrl.setZoom(null);
            ctrl.select(null);
            ctrl.setQuery('');
          },
          canExitZoom: zoom != null,
          onOpenSettings: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => SettingsSheet(
              onToggleTheme: ctrl.toggleTheme,
              onToggleDensity: ctrl.toggleCompact,
              compact: compact,
              showAxisLegends: showAxisLegends,
              onToggleAxisLegends: ctrl.toggleAxisLegends,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showAxisLegends && zoom == null)
                _LeftAxisLegends(minimal: minimal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showAxisLegends && zoom == null)
                      _TopAxisLegends(minimal: minimal),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radius),
                        child: Stack(
                          children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: minimal ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: _ProgressBanner(minimal: minimal),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: minimal
                      ? const SizedBox.expand()
                      : BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: tokens.blur, sigmaY: tokens.blur),
                          child: const SizedBox.expand(),
                        ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: state.minimal ? Colors.white : tokens.glassBg,
                    borderRadius: BorderRadius.circular(tokens.radius),
                    border: state.minimal
                        ? Border.all(color: Colors.transparent, width: 0)
                        : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                    boxShadow: state.minimal
                        ? const []
                        : [
                            BoxShadow(color: tokens.halo.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2),
                          ],
                  ),
                ),
                ColorFiltered(
                  colorFilter: state.minimal
                      ? const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      // Recompute incrementally based on current viewport
                      final dynamicLayout = ctrl.computeLayout(viewport: size);
                      final suggested = ctrl.suggestedTopSpots;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: TreemapCanvas(
                          key: ValueKey('${zoom}_${dynamicLayout.length}_${suggested.length}'),
                          tasks: tasks,
                          layout: dynamicLayout,
                          suggestedIds: suggested,
                          minimal: minimal,
                          zoom: zoom,
                          presentQuadrant: zoom ?? ref.read(matrixControllerProvider).presentQuadrant,
                          inlineEditId: _inlineEditId,
                          onInlineSubmit: (id, title) {
                            ctrl.updateTask(id, (t) => t.copyWith(title: title));
                            setState(() => _inlineEditId = null);
                          },
                          onInlineCancel: (id) {
                            final t = tasks.firstWhere((e) => e.id == id);
                            if (t.title == 'New Task' && (t.notes == null || t.notes!.isEmpty)) {
                              ctrl.deleteTask(id);
                            }
                            setState(() => _inlineEditId = null);
                          },
                          onTap: (id) {
                            ctrl.select(id);
                            if (id != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) => _scaffoldKey.currentState?.openEndDrawer());
                            }
                          },
                          onDropToQuadrant: (id, q) {
                            final prev = tasks.firstWhere((t) => t.id == id).quadrant;
                            if (prev == q) return; // no-op
                            ctrl.moveTaskToQuadrant(id, q);
                            final qName = q.name.toUpperCase();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tarea movida a $qName'),
                                action: SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: () {
                                    ctrl.moveTaskToQuadrant(id, prev);
                                  },
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                          onDoubleTapQuadrant: (q) { ctrl.setZoom(zoom == q ? null : q); ctrl.setPresentQuadrant(q); },
                          onEditTask: (id) {
                            final task = tasks.firstWhere((t) => t.id == id);
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorPage(task: task)));
                          },
                          onMarkDone: (id) {
                            ctrl.markTaskDone(id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Tarea completada!'), duration: Duration(milliseconds: 900)));
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Quick add buttons por cuadrante
                Positioned(
                  left: 12,
                  top: 56,
                  child: _QuickAddButton(label: 'Q1', minimal: minimal, onTap: () => _quickAdd(context, Quadrant.q1, ctrl)),
                ),
                Positioned(
                  right: 12,
                  top: 56,
                  child: _QuickAddButton(label: 'Q2', minimal: minimal, onTap: () => _quickAdd(context, Quadrant.q2, ctrl)),
                ),
                Positioned(
                  left: 12,
                  bottom: 56,
                  child: _QuickAddButton(label: 'Q3', minimal: minimal, onTap: () => _quickAdd(context, Quadrant.q3, ctrl)),
                ),
                Positioned(
                  right: 12,
                  bottom: 56,
                  child: _QuickAddButton(label: 'Q4', minimal: minimal, onTap: () => _quickAdd(context, Quadrant.q4, ctrl)),
                ),
                
                
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: selectedId == null
          ? null
          : InspectorDrawer(
              key: ValueKey(selectedId),
              task: tasks.firstWhere((t) => t.id == selectedId),
              onChanged: (t) => ctrl.updateTask(t.id, (_) => t),
              onDelete: () => ctrl.deleteTask(selectedId!),
            ),
      bottomNavigationBar: _BottomActionBar(
        onNew: () {
          final q = zoom ?? Quadrant.q2;
          final id = ctrl.createTask(quadrant: q);
          ctrl.select(id);
          setState(() => _inlineEditId = id);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tarea creada en ${q.name.toUpperCase()}'), duration: const Duration(seconds: 3)),
          );
        },
        onNewInQuadrant: (q) {
          final id = ctrl.createTask(quadrant: q);
          ctrl.select(id);
          setState(() => _inlineEditId = id);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tarea creada en ${q.name.toUpperCase()}'), duration: const Duration(seconds: 3)),
          );
        },
        onToggleDensity: ctrl.toggleCompact,
        compact: compact,
        minimap: Minimap(
          zoom: zoom,
          minimal: minimal,
          tasks: tasks,
          onSelectQuadrant: (q) => ctrl.setZoom(q),
          onFullView: () {
            ctrl.setZoom(null);
            ctrl.select(null);
            ctrl.setQuery('');
          },
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool minimal;
  const _QuickAddButton({required this.label, required this.onTap, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: minimal ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.35),
        foregroundColor: minimal ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
    );
  }
}

void _quickAdd(BuildContext context, Quadrant q, MatrixController ctrl) {
  final id = ctrl.createTask(quadrant: q);
  ctrl.select(id);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Tarea creada en ${q.name.toUpperCase()}'), duration: const Duration(seconds: 3)),
  );
}

class _AxisLegends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final halfW = w / 2;
            final halfH = h / 2;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                );
            final l10n = AppLocalizations.of(context);
            return Stack(children: [
              // X-axis (horizontal): No importante (left) — Importante (right)
              Positioned(
                left: 16,
                top: halfH - 18,
                child: Text(l10n.axisNotImportant, style: style),
              ),
              Positioned(
                right: 16,
                top: halfH - 18,
                child: Text(l10n.axisImportant, style: style),
              ),
              // Y-axis (vertical): Urgente (top) — No urgente (bottom)
              Positioned(
                left: halfW - 50,
                top: 12,
                child: Text(l10n.axisUrgent, style: style),
              ),
              Positioned(
                left: halfW - 62,
                bottom: 12,
                child: Text(l10n.axisNotUrgent, style: style),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _TopAxisLegends extends StatelessWidget {
  final bool minimal;
  const _TopAxisLegends({this.minimal = false});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: minimal ? Colors.black : Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Center(child: Text(l10n.axisUrgent, style: style))),
          Expanded(child: Center(child: Text(l10n.axisNotUrgent, style: style))),
        ],
      ),
    );
  }
}

class _LeftAxisLegends extends StatelessWidget {
  final bool minimal;
  const _LeftAxisLegends({this.minimal = false});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: minimal ? Colors.black : Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        );
    return SizedBox(
      width: 64,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RotatedBox(quarterTurns: 3, child: Text(l10n.axisImportant, style: style)),
            RotatedBox(quarterTurns: 3, child: Text(l10n.axisNotImportant, style: style)),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onNew;
  final void Function(Quadrant q) onNewInQuadrant;
  final VoidCallback onToggleDensity;
  final bool compact;
  final Widget? minimap;

  const _BottomActionBar({
    required this.onNew,
    required this.onNewInQuadrant,
    required this.onToggleDensity,
    required this.compact,
    this.minimap,
  });

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final densityLabel = isEs
        ? (compact ? 'Cómodo' : 'Compacto')
        : (compact ? 'Comfortable' : 'Compact');
    final densityIcon = compact ? Icons.view_comfortable : Icons.view_compact;
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Density toggle button
            TextButton.icon(
              onPressed: onToggleDensity,
              icon: Icon(densityIcon),
              label: Text(densityLabel),
            ),
            // New task with quadrant menu
            MenuAnchor(
              builder: (context, controller, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context).newTask),
                    ),
                    IconButton(
                      onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                      tooltip: isEs ? 'Elegir cuadrante' : 'Choose quadrant',
                      icon: const Icon(Icons.arrow_drop_down),
                    ),
                  ],
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: onNew,
                  leadingIcon: const Icon(Icons.add),
                  child: Text(isEs ? 'Rápido (cuadrante actual)' : 'Quick (current quadrant)'),
                ),
                MenuItemButton(
                  onPressed: () => onNewInQuadrant(Quadrant.q1),
                  leadingIcon: const Icon(Icons.filter_1),
                  child: const Text('Q1'),
                ),
                MenuItemButton(
                  onPressed: () => onNewInQuadrant(Quadrant.q2),
                  leadingIcon: const Icon(Icons.filter_2),
                  child: const Text('Q2'),
                ),
                MenuItemButton(
                  onPressed: () => onNewInQuadrant(Quadrant.q3),
                  leadingIcon: const Icon(Icons.filter_3),
                  child: const Text('Q3'),
                ),
                MenuItemButton(
                  onPressed: () => onNewInQuadrant(Quadrant.q4),
                  leadingIcon: const Icon(Icons.filter_4),
                  child: const Text('Q4'),
                ),
              ],
            ),
            if (minimap != null) ...[
              const SizedBox(width: 12),
              minimap!,
            ],
          ],
        ),
      ),
    );
  }
}
