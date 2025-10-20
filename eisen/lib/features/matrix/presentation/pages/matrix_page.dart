import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/legend.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/minimap.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/toolbar.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_canvas.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/inspector_drawer.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/settings_sheet.dart';
import 'package:eisen/features/eisen_matrix/presentation/pages/task_editor_page.dart';

class MatrixPage extends ConsumerStatefulWidget {
  const MatrixPage({super.key});

  @override
  ConsumerState<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends ConsumerState<MatrixPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(matrixControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>()!;
    final state = ref.watch(matrixControllerProvider);
    final ctrl = ref.read(matrixControllerProvider.notifier);
    final layout = ctrl.layout();

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppToolbar(
          onNew: () => ctrl.createTask(quadrant: state.zoom ?? Quadrant.q2),
          onToggleTheme: ctrl.toggleTheme,
          onQuery: ctrl.setQuery,
          compact: state.compact,
          themeMode: state.themeMode,
          onToggleDensity: ctrl.toggleCompact,
          onEdit: () {
            final id = state.selectedId;
            if (id == null) return;
            final task = state.tasks.firstWhere((t) => t.id == id);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorPage(task: task)));
          },
          canEdit: state.selectedId != null,
          onExitZoom: () {
            ctrl.setZoom(null);
            ctrl.select(null);
          },
          canExitZoom: state.zoom != null,
          onOpenSettings: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => SettingsSheet(
              onToggleTheme: ctrl.toggleTheme,
              onToggleDensity: ctrl.toggleCompact,
              compact: state.compact,
              showAxisLegends: state.showAxisLegends,
              onToggleAxisLegends: ctrl.toggleAxisLegends,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: tokens.blur, sigmaY: tokens.blur),
                    child: const SizedBox.expand(),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.glassBg,
                    borderRadius: BorderRadius.circular(tokens.radius),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                    boxShadow: [
                      BoxShadow(color: tokens.halo.withOpacity(0.15), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                ),
                TreemapCanvas(
                  tasks: state.tasks,
                  layout: layout,
                  zoom: state.zoom,
                  onTap: (id) {
                    ctrl.select(id);
                    if (id != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scaffoldKey.currentState?.openEndDrawer());
                    }
                  },
                  onDropToQuadrant: ctrl.moveTaskToQuadrant,
                  onDoubleTapQuadrant: (q) => ctrl.setZoom(state.zoom == q ? null : q),
                  onEditTask: (id) {
                    final task = state.tasks.firstWhere((t) => t.id == id);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorPage(task: task)));
                  },
                ),
                if (state.showAxisLegends && state.zoom == null) const _AxisLegends(),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Legend(tasks: state.tasks),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Minimap(zoom: state.zoom),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      endDrawer: state.selectedId == null
          ? null
          : InspectorDrawer(
              key: ValueKey(state.selectedId),
              task: state.tasks.firstWhere((t) => t.id == state.selectedId),
              onChanged: (t) => ctrl.updateTask(t.id, (_) => t),
              onDelete: () => ctrl.deleteTask(state.selectedId!),
            ),
    );
  }
}

class _AxisLegends extends StatelessWidget {
  const _AxisLegends();
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
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                );
            return Stack(children: [
              // X-axis labels (Urgent — Not urgent)
              Positioned(
                left: 16,
                top: halfH - 18,
                child: Text('Urgente', style: style),
              ),
              Positioned(
                right: 16,
                top: halfH - 18,
                child: Text('No urgente', style: style),
              ),
              // Y-axis labels (Important — Not important)
              Positioned(
                left: halfW - 60,
                top: 24,
                child: Text('Importante', style: style),
              ),
              Positioned(
                left: halfW - 66,
                bottom: 12,
                child: Text('No importante', style: style),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

