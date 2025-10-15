import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/matrix_controller.dart';
import '../../domain/entities.dart';
import '../widgets/legend.dart';
import '../widgets/minimap.dart';
import '../widgets/task_tile.dart';
import '../widgets/toolbar.dart';
import '../widgets/treemap_canvas.dart';
import '../widgets/inspector_drawer.dart';

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
          onToggleDensity: ctrl.toggleCompact,
          onEdit: () => _scaffoldKey.currentState?.openEndDrawer(),
          canEdit: state.selectedId != null,
          onExitZoom: () => ctrl.setZoom(null),
          canExitZoom: state.zoom != null,
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
                ),
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

