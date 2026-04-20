import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/focus/domain/focus_controller.dart';
import 'package:eisen/features/insights/domain/nudge.dart';

import 'package:eisen/features/insights_adaptive/domain/adaptive_providers.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
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

    // Ejecutar todas las reglas
    nudges.addAll(await _checkLowQ2(tasks, windowStart, windowEnd, now));
    nudges.addAll(await _checkRepeatedReschedules(tasks, now));
    nudges.addAll(await _checkDailyOverload(tasks, today, now));
    nudges.addAll(await _checkProcrastination(tasks, now));
    nudges.addAll(
        await _checkQuadrantImbalance(tasks, windowStart, windowEnd, now));
    nudges.addAll(await _checkTasksWithoutProject(tasks, now));
    nudges.addAll(await _checkNoFocusSessions(now));
    nudges
        .addAll(await _checkLateNightWork(tasks, windowStart, windowEnd, now));

    // Aplicar política adaptativa para priorizar un nudge concreto
    final adaptive = ref.read(adaptivePolicyEngineProvider);
    final selectedArm = await adaptive.selectBestNudgeArm(now);
    final prioritizedTemplate = _mapArmToNudge(
      selectedArm,
      tasks: tasks,
      now: now,
    );
    if (prioritizedTemplate != null) {
      final matchingIndex = nudges.indexWhere(
        (nudge) => nudge.type == prioritizedTemplate.type,
      );
      if (matchingIndex != -1) {
        final enriched = nudges.removeAt(matchingIndex);
        nudges.insert(
          0,
          enriched.copyWith(
            id: prioritizedTemplate.id,
            createdAt: now,
            actions: prioritizedTemplate.actions.isNotEmpty
                ? prioritizedTemplate.actions
                : enriched.actions,
          ),
        );
      }
    }

    return nudges;
  }

  Nudge? _mapArmToNudge(
    NudgeArm arm, {
    required List<Task> tasks,
    required DateTime now,
  }) {
    switch (arm) {
      case NudgeArm.focusBlock:
        return Nudge(
          id: 'bandit-focus-block',
          type: NudgeType.lowQ2,
          title: 'Bloquea foco Q2',
          message:
              'Reserva 60-90 minutos hoy para avanzar en una tarea importante no urgente.',
          severity: NudgeSeverity.mediumHigh,
          category: NudgeCategory.focus,
          createdAt: now,
          actions: const [
            NudgeAction(
              type: NudgeActionType.openFocus,
              label: 'Abrir Focus',
              route: '/focus',
            ),
          ],
        );
      case NudgeArm.reduceTodayLoad:
        return Nudge(
          id: 'bandit-reduce-load',
          type: NudgeType.overload,
          title: 'Reduce la carga de hoy',
          message:
              'Tu día luce pesado. Mueve 1–2 tareas a mañana para proteger tu foco.',
          severity: NudgeSeverity.high,
          category: NudgeCategory.productivity,
          createdAt: now,
          actions: const [
            NudgeAction(
              type: NudgeActionType.openGantt,
              label: 'Reorganizar',
              route: '/workflow-plan',
            ),
          ],
        );
      case NudgeArm.splitBigTask:
        final big = tasks.where((t) => t.minutes >= 120).toList();
        final target = big.isNotEmpty ? big.first.title : 'Tarea grande';
        return Nudge(
          id: 'bandit-split-task',
          type: NudgeType.procrastination,
          title: 'Divide una tarea grande',
          message:
              '“$target” puede dividirse en pasos pequeños para avanzar hoy.',
          severity: NudgeSeverity.mediumHigh,
          category: NudgeCategory.organization,
          createdAt: now,
          actions: const [
            NudgeAction(
              type: NudgeActionType.openMatrix,
              label: 'Abrir Matriz',
              route: '/matrix',
            ),
          ],
        );
      case NudgeArm.dailyShutdown:
        return Nudge(
          id: 'bandit-shutdown',
          type: NudgeType.lateNightWork,
          title: 'Define tu cierre del día',
          message:
              'Termina antes con un ritual simple: revisar mañana, cerrar apps y anotar pendientes.',
          severity: NudgeSeverity.medium,
          category: NudgeCategory.health,
          createdAt: now,
          actions: const [
            NudgeAction(
              type: NudgeActionType.openSettings,
              label: 'Configurar cierre',
              route: '/settings',
            ),
          ],
        );
    }
  }

  /// Regla 1: Bajo Q2 en últimos N días.
  Future<List<Nudge>> _checkLowQ2(
    List<Task> tasks,
    DateTime windowStart,
    DateTime windowEnd,
    DateTime now,
  ) async {
    final completed = tasks.where((t) {
      final done = t.completedAt;
      return done != null &&
          !done.isBefore(windowStart) &&
          done.isBefore(windowEnd);
    }).toList(growable: false);

    final totalCompleted = completed.length;
    if (totalCompleted == 0) return const [];

    final q2Count = completed.where((t) => t.quadrant == Quadrant.q2).length;
    final share = q2Count / totalCompleted;

    if (share >= lowQ2Threshold) return const [];

    final percentage = (share * 100).toStringAsFixed(0);
    final q1Count = completed.where((t) => t.quadrant == Quadrant.q1).length;

    String message;
    NudgeSeverity severity;

    if (share < 0.10) {
      severity = NudgeSeverity.high;
      message =
          '🎯 Solo el $percentage% de tus tareas completadas fueron importantes no urgentes (Q2). '
          'Estás en modo "apaga fuegos" constante. Agenda bloques protegidos de 2-3 horas para Q2 esta semana.';
    } else if (share < 0.15) {
      severity = NudgeSeverity.mediumHigh;
      message =
          '⚠️ Apenas el $percentage% de tu tiempo fue para tareas importantes no urgentes (Q2). '
          'Completaste $q1Count tareas urgentes vs. solo $q2Count estratégicas. '
          'Intenta reservar al menos 1 hora diaria para Q2.';
    } else {
      severity = NudgeSeverity.medium;
      message = '💡 Tu enfoque en Q2 está bajo ($percentage%). '
          'Las tareas importantes no urgentes previenen futuras urgencias. '
          'Considera dedicar 25% de tu tiempo a planificación y proyectos estratégicos.';
    }

    return [
      Nudge(
        id: 'low-q2-$lookbackDays',
        type: NudgeType.lowQ2,
        title: 'Invierte más en lo importante',
        message: message,
        severity: severity,
        category: NudgeCategory.balance,
        createdAt: now,
        metadata: {
          'q2Share': share,
          'q2Count': q2Count,
          'q1Count': q1Count,
          'sample': totalCompleted,
          'lookbackDays': lookbackDays,
        },
        actions: const [
          NudgeAction(
            type: NudgeActionType.openMatrix,
            label: 'Ver Matriz',
            route: '/matrix',
            params: {'quadrant': 'q2'},
          ),
          NudgeAction(
            type: NudgeActionType.openGantt,
            label: 'Planificar Semana',
            route: '/workflow-plan',
          ),
        ],
      ),
    ];
  }

  /// Regla 2: Muchas tareas reprogramadas.
  Future<List<Nudge>> _checkRepeatedReschedules(
    List<Task> tasks,
    DateTime now,
  ) async {
    final rescheduled = tasks.where((t) {
      if (t.replanCount >= 2) return true;
      final created = t.createdAt;
      final updated = t.updatedAt;
      if (created == null || updated == null) return false;
      final deltaDays = updated.difference(created).inDays;
      return deltaDays >= 1 && updated.isAfter(created);
    }).length;

    final totalTasks = tasks.length;
    if (totalTasks == 0) return const [];

    final ratio = rescheduled / totalTasks;
    if (ratio < rescheduleThreshold) return const [];

    final percentage = (ratio * 100).toStringAsFixed(0);
    final pending = tasks.where((t) => t.completedAt == null).length;

    String message;
    NudgeSeverity severity;

    if (ratio >= 0.50) {
      severity = NudgeSeverity.high;
      message =
          '🔄 El $percentage% de tus tareas ($rescheduled de $totalTasks) han sido reprogramadas. '
          'Esto indica sobrecompromiso o falta de realismo. '
          'Reduce tu plan diario a 3-5 tareas clave y celebra completarlas.';
    } else if (ratio >= 0.40) {
      severity = NudgeSeverity.mediumHigh;
      message = '⏰ $rescheduled tareas reprogramadas ($percentage%). '
          'Tienes $pending pendientes acumuladas. '
          'Prueba la regla del 50%: planifica solo la mitad de tu capacidad estimada.';
    } else {
      severity = NudgeSeverity.medium;
      message = '📅 $rescheduled tareas han sido pospuestas ($percentage%). '
          'Reprogramar ocasionalmente es normal, pero hacerlo frecuentemente genera deuda de tareas. '
          'Considera eliminar o delegar algunas.';
    }

    return [
      Nudge(
        id: 'excessive-reschedules',
        type: NudgeType.excessiveReschedules,
        title: 'Demasiadas reprogramaciones',
        message: message,
        severity: severity,
        category: NudgeCategory.productivity,
        createdAt: now,
        metadata: {
          'rescheduled': rescheduled,
          'total': totalTasks,
          'pending': pending,
          'ratio': ratio,
        },
        actions: const [
          NudgeAction(
            type: NudgeActionType.openMatrix,
            label: 'Revisar Tareas',
            route: '/matrix',
          ),
          NudgeAction(
            type: NudgeActionType.openGantt,
            label: 'Reorganizar',
            route: '/workflow-plan',
          ),
        ],
      ),
    ];
  }

  /// Regla 3: Sobrecarga diaria (vencen hoy).
  Future<List<Nudge>> _checkDailyOverload(
    List<Task> tasks,
    DateTime today,
    DateTime now,
  ) async {
    final dueToday = tasks.where((t) {
      if (t.completedAt != null) return false;
      final due = t.due;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
    }).length;

    if (dueToday < overloadThreshold) return const [];

    final q1Today = tasks.where((t) {
      if (t.completedAt != null) return false;
      final due = t.due;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day &&
          t.quadrant == Quadrant.q1;
    }).length;

    final totalMinutes = tasks.where((t) {
      if (t.completedAt != null) return false;
      final due = t.due;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
    }).fold<int>(0, (sum, task) => sum + task.minutes);

    final hours = (totalMinutes / 60.0).toStringAsFixed(1);

    String message;
    NudgeSeverity severity;

    if (dueToday >= 20) {
      severity = NudgeSeverity.high;
      message =
          '🚨 Tienes $dueToday tareas venciendo HOY (~$hours horas estimadas). '
          'Esto es humanamente imposible. Aplica triaje urgente: '
          'elige las 3 MÁS críticas y negocia plazos para el resto.';
    } else if (dueToday >= 15) {
      severity = NudgeSeverity.high;
      message = '⚠️ Sobrecarga: $dueToday tareas para hoy ($hours horas). '
          'Identifica tus top 5 prioridades y comunica retrasos en las demás. '
          'Recuerda: hacer 5 cosas bien > hacer 15 mal.';
    } else {
      severity = NudgeSeverity.mediumHigh;
      message =
          '📊 Tienes $dueToday tareas venciendo hoy ($q1Today urgentes, $hours horas totales). '
          'Es un día pesado. Enfócate primero en las $q1Today urgentes-importantes (Q1), '
          'luego evalúa si puedes renegociar las demás.';
    }

    return [
      Nudge(
        id: 'overload-${today.toIso8601String().substring(0, 10)}',
        type: NudgeType.overload,
        title: 'Carga diaria muy alta',
        message: message,
        severity: severity,
        category: NudgeCategory.productivity,
        createdAt: now,
        metadata: {
          'dueToday': dueToday,
          'q1Today': q1Today,
          'totalMinutes': totalMinutes,
          'threshold': overloadThreshold,
        },
      ),
    ];
  }

  /// Regla 4: Procrastinación - Tareas grandes sin progreso.
  Future<List<Nudge>> _checkProcrastination(
    List<Task> tasks,
    DateTime now,
  ) async {
    // Tareas grandes (>120 min) creadas hace más de 3 días sin completar
    final bigOldTasks = tasks.where((t) {
      if (t.completedAt != null) return false;
      if (t.minutes < 120) return false;
      final created = t.createdAt;
      if (created == null) return false;
      final daysSinceCreated = now.difference(created).inDays;
      return daysSinceCreated >= 3;
    }).toList();

    if (bigOldTasks.length < 3) return const [];

    final oldestTask = bigOldTasks.reduce(
      (a, b) => (a.createdAt?.isBefore(b.createdAt ?? now) ?? false) ? a : b,
    );
    final oldestDays = now.difference(oldestTask.createdAt ?? now).inDays;

    final message =
        '🐌 Tienes ${bigOldTasks.length} tareas grandes (>2h) sin completar desde hace más de 3 días. '
        'La más antigua lleva $oldestDays días. '
        'Tareas grandes generan parálisis. Divídelas en subtareas de 25-45 minutos.';

    return [
      Nudge(
        id: 'procrastination-big-tasks',
        type: NudgeType.procrastination,
        title: 'Divide tareas grandes',
        message: message,
        severity: NudgeSeverity.medium,
        category: NudgeCategory.productivity,
        createdAt: now,
        metadata: {
          'bigTasksCount': bigOldTasks.length,
          'oldestDays': oldestDays,
          'threshold': 120,
        },
        actions: const [
          NudgeAction(
            type: NudgeActionType.openMatrix,
            label: 'Ver Tareas Grandes',
            route: '/matrix',
          ),
        ],
      ),
    ];
  }

  /// Regla 5: Desbalance extremo entre cuadrantes.
  Future<List<Nudge>> _checkQuadrantImbalance(
    List<Task> tasks,
    DateTime windowStart,
    DateTime windowEnd,
    DateTime now,
  ) async {
    final completed = tasks.where((t) {
      final done = t.completedAt;
      return done != null &&
          !done.isBefore(windowStart) &&
          done.isBefore(windowEnd);
    }).toList();

    if (completed.length < 10) return const [];

    final q1 = completed.where((t) => t.quadrant == Quadrant.q1).length;
    final q3 = completed.where((t) => t.quadrant == Quadrant.q3).length;
    final q4 = completed.where((t) => t.quadrant == Quadrant.q4).length;
    final total = completed.length;

    // Detectar si un solo cuadrante tiene más del 70%
    final q1Share = q1 / total;
    final q3Share = q3 / total;
    final q4Share = q4 / total;

    if (q1Share > 0.70) {
      final percentage = (q1Share * 100).toStringAsFixed(0);
      return [
        Nudge(
          id: 'quadrant-imbalance-q1',
          type: NudgeType.quadrantImbalance,
          title: 'Demasiado Q1 (urgente-importante)',
          message: '🔥 El $percentage% de tu tiempo está en Q1 (apaga fuegos). '
              'Estás en modo crisis permanente. Agenda al menos 2 horas diarias de Q2 '
              'para prevenir futuras urgencias.',
          severity: NudgeSeverity.high,
          category: NudgeCategory.balance,
          createdAt: now,
          metadata: {'q1': q1, 'total': total, 'share': q1Share},
        ),
      ];
    }

    if (q3Share > 0.40) {
      final percentage = (q3Share * 100).toStringAsFixed(0);
      return [
        Nudge(
          id: 'quadrant-imbalance-q3',
          type: NudgeType.quadrantImbalance,
          title: 'Demasiado Q3 (urgente-no importante)',
          message:
              '📞 El $percentage% de tu tiempo está en Q3 (interrupciones urgentes). '
              'Estás atendiendo urgencias de otros. Aprende a decir "no" o delegar. '
              'Protege bloques de foco para Q1 y Q2.',
          severity: NudgeSeverity.mediumHigh,
          category: NudgeCategory.balance,
          createdAt: now,
          metadata: {'q3': q3, 'total': total, 'share': q3Share},
          actions: const [
            NudgeAction(
              type: NudgeActionType.openSettings,
              label: 'Configurar Foco',
              route: '/settings',
              params: {'section': 'notifications'},
            ),
            NudgeAction(
              type: NudgeActionType.openMatrix,
              label: 'Ver Tareas Q3',
              route: '/matrix',
              params: {'quadrant': 'q3'},
            ),
          ],
        ),
      ];
    }

    if (q4Share > 0.30) {
      final percentage = (q4Share * 100).toStringAsFixed(0);
      return [
        Nudge(
          id: 'quadrant-imbalance-q4',
          type: NudgeType.quadrantImbalance,
          title: 'Demasiado Q4 (ni urgente ni importante)',
          message:
              '🎮 El $percentage% de tu tiempo está en Q4 (distracciones). '
              'Elimina o reduce estas actividades. Son ladrones de tiempo. '
              'Reemplázalas con Q2 estratégico.',
          severity: NudgeSeverity.medium,
          category: NudgeCategory.balance,
          createdAt: now,
          metadata: {'q4': q4, 'total': total, 'share': q4Share},
          actions: const [
            NudgeAction(
              type: NudgeActionType.openMatrix,
              label: 'Revisar Q4',
              route: '/matrix',
              params: {'quadrant': 'q4'},
            ),
          ],
        ),
      ];
    }

    return const [];
  }

  /// Regla 6: Tareas sin proyecto asignado.
  Future<List<Nudge>> _checkTasksWithoutProject(
    List<Task> tasks,
    DateTime now,
  ) async {
    final pending = tasks.where((t) => t.completedAt == null).toList();
    if (pending.length < 5) return const [];

    final noProject = pending.where((t) => t.category == null).length;
    final ratio = noProject / pending.length;

    if (ratio < 0.50) return const [];

    final percentage = (ratio * 100).toStringAsFixed(0);

    final message =
        '📁 El $percentage% de tus tareas pendientes ($noProject de ${pending.length}) '
        'no tienen proyecto asignado. '
        'Agrupar tareas por proyecto te ayuda a priorizar y mantener contexto. '
        'Dedica 10 minutos a organizarlas.';

    return [
      Nudge(
        id: 'no-project-tasks',
        type: NudgeType.noProject,
        title: 'Organiza tus tareas en proyectos',
        message: message,
        severity: NudgeSeverity.medium,
        category: NudgeCategory.organization,
        createdAt: now,
        metadata: {
          'noProject': noProject,
          'total': pending.length,
          'ratio': ratio,
        },
        actions: const [
          NudgeAction(
            type: NudgeActionType.openMatrix,
            label: 'Organizar Tareas',
            route: '/matrix',
          ),
        ],
      ),
    ];
  }

  /// Regla 7: Sin sesiones de foco en últimos 3 días.
  Future<List<Nudge>> _checkNoFocusSessions(DateTime now) async {
    try {
      final focusRepo = ref.read(focusRepositoryProvider);
      final last3Days = now.subtract(const Duration(days: 3));
      final sessions = await focusRepo.getSessions(
        from: last3Days,
        to: now,
      );

      if (sessions.isNotEmpty) return const [];

      final message =
          '🎯 No has registrado sesiones de foco en los últimos 3 días. '
          'El trabajo profundo requiere bloques ininterrumpidos de 25-90 minutos. '
          'Agenda una sesión Pomodoro para hoy.';

      return [
        Nudge(
          id: 'no-focus-3days',
          type: NudgeType.noFocusSessions,
          title: 'Retoma tus sesiones de foco',
          message: message,
          severity: NudgeSeverity.medium,
          category: NudgeCategory.focus,
          createdAt: now,
          metadata: {'daysSinceLastSession': 3},
          actions: const [
            NudgeAction(
              type: NudgeActionType.openFocus,
              label: 'Iniciar Pomodoro',
              route: '/focus',
            ),
          ],
        ),
      ];
    } catch (e) {
      // Si falla focus repository, simplemente no generamos el nudge
      return const [];
    }
  }

  /// Regla 8: Trabajo nocturno recurrente (después medianoche).
  Future<List<Nudge>> _checkLateNightWork(
    List<Task> tasks,
    DateTime windowStart,
    DateTime windowEnd,
    DateTime now,
  ) async {
    // Detectar tareas completadas entre medianoche y 6am
    final lateNightTasks = tasks.where((t) {
      final done = t.completedAt;
      if (done == null) return false;
      if (done.isBefore(windowStart) || !done.isBefore(windowEnd)) {
        return false;
      }
      final hour = done.hour;
      return hour >= 0 && hour < 6;
    }).toList();

    if (lateNightTasks.length < 3) return const [];

    // Contar días distintos con trabajo nocturno
    final distinctDays = <String>{};
    for (final task in lateNightTasks) {
      final done = task.completedAt;
      if (done != null) {
        final dayKey = '${done.year}-${done.month}-${done.day}';
        distinctDays.add(dayKey);
      }
    }

    if (distinctDays.length < 2) return const [];

    final message =
        '🌙 Has completado ${lateNightTasks.length} tareas después de medianoche '
        'en ${distinctDays.length} noches distintas. '
        'El trabajo nocturno reduce productividad y afecta tu salud. '
        'Configura un "cierre del día" y respétalo.';

    return [
      Nudge(
        id: 'late-night-work-pattern',
        type: NudgeType.lateNightWork,
        title: 'Reduce el trabajo nocturno',
        message: message,
        severity: NudgeSeverity.mediumHigh,
        category: NudgeCategory.health,
        createdAt: now,
        metadata: {
          'lateNightTasks': lateNightTasks.length,
          'distinctNights': distinctDays.length,
        },
        actions: const [
          NudgeAction(
            type: NudgeActionType.openSettings,
            label: 'Configurar Horarios',
            route: '/settings',
            params: {'section': 'notifications'},
          ),
          NudgeAction(
            type: NudgeActionType.openGantt,
            label: 'Planificar Mejor',
            route: '/workflow-plan',
          ),
        ],
      ),
    ];
  }
}

final nudgeEngineProvider = Provider<NudgeEngine>(
  (ref) => DefaultNudgeEngine(ref: ref),
);
