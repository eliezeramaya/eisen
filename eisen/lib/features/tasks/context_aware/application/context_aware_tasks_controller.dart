import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContextAwareTasksController extends Notifier<ContextState> {
  static const _autoCycle = <ContextLocationPreset>[
    officeContextPreset,
    homeContextPreset,
    errandsContextPreset,
  ];

  String _manualTag = officeContextPreset.tag;
  int _autoIndex = 0;

  @override
  ContextState build() {
    return _buildStateFromPreset(
      _autoCycle[_autoIndex],
      isAutoMode: true,
      permissionState: ContextPermissionState.granted,
    );
  }

  void setAutoMode(bool isAutoMode) {
    if (isAutoMode == state.isAutoMode) return;

    if (isAutoMode) {
      state = _buildStateFromPreset(
        _autoCycle[_autoIndex],
        isAutoMode: true,
        permissionState: state.permissionState,
      );
      return;
    }

    state = _buildStateFromPreset(
      contextPresetForTag(_manualTag),
      isAutoMode: false,
      permissionState: state.permissionState,
    );
  }

  void selectManualContext(String tag) {
    _manualTag = tag;
    if (!state.isAutoMode) {
      state = _buildStateFromPreset(
        contextPresetForTag(tag),
        isAutoMode: false,
        permissionState: state.permissionState,
      );
    }
  }

  void refreshAutomaticContext() {
    _autoIndex = (_autoIndex + 1) % _autoCycle.length;
    if (state.isAutoMode) {
      state = _buildStateFromPreset(
        _autoCycle[_autoIndex],
        isAutoMode: true,
        permissionState: state.permissionState,
      );
    }
  }

  void setPermissionState(ContextPermissionState permissionState) {
    state = _buildStateFromPreset(
      state.isAutoMode
          ? _autoCycle[_autoIndex]
          : contextPresetForTag(_manualTag),
      isAutoMode: state.isAutoMode,
      permissionState: permissionState,
    );
  }

  ContextState _buildStateFromPreset(
    ContextLocationPreset preset, {
    required bool isAutoMode,
    required ContextPermissionState permissionState,
  }) {
    final canUseCoordinates =
        !isAutoMode || permissionState != ContextPermissionState.denied;

    return ContextState(
      currentLocationTag:
          canUseCoordinates ? preset.tag : unknownContextPreset.tag,
      latitude: canUseCoordinates ? preset.latitude : null,
      longitude: canUseCoordinates ? preset.longitude : null,
      isAutoMode: isAutoMode,
      permissionState: permissionState,
    );
  }
}

final contextAwareTasksControllerProvider =
    NotifierProvider<ContextAwareTasksController, ContextState>(
  ContextAwareTasksController.new,
);

final rankedContextAwareTasksProvider =
    Provider<List<RankedContextTask>>((ref) {
  final context = ref.watch(contextAwareTasksControllerProvider);
  final tasks = ref.watch(matrixTasksProvider);
  return rankContextAwareTasks(tasks: tasks, context: context);
});
