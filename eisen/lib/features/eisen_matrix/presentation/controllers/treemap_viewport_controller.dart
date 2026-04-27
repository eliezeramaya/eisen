import 'dart:async';

import 'package:eisen/features/eisen_matrix/data/treemap_view_local_datasource.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_view_preferences.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TreemapViewportController extends Notifier<TreemapViewportState> {
  final TreemapViewLocalDatasource _datasource = TreemapViewLocalDatasource();
  TreemapViewPreferences _preferences = TreemapViewPreferencesDefaults.value;
  bool _hasLocalChanges = false;

  @override
  TreemapViewportState build() {
    _restore();
    return TreemapViewportState(
      grouping: _preferences.defaultGrouping,
      density: _preferences.visualDensity,
      zoomLevel: _preferences.defaultZoomLevel,
    );
  }

  void reset({
    TreemapGrouping? grouping,
    TreemapVisualDensity? density,
  }) {
    _commit(
      TreemapViewportState(
        grouping: grouping ?? state.grouping,
        density: density ?? state.density,
        activeSearchQuery: state.activeSearchQuery,
      ),
      persistPreferences: true,
    );
  }

  void setGrouping(TreemapGrouping grouping) {
    _commit(
        state.copyWith(
          grouping: grouping,
          selectedNodeId: null,
          selectedSubcategoryId: null,
          selectedGroupId: null,
          selectedTaskId: null,
          zoomLevel:
              state.isGlobal ? state.zoomLevel : TreemapZoomLevel.category,
          breadcrumbPath: _breadcrumb(
            zoomLevel: state.isGlobal
                ? TreemapZoomLevel.global
                : TreemapZoomLevel.category,
            quadrant: state.selectedQuadrant,
            categoryLabel: null,
            subcategoryLabel: null,
            groupLabel: null,
            taskLabel: null,
          ),
        ),
        persistPreferences: true);
  }

  void setDensity(TreemapVisualDensity density) {
    _commit(
      state.copyWith(density: density),
      persistPreferences: true,
    );
  }

  void setQuickFilter(TreemapQuickFilter? filter) {
    _commit(state.copyWith(quickFilter: filter));
  }

  void syncSearchQuery(String query) {
    final normalized = query.trim();
    final next = normalized.isEmpty ? null : normalized;
    if (next == state.activeSearchQuery) {
      return;
    }
    _commit(state.copyWith(activeSearchQuery: next));
  }

  void enterQuadrant(Quadrant quadrant, {required String label}) {
    _commit(state.copyWith(
      zoomLevel: TreemapZoomLevel.category,
      selectedQuadrant: quadrant,
      selectedCategoryId: null,
      selectedSubcategoryId: null,
      selectedGroupId: null,
      selectedTaskId: null,
      selectedNodeId: null,
      breadcrumbPath: _breadcrumb(
        zoomLevel: TreemapZoomLevel.category,
        quadrant: quadrant,
        quadrantLabel: label,
      ),
    ));
  }

  void openCategory({
    required String categoryId,
    required String categoryLabel,
  }) {
    _commit(state.copyWith(
      zoomLevel: TreemapZoomLevel.subcategory,
      selectedCategoryId: categoryId,
      selectedSubcategoryId: null,
      selectedGroupId: null,
      selectedTaskId: null,
      selectedNodeId: categoryId,
      breadcrumbPath: _breadcrumb(
        zoomLevel: TreemapZoomLevel.subcategory,
        quadrant: state.selectedQuadrant,
        quadrantLabel: _labelAt(1),
        categoryLabel: categoryLabel,
      ),
    ));
  }

  void openSubcategory({
    required String subcategoryId,
    required String subcategoryLabel,
  }) {
    _commit(state.copyWith(
      zoomLevel: TreemapZoomLevel.group,
      selectedSubcategoryId: subcategoryId,
      selectedGroupId: null,
      selectedTaskId: null,
      selectedNodeId: subcategoryId,
      breadcrumbPath: _breadcrumb(
        zoomLevel: TreemapZoomLevel.group,
        quadrant: state.selectedQuadrant,
        quadrantLabel: _labelAt(1),
        categoryLabel: _labelAt(2),
        subcategoryLabel: subcategoryLabel,
      ),
    ));
  }

  void openGroup({
    required String groupId,
    required String groupLabel,
  }) {
    _commit(state.copyWith(
      zoomLevel: TreemapZoomLevel.task,
      selectedGroupId: groupId,
      selectedTaskId: null,
      selectedNodeId: groupId,
      breadcrumbPath: _breadcrumb(
        zoomLevel: TreemapZoomLevel.task,
        quadrant: state.selectedQuadrant,
        quadrantLabel: _labelAt(1),
        categoryLabel: _labelAt(2),
        subcategoryLabel: _labelAt(3),
        groupLabel: groupLabel,
      ),
    ));
  }

  void focusTask(Task task) {
    final taskLabel = task.title.trim().isEmpty ? 'Tarea' : task.title.trim();
    _commit(state.copyWith(
      zoomLevel: TreemapZoomLevel.task,
      selectedTaskId: task.id,
      selectedNodeId: task.id,
      breadcrumbPath: _breadcrumb(
        zoomLevel: TreemapZoomLevel.task,
        quadrant: state.selectedQuadrant,
        quadrantLabel: _labelAt(1),
        categoryLabel: _labelAt(2),
        subcategoryLabel: _labelAt(3),
        groupLabel: _labelAt(4),
        taskLabel: taskLabel,
      ),
    ));
  }

  void selectNode(String? nodeId) {
    _commit(state.copyWith(selectedNodeId: nodeId));
  }

  void popLevel() {
    switch (state.zoomLevel) {
      case TreemapZoomLevel.global:
        return;
      case TreemapZoomLevel.category:
        reset(grouping: state.grouping, density: state.density);
        return;
      case TreemapZoomLevel.subcategory:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.category,
          selectedCategoryId: null,
          selectedSubcategoryId: null,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.category,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
          ),
        ));
        return;
      case TreemapZoomLevel.group:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.subcategory,
          selectedSubcategoryId: null,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.subcategory,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
            categoryLabel: _labelAt(2),
          ),
        ));
        return;
      case TreemapZoomLevel.task:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.group,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.group,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
            categoryLabel: _labelAt(2),
            subcategoryLabel: _labelAt(3),
          ),
        ));
        return;
    }
  }

  void jumpToLevel(TreemapZoomLevel level) {
    switch (level) {
      case TreemapZoomLevel.global:
        reset(grouping: state.grouping, density: state.density);
        return;
      case TreemapZoomLevel.category:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.category,
          selectedCategoryId: null,
          selectedSubcategoryId: null,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.category,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
          ),
        ));
        return;
      case TreemapZoomLevel.subcategory:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.subcategory,
          selectedSubcategoryId: null,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.subcategory,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
            categoryLabel: _labelAt(2),
          ),
        ));
        return;
      case TreemapZoomLevel.group:
        _commit(state.copyWith(
          zoomLevel: TreemapZoomLevel.group,
          selectedGroupId: null,
          selectedTaskId: null,
          selectedNodeId: null,
          breadcrumbPath: _breadcrumb(
            zoomLevel: TreemapZoomLevel.group,
            quadrant: state.selectedQuadrant,
            quadrantLabel: _labelAt(1),
            categoryLabel: _labelAt(2),
            subcategoryLabel: _labelAt(3),
          ),
        ));
        return;
      case TreemapZoomLevel.task:
        return;
    }
  }

  String? _labelAt(int index) {
    if (state.breadcrumbPath.length <= index) {
      return null;
    }
    return state.breadcrumbPath[index];
  }

  List<String> _breadcrumb({
    required TreemapZoomLevel zoomLevel,
    Quadrant? quadrant,
    String? quadrantLabel,
    String? categoryLabel,
    String? subcategoryLabel,
    String? groupLabel,
    String? taskLabel,
  }) {
    final items = <String>['Todo'];
    final qLabel = quadrantLabel ?? quadrant?.name.toUpperCase();
    if (zoomLevel.index >= TreemapZoomLevel.category.index && qLabel != null) {
      items.add(qLabel);
    }
    if (zoomLevel.index >= TreemapZoomLevel.subcategory.index &&
        categoryLabel != null) {
      items.add(categoryLabel);
    }
    if (zoomLevel.index >= TreemapZoomLevel.group.index &&
        subcategoryLabel != null) {
      items.add(subcategoryLabel);
    }
    if (groupLabel != null) {
      items.add(groupLabel);
    }
    if (taskLabel != null) {
      items.add(taskLabel);
    }
    return items;
  }

  Future<void> _restore() async {
    final preferences = await _datasource.loadPreferences();
    final restoredState = await _datasource.loadState();
    _preferences = preferences;
    if (!ref.mounted || _hasLocalChanges) {
      return;
    }
    state = (restoredState ??
            TreemapViewportState(
              grouping: preferences.defaultGrouping,
              density: preferences.visualDensity,
              zoomLevel: preferences.defaultZoomLevel,
            ))
        .copyWith(
      grouping: restoredState?.grouping ?? preferences.defaultGrouping,
      density: restoredState?.density ?? preferences.visualDensity,
    );
  }

  void _commit(
    TreemapViewportState next, {
    bool persistPreferences = false,
  }) {
    final committed = next.copyWith(updatedAt: DateTime.now());
    _hasLocalChanges = true;
    state = committed;
    unawaited(_datasource.saveState(committed));
    if (!persistPreferences) {
      return;
    }
    _preferences = _preferences.copyWith(
      defaultGrouping: committed.grouping,
      visualDensity: committed.density,
      updatedAt: committed.updatedAt,
    );
    unawaited(_datasource.savePreferences(_preferences));
  }
}

final treemapViewportControllerProvider =
    NotifierProvider<TreemapViewportController, TreemapViewportState>(
  TreemapViewportController.new,
);
