import 'package:eisen/features/eisen_matrix/domain/entities.dart';

List<Task> demoTasks() {
  final now = DateTime.now();

  return <Task>[
    // Q1 - Urgente e Importante
    Task(
      id: 'd1',
      title: 'Preparar informe trimestral de ventas',
      notes:
          'Compilar datos de ventas del Q4 y preparar el informe trimestral con conclusiones para la junta directiva.',
      quadrant: Quadrant.q1,
      priority: 10,
      minutes: 180,
      due: now.add(const Duration(days: 3)),
      tags: ['informe', 'ventas', 'análisis'],
      category: 'trabajo',
      status: TaskStatus.inProgress,
      effort: EffortLevel.high,
      startedAt: now.subtract(const Duration(hours: 2)),
      subtasks: [
        Subtask(
            id: 'st1',
            title: 'Reunir datos de ventas Q4',
            completed: true,
            completedAt: now.subtract(const Duration(hours: 1))),
        Subtask(
            id: 'st2',
            title: 'Analizar tendencias de ventas',
            completed: false),
        Subtask(
            id: 'st3',
            title: 'Redactar conclusiones del informe',
            completed: false),
      ],
    ),

    Task(
      id: 'd2',
      title: 'Resolver incidencia crítica del cliente ABC',
      notes:
          'Atender el problema reportado por el cliente ABC y coordinar con soporte para una solución inmediata.',
      quadrant: Quadrant.q1,
      priority: 10,
      minutes: 60,
      due: now.add(const Duration(hours: 8)),
      tags: ['cliente', 'incidencia', 'soporte'],
      category: 'trabajo',
      status: TaskStatus.inProgress,
      effort: EffortLevel.high,
      startedAt: now.subtract(const Duration(minutes: 30)),
      actualMinutes: 45,
      subtasks: [
        Subtask(id: 'st4', title: 'Contactar al cliente ABC', completed: true),
        Subtask(
            id: 'st5',
            title: 'Reproducir el problema reportado',
            completed: true),
        Subtask(
            id: 'st6',
            title: 'Implementar solución temporal',
            completed: false),
      ],
    ),

    Task(
      id: 'd3',
      title: 'Entrevistar a candidato para desarrollador front-end',
      notes:
          'Realizar la entrevista técnica al candidato para la posición de desarrollador front-end.',
      quadrant: Quadrant.q1,
      priority: 9,
      minutes: 30,
      due: now.add(const Duration(days: 2)),
      tags: ['RRHH', 'entrevista', 'contratación'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.medium,
      subtasks: [
        Subtask(id: 'st7', title: 'Revisar CV del candidato', completed: true),
        Subtask(
            id: 'st8', title: 'Preparar preguntas técnicas', completed: true),
        Subtask(id: 'st9', title: 'Conducir la entrevista', completed: false),
      ],
    ),

    Task(
      id: 'd4',
      title: 'Revisar y aprobar presupuesto del departamento',
      notes:
          'Analizar el presupuesto propuesto para el departamento para el próximo año y dar la aprobación final.',
      quadrant: Quadrant.q1,
      priority: 10,
      minutes: 90,
      due: now.add(const Duration(days: 5)),
      tags: ['presupuesto', 'finanzas', 'aprobación'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.high,
    ),

    // Q2 - No Urgente pero Importante
    Task(
      id: 'd5',
      title: 'Actualizar roadmap del proyecto',
      notes:
          'Revisar y actualizar el cronograma y entregables del proyecto para el primer trimestre del próximo año.',
      quadrant: Quadrant.q2,
      priority: 8,
      minutes: 120,
      due: now.add(const Duration(days: 15)),
      tags: ['planificación', 'proyecto', 'cronograma'],
      category: 'trabajo',
      projectId: 'proj-2024-alpha',
      status: TaskStatus.pending,
      effort: EffortLevel.medium,
      recurrence: RecurrencePattern.monthly,
      subtasks: [
        Subtask(
            id: 'st10',
            title: 'Revisar estado actual del proyecto',
            completed: false),
        Subtask(
            id: 'st11',
            title: 'Ajustar cronograma de actividades',
            completed: false),
        Subtask(
            id: 'st12',
            title: 'Definir nuevos entregables Q1',
            completed: false),
      ],
    ),

    Task(
      id: 'd6',
      title: 'Refactorizar módulo de pagos',
      notes:
          'Reestructurar el código del módulo de pagos para mejorar la legibilidad y el mantenimiento.',
      quadrant: Quadrant.q2,
      priority: 8,
      minutes: 180,
      due: now.add(const Duration(days: 20)),
      tags: ['refactor', 'código', 'mantenimiento'],
      category: 'desarrollo de app',
      projectId: 'proj-2024-alpha',
      status: TaskStatus.pending,
      effort: EffortLevel.veryHigh,
      subtasks: [
        Subtask(
            id: 'st13',
            title: 'Identificar secciones de código complejas',
            completed: true),
        Subtask(
            id: 'st14',
            title: 'Refactorizar funciones largas',
            completed: false),
        Subtask(
            id: 'st15',
            title: 'Probar funcionalidad tras cambios',
            completed: false),
      ],
    ),

    Task(
      id: 'd7',
      title: 'Preparar presentación para conferencia anual',
      notes:
          'Crear las diapositivas y ensayar la presentación para la conferencia anual de la industria.',
      quadrant: Quadrant.q2,
      priority: 9,
      minutes: 180,
      due: now.add(const Duration(days: 45)),
      tags: ['presentación', 'conferencia', 'diapositivas'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.high,
      attachments: ['https://docs.example.com/presentation-draft'],
    ),

    Task(
      id: 'd8',
      title: 'Implementar autenticación de usuarios',
      notes:
          'Desarrollar la funcionalidad de registro e inicio de sesión de usuarios con validación de datos.',
      quadrant: Quadrant.q2,
      priority: 8,
      minutes: 180,
      due: now.add(const Duration(days: 30)),
      tags: ['backend', 'auth', 'usuarios'],
      category: 'desarrollo de app',
      projectId: 'proj-2024-alpha',
      status: TaskStatus.pending,
      effort: EffortLevel.veryHigh,
    ),

    // Q3 - Urgente pero No Importante
    Task(
      id: 'd9',
      title: 'Responder correos importantes atrasados',
      notes:
          'Ponerse al día con los correos electrónicos importantes pendientes en la bandeja de entrada.',
      quadrant: Quadrant.q3,
      priority: 6,
      minutes: 30,
      due: now.add(const Duration(days: 1)),
      tags: ['comunicación', 'email', 'pendiente'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.daily,
      subtasks: [
        Subtask(
            id: 'st16',
            title: 'Priorizar correos por importancia',
            completed: true),
        Subtask(
            id: 'st17', title: 'Responder correos urgentes', completed: true),
        Subtask(
            id: 'st18', title: 'Archivar correos resueltos', completed: false),
      ],
    ),

    Task(
      id: 'd10',
      title: 'Organizar reunión de equipo para proyecto X',
      notes:
          'Coordinar agenda y preparar los puntos a tratar en la reunión semanal sobre el proyecto X.',
      quadrant: Quadrant.q3,
      priority: 6,
      minutes: 60,
      due: now.add(const Duration(days: 3)),
      tags: ['reunión', 'equipo', 'proyecto X'],
      category: 'trabajo',
      projectId: 'proj-x',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.weekly,
      subtasks: [
        Subtask(
            id: 'st19', title: 'Definir agenda de la reunión', completed: true),
        Subtask(
            id: 'st20',
            title: 'Enviar invitaciones a participantes',
            completed: false),
        Subtask(id: 'st21', title: 'Reservar sala de juntas', completed: false),
      ],
    ),

    Task(
      id: 'd11',
      title: 'Documentar API v2',
      notes:
          'Escribir la documentación de uso de la API para desarrolladores externos y referencia interna.',
      quadrant: Quadrant.q3,
      priority: 5,
      minutes: 45,
      due: now.add(const Duration(days: 4)),
      tags: ['documentación', 'API', 'developers'],
      category: 'desarrollo de app',
      status: TaskStatus.pending,
      effort: EffortLevel.medium,
    ),

    Task(
      id: 'd12',
      title: 'Comprar víveres para la semana',
      notes:
          'Hacer una lista y comprar alimentos y productos básicos necesarios para la semana.',
      quadrant: Quadrant.q3,
      priority: 7,
      minutes: 60,
      due: now.add(const Duration(days: 1)),
      tags: ['compras', 'supermercado', 'hogar'],
      category: 'personal',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.weekly,
      subtasks: [
        Subtask(id: 'st22', title: 'Hacer lista de la compra', completed: true),
        Subtask(id: 'st23', title: 'Ir al supermercado', completed: false),
        Subtask(id: 'st24', title: 'Guardar los víveres', completed: false),
      ],
    ),

    // Q4 - No Urgente y No Importante
    Task(
      id: 'd13',
      title: 'Revisar redes sociales',
      notes:
          'Revisar actualizaciones de redes sociales y tendencias del sector.',
      quadrant: Quadrant.q4,
      priority: 2,
      minutes: 30,
      due: now.add(const Duration(days: 7)),
      tags: ['social', 'tendencias'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.daily,
    ),

    Task(
      id: 'd14',
      title: 'Leer informe de mercado',
      notes:
          'Revisar el informe mensual del mercado para estar al tanto de las tendencias.',
      quadrant: Quadrant.q4,
      priority: 3,
      minutes: 20,
      due: now.add(const Duration(days: 10)),
      tags: ['lectura', 'mercado', 'tendencias'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
    ),

    Task(
      id: 'd15',
      title: 'Organizar fotos digitales familiares',
      notes:
          'Clasificar y respaldar las fotos familiares en álbumes digitales organizados por fecha y evento.',
      quadrant: Quadrant.q4,
      priority: 3,
      minutes: 180,
      due: now.add(const Duration(days: 60)),
      tags: ['organización', 'fotos', 'digital'],
      category: 'personal',
      status: TaskStatus.pending,
      effort: EffortLevel.medium,
      subtasks: [
        Subtask(
            id: 'st25',
            title: 'Respaldar fotos en disco externo',
            completed: true),
        Subtask(id: 'st26', title: 'Crear carpetas por año', completed: false),
        Subtask(
            id: 'st27', title: 'Organizar fotos en carpetas', completed: false),
      ],
    ),

    Task(
      id: 'd16',
      title: 'Actualizar dependencias del proyecto',
      notes:
          'Elevar la versión de las bibliotecas utilizadas y asegurar la compatibilidad tras la actualización.',
      quadrant: Quadrant.q4,
      priority: 4,
      minutes: 60,
      due: now.add(const Duration(days: 90)),
      tags: ['dependencias', 'actualización', 'mantenimiento'],
      category: 'desarrollo de app',
      status: TaskStatus.pending,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.monthly,
    ),

    Task(
      id: 'd17',
      title: 'Practicar guitarra 2 horas esta semana',
      notes:
          'Dedicar tiempo para practicar lecciones de guitarra, sumando dos horas en total esta semana.',
      quadrant: Quadrant.q4,
      priority: 5,
      minutes: 120,
      due: now.add(const Duration(days: 7)),
      tags: ['hobby', 'música', 'aprendizaje'],
      category: 'personal',
      status: TaskStatus.inProgress,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.weekly,
      startedAt: now.subtract(const Duration(hours: 3)),
      actualMinutes: 30,
      subtasks: [
        Subtask(id: 'st28', title: 'Practicar escalas 30 min', completed: true),
        Subtask(
            id: 'st29',
            title: 'Practicar canción nueva 30 min',
            completed: false),
        Subtask(id: 'st30', title: 'Improvisar 30 min', completed: false),
        Subtask(
            id: 'st31',
            title: 'Revisar lección teoría 30 min',
            completed: false),
      ],
    ),

    Task(
      id: 'd18',
      title: 'Planificar evento de fin de año de la empresa',
      notes:
          'Organizar la logística para la fiesta de fin de año, incluyendo lugar, catering y actividades.',
      quadrant: Quadrant.q4,
      priority: 6,
      minutes: 120,
      due: now.add(const Duration(days: 14)),
      tags: ['evento', 'logística', 'fin de año'],
      category: 'trabajo',
      status: TaskStatus.pending,
      effort: EffortLevel.medium,
      subtasks: [
        Subtask(
            id: 'st32',
            title: 'Reservar lugar para el evento',
            completed: true),
        Subtask(
            id: 'st33',
            title: 'Contratar servicio de catering',
            completed: false),
        Subtask(
            id: 'st34',
            title: 'Planificar actividades y juegos',
            completed: false),
      ],
    ),

    Task(
      id: 'd19',
      title: 'Iniciar rutina de meditación diaria',
      notes:
          'Practicar meditación durante 10 minutos cada día por una semana para establecer el hábito.',
      quadrant: Quadrant.q4,
      priority: 4,
      minutes: 70,
      due: now.add(const Duration(days: 7)),
      tags: ['bienestar', 'hábito', 'meditación'],
      category: 'personal',
      status: TaskStatus.inProgress,
      effort: EffortLevel.low,
      recurrence: RecurrencePattern.daily,
      startedAt: now.subtract(const Duration(days: 2)),
      actualMinutes: 20,
      subtasks: [
        Subtask(id: 'st35', title: 'Día 1 de meditación', completed: true),
        Subtask(id: 'st36', title: 'Día 2 de meditación', completed: true),
        Subtask(id: 'st37', title: 'Día 3 de meditación', completed: false),
        Subtask(id: 'st38', title: 'Día 4 de meditación', completed: false),
        Subtask(id: 'st39', title: 'Día 5 de meditación', completed: false),
        Subtask(id: 'st40', title: 'Día 6 de meditación', completed: false),
        Subtask(id: 'st41', title: 'Día 7 de meditación', completed: false),
      ],
    ),

    Task(
      id: 'd20',
      title: 'Terminar de leer el libro "Sapiens"',
      notes:
          'Leer los capítulos restantes del libro "Sapiens" para finalizarlo este mes.',
      quadrant: Quadrant.q4,
      priority: 3,
      minutes: 120,
      due: now.add(const Duration(days: 30)),
      tags: ['lectura', 'ocio', 'cultura'],
      category: 'personal',
      status: TaskStatus.inProgress,
      effort: EffortLevel.low,
      startedAt: now.subtract(const Duration(days: 15)),
      actualMinutes: 180,
      subtasks: [
        Subtask(id: 'st42', title: 'Leer capítulo 10', completed: true),
        Subtask(id: 'st43', title: 'Leer capítulo 11', completed: false),
        Subtask(id: 'st44', title: 'Leer capítulo 12', completed: false),
      ],
    ),
  ];
}
