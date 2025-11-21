import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract for any component capable of generating nudges (insights).
abstract interface class NudgeEngine {
  Future<List<Nudge>> calculateNudges(DateTime now);
}

/// Default, deterministic nudge engine based on local task analytics.
class DefaultNudgeEngine implements NudgeEngine {
  DefaultNudgeEngine({
    required this.ref,
    this.lookbackDays = 7,
    this.lowQ2Threshold = 0.22,
    this.rescheduleThreshold = 0.35,
    this.overloadThreshold = 10,
  });

  final Ref ref;
  final int lookbackDays;
  final double lowQ2Threshold;
  final double rescheduleThreshold;
  final int overloadThreshold;

  @override
  Future<List<Nudge>> calculateNudges(DateTime now) async {
    final tasks = ref.read(matrixControllerProvider).tasks;
    if (tasks.isEmpty) return const [];

    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(Duration(days: lookbackDays));
    final windowEnd = today.add(const Duration(days: 1));
    final nudges = <Nudge>[];

    // Regla 1: Bajo Q2 en últimos N días.
    final completed = tasks.where((t) {
      final done = t.completedAt;
      return done != null &&
          !done.isBefore(windowStart) &&
          done.isBefore(windowEnd);
    }).toList(growable: false);
    final totalCompleted = completed.length;
    if (totalCompleted > 0) {
      final q2Count =
          completed.where((t) => t.quadrant == Quadrant.q2).length;
      final share = q2Count / totalCompleted;
      if (share < lowQ2Threshold) {
        nudges.add(
          Nudge(
            id: 'low-q2-$lookbackDays',
            type: NudgeType.lowQ2,
            title: 'Poco tiempo en lo importante',
            message:
                'Tus últimos días han tenido muy poco enfoque en tareas importantes no urgentes (Q2). Protege bloques de tiempo para ellas.',
            severity: NudgeSeverity.mediumHigh,
            createdAt: now,
            metadata: {
              'q2Share': share,
              'sample': totalCompleted,
            },
          ),
        );
      }
    }

    // Regla 2: Muchas tareas reprogramadas.
    final rescheduled = tasks.where((t) {
      if (t.replanCount >= 2) return true;
      final created = t.createdAt;
      final updated = t.updatedAt;
      if (created == null || updated == null) return false;
      final deltaDays = updated.difference(created).inDays;
      return deltaDays >= 1 && updated.isAfter(created);
    }).length;
    final totalTasks = tasks.length;
    if (totalTasks > 0) {
      final ratio = rescheduled / totalTasks;
      if (ratio >= rescheduleThreshold) {
        nudges.add(
          Nudge(
            id: 'excessive-reschedules',
            type: NudgeType.excessiveReschedules,
            title: 'Estás reprogramando demasiado',
            message:
                'Muchas de tus tareas se están moviendo de día en día. Considera recortar el plan diario o desglosar tareas.',
            severity: NudgeSeverity.medium,
            createdAt: now,
            metadata: {
              'rescheduled': rescheduled,
              'total': totalTasks,
              'ratio': ratio,
            },
          ),
        );
      }
    }

    // Regla 3: Sobrecarga diaria (vencen hoy).
    final dueToday = tasks.where((t) {
      if (t.completedAt != null) return false;
      final due = t.due;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
    }).length;
    if (dueToday >= overloadThreshold) {
      nudges.add(
        Nudge(
          id: 'overload-${today.toIso8601String().substring(0, 10)}',
          type: NudgeType.overload,
          title: 'Carga diaria muy alta',
          message:
              'Tu carga para hoy es elevada. Considera mover tareas o reducir alcance para enfocarte en lo esencial.',
          severity: NudgeSeverity.high,
          createdAt: now,
          metadata: {
            'dueToday': dueToday,
            'threshold': overloadThreshold,
          },
        ),
      );
    }

    return nudges;
  }
}

final nudgeEngineProvider = Provider<NudgeEngine>(
  (ref) => DefaultNudgeEngine(ref: ref),
);
