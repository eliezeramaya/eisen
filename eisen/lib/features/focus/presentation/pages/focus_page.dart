import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_button.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/focus/data/focus_repository.dart';
import 'package:eisen/features/focus/domain/focus_controller.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';
import 'package:eisen/features/focus/domain/focus_state.dart';
import 'package:eisen/features/focus/presentation/widgets/pomodoro_timer_ring.dart';
import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Focus/Pomodoro page with functional timer
class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  FocusSessionType _selectedType = FocusSessionType.pomodoro;
  int _selectedDuration = 25;
  Task? _selectedTask;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cs = Theme.of(context).colorScheme;
    final showBack = width < 720;

    final focusState = ref.watch(focusControllerProvider);
    final accessibilityPrefs = ref.watch(accessibilityControllerProvider);
    final reduceAnimations =
        accessibilityPrefs.value?.reduceAnimations ?? false;

    final durations = _getDurationsForType(_selectedType);
    if (!durations.contains(_selectedDuration)) {
      _selectedDuration = durations.first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Modo de foco'),
        leading: showBack
            ? BackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EisenSpacing.lg),
          child: focusState.when(
            data: (state) => _buildContent(
              context,
              state,
              durations,
              reduceAnimations,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FocusState state,
    List<int> durations,
    bool reduceAnimations,
  ) {
    final isIdle = state.status == FocusStatus.idle;
    final isCompleted = state.status == FocusStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Configuration section (only visible when idle)
        if (isIdle) ...[
          const EisenSectionHeader(title: 'Tipo de sesión'),
          const SizedBox(height: EisenSpacing.sm),
          Wrap(
            spacing: EisenSpacing.sm,
            runSpacing: EisenSpacing.sm,
            children: FocusSessionType.values.map((type) {
              final label = _getLabelForType(type);
              return ChoiceChip(
                label: Text(label),
                selected: _selectedType == type,
                onSelected: (_) {
                  setState(() => _selectedType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: EisenSpacing.lg),
          EisenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EisenSectionHeader(
                  title: 'Duración',
                  subtitle: 'Ajusta la longitud del bloque',
                ),
                const SizedBox(height: EisenSpacing.sm),
                Wrap(
                  spacing: EisenSpacing.sm,
                  children: durations.map((d) {
                    return ChoiceChip(
                      label: Text('$d min'),
                      selected: _selectedDuration == d,
                      onSelected: (_) {
                        setState(() => _selectedDuration = d);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: EisenSpacing.lg),
          _buildTaskSelector(),
          const SizedBox(height: EisenSpacing.xl),
        ],

        // Timer display (visible when running/paused/completed)
        if (!isIdle) ...[
          Center(
            child: PomodoroTimerRing(
              total: state.total,
              remaining: state.remaining,
              isRunning: state.isRunning,
              isBreak: state.isBreak,
              reduceAnimations: reduceAnimations,
            ),
          ),
          const SizedBox(height: EisenSpacing.xl),
          if (state.linkedTask != null)
            Text(
              'Trabajando en: ${state.linkedTask!.title}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          const SizedBox(height: EisenSpacing.lg),
        ],

        // Control buttons
        _buildControlButtons(state),

        // Completion message
        if (isCompleted) ...[
          const SizedBox(height: EisenSpacing.lg),
          EisenCard(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: EisenSpacing.md),
                Text(
                  state.isBreak
                      ? '¡Descanso completado!'
                      : '¡Sesión de foco completada!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: EisenSpacing.sm),
                Text(
                  state.isBreak
                      ? 'Es hora de volver al trabajo. ¡Puedes hacerlo! 💪'
                      : 'Gran trabajo! Toma un descanso bien merecido. 🎉',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],

        // Today's stats
        const SizedBox(height: EisenSpacing.xl),
        _buildTodayStats(),
      ],
    );
  }

  Widget _buildTaskSelector() {
    final tasks = ref.watch(matrixControllerProvider).tasks;
    final activeTasks = tasks.where((t) => t.completedAt == null).toList();

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EisenSectionHeader(
            title: 'Tarea vinculada',
            subtitle: 'Opcional: asigna la sesión a una tarea',
          ),
          const SizedBox(height: EisenSpacing.sm),
          DropdownButton<Task?>(
            isExpanded: true,
            value: _selectedTask,
            items: [
              const DropdownMenuItem<Task?>(
                value: null,
                child: Text('Sin tarea vinculada'),
              ),
              ...activeTasks.map((task) {
                return DropdownMenuItem<Task?>(
                  value: task,
                  child: Text(
                    task.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _selectedTask = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(FocusState state) {
    final isIdle = state.status == FocusStatus.idle;
    final isPaused = state.status == FocusStatus.paused;
    final isCompleted = state.status == FocusStatus.completed;

    if (isIdle) {
      return EisenButton.primary(
        label: 'Iniciar foco',
        icon: Icons.play_arrow_rounded,
        onPressed: _startFocus,
      );
    }

    if (isCompleted) {
      return EisenButton.primary(
        label: 'Nueva sesión',
        icon: Icons.refresh,
        onPressed: _resetToIdle,
      );
    }

    return Row(
      children: [
        Expanded(
          child: EisenButton.primary(
            label: isPaused ? 'Reanudar' : 'Pausar',
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            onPressed: isPaused ? _resumeFocus : _pauseFocus,
          ),
        ),
        const SizedBox(width: EisenSpacing.md),
        Expanded(
          child: EisenButton.text(
            label: 'Detener',
            icon: Icons.stop,
            onPressed: _stopFocus,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    final repo = ref.watch(focusRepositoryProvider);

    return FutureBuilder<Map<String, int>>(
      future: _getTodayStats(repo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final total = stats.values.fold(0, (sum, count) => sum + count);

        if (total == 0) {
          return const SizedBox.shrink();
        }

        return EisenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EisenSectionHeader(
                title: 'Sesiones completadas hoy',
              ),
              const SizedBox(height: EisenSpacing.sm),
              Text('Pomodoro: ${stats['pomodoro'] ?? 0}'),
              Text('Deep Work: ${stats['deepWork'] ?? 0}'),
              Text('Sprint: ${stats['sprint'] ?? 0}'),
              const SizedBox(height: EisenSpacing.sm),
              Text(
                'Total: $total sesiones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getTodayStats(FocusRepository repo) async {
    final pomodoro = await repo.getTodayCount(FocusSessionType.pomodoro);
    final deepWork = await repo.getTodayCount(FocusSessionType.deepWork);
    final sprint = await repo.getTodayCount(FocusSessionType.sprint);

    return {
      'pomodoro': pomodoro,
      'deepWork': deepWork,
      'sprint': sprint,
    };
  }

  void _startFocus() {
    ref.read(focusControllerProvider.notifier).start(
          type: _selectedType,
          duration: Duration(minutes: _selectedDuration),
          linkedTask: _selectedTask,
        );
  }

  void _pauseFocus() {
    ref.read(focusControllerProvider.notifier).pause();
  }

  void _resumeFocus() {
    ref.read(focusControllerProvider.notifier).resume();
  }

  void _stopFocus() {
    ref.read(focusControllerProvider.notifier).stop();
  }

  void _resetToIdle() {
    ref.read(focusControllerProvider.notifier).stop();
  }

  List<int> _getDurationsForType(FocusSessionType type) {
    return switch (type) {
      FocusSessionType.deepWork => const [50, 75, 90, 120],
      FocusSessionType.sprint => const [25, 35, 45, 60],
      FocusSessionType.pomodoro => const [20, 25, 30, 40],
    };
  }

  String _getLabelForType(FocusSessionType type) {
    return switch (type) {
      FocusSessionType.deepWork => 'Deep Work',
      FocusSessionType.sprint => 'Sprint',
      FocusSessionType.pomodoro => 'Pomodoro',
    };
  }
}
