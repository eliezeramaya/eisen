import 'package:eisen/features/eisen_matrix/domain/entities.dart';

const int kDemoTaskCount = 100;

List<Task> demoTasks({DateTime? referenceTime}) {
  final now = referenceTime ?? DateTime.now();
  final tasks = <Task>[];

  for (var contextIndex = 0;
      contextIndex < _demoContexts.length;
      contextIndex++) {
    final context = _demoContexts[contextIndex];
    for (var quadrantIndex = 0;
        quadrantIndex < Quadrant.values.length;
        quadrantIndex++) {
      final quadrant = Quadrant.values[quadrantIndex];
      for (var themeIndex = 0;
          themeIndex < context.themes.length;
          themeIndex++) {
        final theme = context.themes[themeIndex];
        final status = _statusFor(
          quadrant: quadrant,
          contextTag: context.tag,
          themeIndex: themeIndex,
        );
        final taskNumber = _taskNumber(
          contextIndex: contextIndex,
          quadrantIndex: quadrantIndex,
          themeIndex: themeIndex,
        );
        final minutes = _minutesFor(
          quadrant: quadrant,
          baseMinutes: theme.baseMinutes,
          themeIndex: themeIndex,
        );
        final priority = _priorityFor(
          quadrant: quadrant,
          themePriorityBias: theme.priorityBias,
          themeIndex: themeIndex,
        );
        final createdAt = now.subtract(
          Duration(
            days: 18 - (taskNumber % 7),
            hours: (contextIndex * 2) + themeIndex,
          ),
        );
        final due = _dueFor(
          now: now,
          quadrant: quadrant,
          contextTag: context.tag,
          themeIndex: themeIndex,
        );
        final startedAt = _startedAtFor(
          status: status,
          now: now,
          createdAt: createdAt,
          themeIndex: themeIndex,
        );
        final completedAt = _completedAtFor(
          status: status,
          now: now,
          themeIndex: themeIndex,
        );
        final updatedAt = _updatedAtFor(
          status: status,
          now: now,
          completedAt: completedAt,
          startedAt: startedAt,
        );
        final actualMinutes = _actualMinutesFor(
          status: status,
          minutes: minutes,
          themeIndex: themeIndex,
        );
        final recurrence = _recurrenceFor(
          quadrant: quadrant,
          contextTag: context.tag,
          themeIndex: themeIndex,
        );
        final dependencies = _dependenciesFor(
          contextIndex: contextIndex,
          quadrant: quadrant,
          themeIndex: themeIndex,
        );
        final subtasks = _buildSubtasks(
          taskNumber: taskNumber,
          quadrant: quadrant,
          theme: theme,
          status: status,
          referenceTime: now,
        );

        tasks.add(
          Task(
            id: 'd$taskNumber',
            title: _titleFor(
              quadrant: quadrant,
              theme: theme,
              themeIndex: themeIndex,
            ),
            notes: _notesFor(
              quadrant: quadrant,
              context: context,
              theme: theme,
            ),
            quadrant: quadrant,
            priority: priority,
            minutes: minutes,
            due: due,
            tags: [
              'demo',
              context.tag,
              quadrant.name,
              ...context.tags,
              ...theme.tags,
              if (status == TaskStatus.blocked) 'blocked',
              if (status == TaskStatus.completed) 'done',
            ],
            categories: [
              'demo',
              context.category,
              context.groupLabel,
              theme.categoryLabel,
              _categoryLabelForQuadrant(quadrant),
            ],
            category: context.category,
            locationTag: context.tag,
            latitude: context.baseLatitude + (themeIndex * 0.0011),
            longitude: context.baseLongitude - (themeIndex * 0.0009),
            radiusMeters: context.baseRadiusMeters + (themeIndex * 75),
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            replanCount: _replanCountFor(
              quadrant: quadrant,
              status: status,
              themeIndex: themeIndex,
            ),
            snoozeCount: _snoozeCountFor(
              quadrant: quadrant,
              status: status,
              themeIndex: themeIndex,
            ),
            normalizedPriority: (priority - 1) / 9,
            normalizedMinutes: (minutes.clamp(15, 240)) / 240,
            subtasks: subtasks,
            status: status,
            recurrence: recurrence,
            projectId: '${context.projectPrefix}-${(themeIndex % 3) + 1}',
            assignedTo: context.assignees[themeIndex],
            attachments: _attachmentsFor(
              context: context,
              theme: theme,
              quadrant: quadrant,
              themeIndex: themeIndex,
            ),
            effort: _effortFor(minutes),
            actualMinutes: actualMinutes,
            startedAt: startedAt,
            blockedReason: status == TaskStatus.blocked
                ? _blockedReasonFor(context: context, theme: theme)
                : null,
            dependencies: dependencies,
          ),
        );
      }
    }
  }

  assert(tasks.length == kDemoTaskCount);
  return tasks;
}

int _taskNumber({
  required int contextIndex,
  required int quadrantIndex,
  required int themeIndex,
}) {
  return (contextIndex * 20) + (quadrantIndex * 5) + themeIndex + 1;
}

String _taskIdFor({
  required int contextIndex,
  required Quadrant quadrant,
  required int themeIndex,
}) {
  final quadrantIndex = Quadrant.values.indexOf(quadrant);
  return 'd${_taskNumber(
    contextIndex: contextIndex,
    quadrantIndex: quadrantIndex,
    themeIndex: themeIndex,
  )}';
}

String _titleFor({
  required Quadrant quadrant,
  required _DemoTheme theme,
  required int themeIndex,
}) {
  switch (quadrant) {
    case Quadrant.q1:
      return '${_q1Verbs[themeIndex]} ${theme.titleLabel}';
    case Quadrant.q2:
      return '${_q2Verbs[themeIndex]} ${theme.titleLabel}';
    case Quadrant.q3:
      return '${_q3Verbs[themeIndex]} ${theme.titleLabel}';
    case Quadrant.q4:
      return '${_q4Verbs[themeIndex]} ${theme.titleLabel}';
  }
}

String _notesFor({
  required Quadrant quadrant,
  required _DemoContext context,
  required _DemoTheme theme,
}) {
  return '${theme.summary}. ${_quadrantNotes[quadrant]} '
      'Contexto: ${context.groupLabel}.';
}

DateTime? _dueFor({
  required DateTime now,
  required Quadrant quadrant,
  required String contextTag,
  required int themeIndex,
}) {
  switch (quadrant) {
    case Quadrant.q1:
      return now.add(
        Duration(hours: [3, 6, 10, 18, 30][themeIndex]),
      );
    case Quadrant.q2:
      return now.add(
        Duration(days: [5, 8, 12, 16, 24][themeIndex]),
      );
    case Quadrant.q3:
      return now.add(
        Duration(hours: [8, 14, 24, 36, 48][themeIndex]),
      );
    case Quadrant.q4:
      if (contextTag == 'wellness' && themeIndex.isEven) {
        return now.add(Duration(days: [4, 9, 14, 21, 28][themeIndex]));
      }
      return now.add(
        Duration(days: [10, 14, 21, 30, 45][themeIndex]),
      );
  }
}

int _minutesFor({
  required Quadrant quadrant,
  required int baseMinutes,
  required int themeIndex,
}) {
  final adjustment = switch (quadrant) {
    Quadrant.q1 => 25,
    Quadrant.q2 => 45,
    Quadrant.q3 => 0,
    Quadrant.q4 => -10,
  };
  final jitter = (themeIndex % 3) * 10;
  return (baseMinutes + adjustment + jitter).clamp(20, 300);
}

int _priorityFor({
  required Quadrant quadrant,
  required int themePriorityBias,
  required int themeIndex,
}) {
  final base = switch (quadrant) {
    Quadrant.q1 => 8,
    Quadrant.q2 => 6,
    Quadrant.q3 => 4,
    Quadrant.q4 => 1,
  };
  return (base + themePriorityBias + (themeIndex % 2)).clamp(1, 10);
}

TaskStatus _statusFor({
  required Quadrant quadrant,
  required String contextTag,
  required int themeIndex,
}) {
  switch (quadrant) {
    case Quadrant.q1:
      if (themeIndex == 1 || (contextTag == 'office' && themeIndex == 4)) {
        return TaskStatus.blocked;
      }
      return themeIndex.isEven ? TaskStatus.inProgress : TaskStatus.pending;
    case Quadrant.q2:
      if (contextTag == 'study' && themeIndex == 3) {
        return TaskStatus.inProgress;
      }
      return themeIndex == 4 ? TaskStatus.inProgress : TaskStatus.pending;
    case Quadrant.q3:
      return themeIndex == 2 ? TaskStatus.inProgress : TaskStatus.pending;
    case Quadrant.q4:
      if (contextTag == 'wellness' && themeIndex >= 2) {
        return TaskStatus.inProgress;
      }
      if (contextTag == 'home' && themeIndex == 4) {
        return TaskStatus.inProgress;
      }
      return themeIndex == 1 ? TaskStatus.inProgress : TaskStatus.pending;
  }
}

DateTime? _startedAtFor({
  required TaskStatus status,
  required DateTime now,
  required DateTime createdAt,
  required int themeIndex,
}) {
  if (status == TaskStatus.pending) return null;
  return createdAt.add(Duration(hours: 2 + themeIndex)).isAfter(now)
      ? createdAt
      : createdAt.add(Duration(hours: 2 + themeIndex));
}

DateTime? _completedAtFor({
  required TaskStatus status,
  required DateTime now,
  required int themeIndex,
}) {
  if (status != TaskStatus.completed) return null;
  return now.subtract(Duration(days: themeIndex + 1, hours: themeIndex * 3));
}

DateTime _updatedAtFor({
  required TaskStatus status,
  required DateTime now,
  required DateTime? completedAt,
  required DateTime? startedAt,
}) {
  if (status == TaskStatus.completed && completedAt != null) {
    return completedAt;
  }
  if (startedAt != null) {
    return startedAt.add(const Duration(hours: 1));
  }
  return now.subtract(const Duration(hours: 6));
}

int? _actualMinutesFor({
  required TaskStatus status,
  required int minutes,
  required int themeIndex,
}) {
  switch (status) {
    case TaskStatus.inProgress:
      return (minutes * (0.35 + (themeIndex * 0.08))).round();
    case TaskStatus.completed:
      return minutes + ((themeIndex - 1) * 12);
    case TaskStatus.blocked:
      return (minutes * 0.2).round();
    case TaskStatus.pending:
    case TaskStatus.cancelled:
      return null;
  }
}

RecurrencePattern _recurrenceFor({
  required Quadrant quadrant,
  required String contextTag,
  required int themeIndex,
}) {
  if (contextTag == 'wellness') {
    return themeIndex.isEven
        ? RecurrencePattern.weekly
        : RecurrencePattern.daily;
  }
  if (contextTag == 'home' && quadrant != Quadrant.q1) {
    return themeIndex == 0
        ? RecurrencePattern.weekly
        : RecurrencePattern.monthly;
  }
  if (contextTag == 'errands' && quadrant == Quadrant.q3) {
    return themeIndex.isEven
        ? RecurrencePattern.weekly
        : RecurrencePattern.biweekly;
  }
  if (contextTag == 'study' && quadrant == Quadrant.q2) {
    return RecurrencePattern.weekly;
  }
  if (contextTag == 'office' && quadrant == Quadrant.q2 && themeIndex >= 3) {
    return RecurrencePattern.monthly;
  }
  return RecurrencePattern.none;
}

List<String> _attachmentsFor({
  required _DemoContext context,
  required _DemoTheme theme,
  required Quadrant quadrant,
  required int themeIndex,
}) {
  if (quadrant == Quadrant.q3 || context.tag == 'errands') {
    return const [];
  }

  final slug = theme.slug;
  final prefix = 'https://demo.eisen.app/assets/${context.tag}/$slug';
  return [
    '$prefix/brief-${quadrant.name}.pdf',
    if (themeIndex.isEven) '$prefix/checklist-${themeIndex + 1}.png',
  ];
}

EffortLevel _effortFor(int minutes) {
  if (minutes <= 45) return EffortLevel.low;
  if (minutes <= 105) return EffortLevel.medium;
  if (minutes <= 180) return EffortLevel.high;
  return EffortLevel.veryHigh;
}

String _blockedReasonFor({
  required _DemoContext context,
  required _DemoTheme theme,
}) {
  return 'En espera de insumos externos para ${theme.shortLabel} en '
      '${context.groupLabel.toLowerCase()}.';
}

int _replanCountFor({
  required Quadrant quadrant,
  required TaskStatus status,
  required int themeIndex,
}) {
  if (status == TaskStatus.blocked) return 2 + (themeIndex % 2);
  if (quadrant == Quadrant.q2) return themeIndex % 3;
  if (quadrant == Quadrant.q4) return 1;
  return themeIndex % 2;
}

int _snoozeCountFor({
  required Quadrant quadrant,
  required TaskStatus status,
  required int themeIndex,
}) {
  if (status == TaskStatus.completed) return 0;
  if (quadrant == Quadrant.q4) return 2 + (themeIndex % 2);
  if (quadrant == Quadrant.q3) return 1 + (themeIndex % 2);
  return themeIndex % 2;
}

String _categoryLabelForQuadrant(Quadrant quadrant) {
  switch (quadrant) {
    case Quadrant.q1:
      return 'do-first';
    case Quadrant.q2:
      return 'schedule';
    case Quadrant.q3:
      return 'delegate';
    case Quadrant.q4:
      return 'eliminate';
  }
}

List<String> _dependenciesFor({
  required int contextIndex,
  required Quadrant quadrant,
  required int themeIndex,
}) {
  final dependencies = <String>[];
  switch (quadrant) {
    case Quadrant.q1:
      if (themeIndex > 0) {
        dependencies.add(
          _taskIdFor(
            contextIndex: contextIndex,
            quadrant: Quadrant.q1,
            themeIndex: themeIndex - 1,
          ),
        );
      }
      break;
    case Quadrant.q2:
      dependencies.add(
        _taskIdFor(
          contextIndex: contextIndex,
          quadrant: Quadrant.q1,
          themeIndex: themeIndex,
        ),
      );
      if (themeIndex > 1) {
        dependencies.add(
          _taskIdFor(
            contextIndex: contextIndex,
            quadrant: Quadrant.q2,
            themeIndex: themeIndex - 1,
          ),
        );
      }
      break;
    case Quadrant.q3:
      dependencies.add(
        _taskIdFor(
          contextIndex: contextIndex,
          quadrant: Quadrant.q1,
          themeIndex: themeIndex,
        ),
      );
      break;
    case Quadrant.q4:
      if (themeIndex.isOdd) {
        dependencies.add(
          _taskIdFor(
            contextIndex: contextIndex,
            quadrant: Quadrant.q2,
            themeIndex: themeIndex - 1,
          ),
        );
      }
      break;
  }
  return dependencies.toSet().toList();
}

List<Subtask> _buildSubtasks({
  required int taskNumber,
  required Quadrant quadrant,
  required _DemoTheme theme,
  required TaskStatus status,
  required DateTime referenceTime,
}) {
  final stepTitles = switch (quadrant) {
    Quadrant.q1 => [
        'Alinear prioridad de ${theme.shortLabel}',
        'Ejecutar entrega principal',
        'Confirmar resultado con stakeholders',
      ],
    Quadrant.q2 => [
        'Definir alcance de ${theme.shortLabel}',
        'Preparar materiales y bloques de trabajo',
        'Documentar siguiente iteración',
      ],
    Quadrant.q3 => [
        'Coordinar responsables',
        'Enviar seguimiento operativo',
        'Cerrar pendientes de baja importancia',
      ],
    Quadrant.q4 => [
        'Decidir si vale la pena mantenerlo',
        'Hacer una sesión breve o limpieza',
        'Archivar aprendizajes y liberar espacio',
      ],
  };

  final completedCount = switch (status) {
    TaskStatus.completed => stepTitles.length,
    TaskStatus.inProgress => 2,
    TaskStatus.blocked => 1,
    TaskStatus.pending => 0,
    TaskStatus.cancelled => 0,
  };

  return List<Subtask>.generate(stepTitles.length, (index) {
    final completed = index < completedCount;
    return Subtask(
      id: 'dst${taskNumber}_${index + 1}',
      title: stepTitles[index],
      completed: completed,
      completedAt: completed
          ? referenceTime.subtract(
              Duration(hours: ((index + 1) * 3) + (taskNumber % 5)),
            )
          : null,
    );
  });
}

class _DemoContext {
  const _DemoContext({
    required this.tag,
    required this.groupLabel,
    required this.category,
    required this.projectPrefix,
    required this.baseLatitude,
    required this.baseLongitude,
    required this.baseRadiusMeters,
    required this.tags,
    required this.assignees,
    required this.themes,
  });

  final String tag;
  final String groupLabel;
  final String category;
  final String projectPrefix;
  final double baseLatitude;
  final double baseLongitude;
  final double baseRadiusMeters;
  final List<String> tags;
  final List<String> assignees;
  final List<_DemoTheme> themes;
}

class _DemoTheme {
  const _DemoTheme({
    required this.slug,
    required this.titleLabel,
    required this.shortLabel,
    required this.summary,
    required this.categoryLabel,
    required this.tags,
    required this.baseMinutes,
    required this.priorityBias,
  });

  final String slug;
  final String titleLabel;
  final String shortLabel;
  final String summary;
  final String categoryLabel;
  final List<String> tags;
  final int baseMinutes;
  final int priorityBias;
}

const List<String> _q1Verbs = [
  'Cerrar',
  'Resolver',
  'Entregar',
  'Preparar',
  'Desbloquear',
];

const List<String> _q2Verbs = [
  'Diseñar',
  'Planificar',
  'Refinar',
  'Documentar',
  'Optimizar',
];

const List<String> _q3Verbs = [
  'Coordinar',
  'Responder',
  'Confirmar',
  'Actualizar',
  'Revisar',
];

const List<String> _q4Verbs = [
  'Ordenar',
  'Explorar',
  'Curar',
  'Probar',
  'Mantener',
];

const Map<Quadrant, String> _quadrantNotes = {
  Quadrant.q1: 'Tiene una ventana de entrega corta y necesita foco inmediato.',
  Quadrant.q2: 'Conviene calendarizarlo bien para sostener avance estratégico.',
  Quadrant.q3:
      'Es operativo y requiere seguimiento, pero no debe desplazar lo importante.',
  Quadrant.q4:
      'Sirve como tarea de mantenimiento o baja prioridad para momentos ligeros.',
};

const List<_DemoContext> _demoContexts = [
  _DemoContext(
    tag: 'office',
    groupLabel: 'Oficina',
    category: 'trabajo',
    projectPrefix: 'office',
    baseLatitude: 19.4328,
    baseLongitude: -99.1332,
    baseRadiusMeters: 320,
    tags: ['team', 'stakeholders', 'delivery'],
    assignees: ['Ana', 'Marco', 'Lucía', 'Diego', 'Sofía'],
    themes: [
      _DemoTheme(
        slug: 'executive-deck',
        titleLabel: 'presentación ejecutiva para comité',
        shortLabel: 'la presentación ejecutiva',
        summary:
            'Ajustar narrativa, cifras y materiales para una revisión con dirección.',
        categoryLabel: 'liderazgo',
        tags: ['slides', 'executive'],
        baseMinutes: 85,
        priorityBias: 2,
      ),
      _DemoTheme(
        slug: 'payments-architecture',
        titleLabel: 'arquitectura del módulo de pagos',
        shortLabel: 'la arquitectura de pagos',
        summary: 'Ordenar decisiones técnicas y riesgos del flujo de cobro.',
        categoryLabel: 'arquitectura',
        tags: ['payments', 'backend'],
        baseMinutes: 110,
        priorityBias: 2,
      ),
      _DemoTheme(
        slug: 'enterprise-proposal',
        titleLabel: 'propuesta enterprise para cliente clave',
        shortLabel: 'la propuesta enterprise',
        summary:
            'Preparar entregables comerciales y validar alcance con ventas.',
        categoryLabel: 'ventas',
        tags: ['proposal', 'sales'],
        baseMinutes: 75,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'ops-playbook',
        titleLabel: 'playbook operativo del nuevo squad',
        shortLabel: 'el playbook operativo',
        summary: 'Dejar claros rituales, ownerships y acuerdos de operación.',
        categoryLabel: 'operaciones',
        tags: ['ops', 'playbook'],
        baseMinutes: 60,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'technical-hiring',
        titleLabel: 'pipeline de contratación técnica',
        shortLabel: 'el pipeline de contratación',
        summary:
            'Coordinar entrevistas, scorecards y oferta para posiciones críticas.',
        categoryLabel: 'talento',
        tags: ['hiring', 'interviews'],
        baseMinutes: 70,
        priorityBias: 1,
      ),
    ],
  ),
  _DemoContext(
    tag: 'home',
    groupLabel: 'Casa',
    category: 'personal',
    projectPrefix: 'home',
    baseLatitude: 19.4260,
    baseLongitude: -99.1677,
    baseRadiusMeters: 280,
    tags: ['home', 'family', 'maintenance'],
    assignees: ['Yo', 'Familia', 'Yo', 'Pareja', 'Yo'],
    themes: [
      _DemoTheme(
        slug: 'meal-plan',
        titleLabel: 'plan semanal de comidas',
        shortLabel: 'el plan de comidas',
        summary: 'Definir menú, compras y bloques de cocina para la semana.',
        categoryLabel: 'hogar',
        tags: ['meal-prep', 'routine'],
        baseMinutes: 55,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'laundry-reset',
        titleLabel: 'lavado y reseteo de ropa',
        shortLabel: 'el lavado de ropa',
        summary: 'Ordenar ropa pendiente y dejar listas las cargas necesarias.',
        categoryLabel: 'mantenimiento',
        tags: ['laundry', 'reset'],
        baseMinutes: 45,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'family-budget',
        titleLabel: 'revisión del presupuesto familiar',
        shortLabel: 'el presupuesto familiar',
        summary: 'Revisar gastos fijos, ahorro y pagos próximos del hogar.',
        categoryLabel: 'finanzas',
        tags: ['budget', 'finance'],
        baseMinutes: 65,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'deep-clean',
        titleLabel: 'limpieza profunda de cocina y sala',
        shortLabel: 'la limpieza profunda',
        summary: 'Atacar acumulados visibles y dejar áreas comunes listas.',
        categoryLabel: 'orden',
        tags: ['cleaning', 'home-care'],
        baseMinutes: 80,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'family-calendar',
        titleLabel: 'calendario familiar del mes',
        shortLabel: 'el calendario familiar',
        summary: 'Coordinar actividades, citas y compromisos de toda la casa.',
        categoryLabel: 'familia',
        tags: ['planning', 'calendar'],
        baseMinutes: 50,
        priorityBias: 1,
      ),
    ],
  ),
  _DemoContext(
    tag: 'errands',
    groupLabel: 'Mandados',
    category: 'vida-adulta',
    projectPrefix: 'errands',
    baseLatitude: 19.4385,
    baseLongitude: -99.1401,
    baseRadiusMeters: 420,
    tags: ['outside', 'city', 'coordination'],
    assignees: ['Yo', 'Yo', 'Yo', 'Yo', 'Yo'],
    themes: [
      _DemoTheme(
        slug: 'grocery-run',
        titleLabel: 'ruta de super y reposición esencial',
        shortLabel: 'la ruta de super',
        summary: 'Cubrir compras prioritarias y reponer básicos del hogar.',
        categoryLabel: 'compras',
        tags: ['grocery', 'restock'],
        baseMinutes: 50,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'bank-paperwork',
        titleLabel: 'trámite bancario pendiente',
        shortLabel: 'el trámite bancario',
        summary: 'Cerrar validaciones, firmas o movimientos presenciales.',
        categoryLabel: 'tramites',
        tags: ['bank', 'paperwork'],
        baseMinutes: 60,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'pharmacy-stop',
        titleLabel: 'parada de farmacia y salud',
        shortLabel: 'la parada de farmacia',
        summary: 'Resolver compras de salud, recetas o insumos personales.',
        categoryLabel: 'salud',
        tags: ['pharmacy', 'health'],
        baseMinutes: 40,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'parcel-dropoff',
        titleLabel: 'entrega y recolección de paquetería',
        shortLabel: 'la paquetería',
        summary: 'Consolidar devoluciones, envíos y paquetes pendientes.',
        categoryLabel: 'logistica',
        tags: ['shipping', 'logistics'],
        baseMinutes: 45,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'car-upkeep',
        titleLabel: 'mantenimiento ligero del auto',
        shortLabel: 'el mantenimiento del auto',
        summary: 'Resolver gasolina, limpieza o chequeos rápidos del vehículo.',
        categoryLabel: 'movilidad',
        tags: ['car', 'mobility'],
        baseMinutes: 55,
        priorityBias: 0,
      ),
    ],
  ),
  _DemoContext(
    tag: 'study',
    groupLabel: 'Estudio',
    category: 'aprendizaje',
    projectPrefix: 'study',
    baseLatitude: 19.4407,
    baseLongitude: -99.1563,
    baseRadiusMeters: 260,
    tags: ['learning', 'deep-work', 'practice'],
    assignees: ['Yo', 'Yo', 'Mentor', 'Yo', 'Yo'],
    themes: [
      _DemoTheme(
        slug: 'flutter-course',
        titleLabel: 'módulo avanzado del curso de Flutter',
        shortLabel: 'el módulo de Flutter',
        summary: 'Avanzar en material técnico con ejercicios aplicados.',
        categoryLabel: 'flutter',
        tags: ['course', 'flutter'],
        baseMinutes: 75,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'data-analysis-project',
        titleLabel: 'proyecto de análisis de datos',
        shortLabel: 'el proyecto de análisis',
        summary: 'Limpiar datos, validar hipótesis y preparar visualizaciones.',
        categoryLabel: 'datos',
        tags: ['data', 'analysis'],
        baseMinutes: 95,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'certification-review',
        titleLabel: 'repaso para certificación profesional',
        shortLabel: 'la certificación',
        summary: 'Cubrir dominios débiles y practicar con bancos de preguntas.',
        categoryLabel: 'certificacion',
        tags: ['exam', 'review'],
        baseMinutes: 80,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'technical-reading',
        titleLabel: 'lectura técnica con notas accionables',
        shortLabel: 'la lectura técnica',
        summary: 'Leer, resumir y convertir ideas en mejoras concretas.',
        categoryLabel: 'lectura',
        tags: ['reading', 'notes'],
        baseMinutes: 60,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'practice-lab',
        titleLabel: 'laboratorio de práctica guiada',
        shortLabel: 'el laboratorio de práctica',
        summary: 'Probar conceptos en un sandbox y capturar aprendizajes.',
        categoryLabel: 'practica',
        tags: ['lab', 'hands-on'],
        baseMinutes: 70,
        priorityBias: 0,
      ),
    ],
  ),
  _DemoContext(
    tag: 'wellness',
    groupLabel: 'Bienestar',
    category: 'bienestar',
    projectPrefix: 'wellness',
    baseLatitude: 19.4192,
    baseLongitude: -99.1749,
    baseRadiusMeters: 300,
    tags: ['wellness', 'energy', 'balance'],
    assignees: ['Yo', 'Coach', 'Yo', 'Yo', 'Yo'],
    themes: [
      _DemoTheme(
        slug: 'strength-routine',
        titleLabel: 'rutina de fuerza de la semana',
        shortLabel: 'la rutina de fuerza',
        summary: 'Sostener entrenamiento con carga progresiva y registro.',
        categoryLabel: 'ejercicio',
        tags: ['strength', 'training'],
        baseMinutes: 50,
        priorityBias: 1,
      ),
      _DemoTheme(
        slug: 'walking-block',
        titleLabel: 'bloque de caminata consciente',
        shortLabel: 'la caminata consciente',
        summary: 'Usar una caminata para bajar tensión y recuperar energía.',
        categoryLabel: 'movimiento',
        tags: ['walk', 'recovery'],
        baseMinutes: 35,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'guided-meditation',
        titleLabel: 'sesión de meditación guiada',
        shortLabel: 'la meditación guiada',
        summary: 'Consolidar una práctica breve de regulación mental.',
        categoryLabel: 'mindfulness',
        tags: ['meditation', 'mindset'],
        baseMinutes: 25,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'sleep-reset',
        titleLabel: 'higiene del sueño y descanso',
        shortLabel: 'la higiene del sueño',
        summary: 'Preparar entorno y ritual nocturno para dormir mejor.',
        categoryLabel: 'descanso',
        tags: ['sleep', 'recovery'],
        baseMinutes: 30,
        priorityBias: 0,
      ),
      _DemoTheme(
        slug: 'health-checkin',
        titleLabel: 'check-in de salud personal',
        shortLabel: 'el check-in de salud',
        summary: 'Registrar energía, hábitos y señales físicas de la semana.',
        categoryLabel: 'salud',
        tags: ['health', 'check-in'],
        baseMinutes: 40,
        priorityBias: 1,
      ),
    ],
  ),
];
