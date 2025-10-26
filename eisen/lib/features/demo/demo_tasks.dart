import 'package:eisen/features/eisen_matrix/domain/entities.dart';

List<Task> demoTasks() => <Task>[
  Task(id: 'd1', title: 'Enviar propuesta al cliente', quadrant: Quadrant.q1, priority: 9, minutes: 90),
  Task(id: 'd2', title: 'Actualizar roadmap', quadrant: Quadrant.q2, priority: 7, minutes: 120),
  Task(id: 'd3', title: 'Documentar API v2', quadrant: Quadrant.q3, priority: 5, minutes: 45),
  Task(id: 'd4', title: 'Revisar redes sociales', quadrant: Quadrant.q4, priority: 2, minutes: 30),
  Task(id: 'd5', title: 'Presentación equipo', quadrant: Quadrant.q1, priority: 6, minutes: 55),
  Task(id: 'd6', title: 'Refactor módulo pagos', quadrant: Quadrant.q2, priority: 8, minutes: 180),
  Task(id: 'd7', title: 'Responder soporte', quadrant: Quadrant.q3, priority: 4, minutes: 35),
  Task(id: 'd8', title: 'Leer informe de mercado', quadrant: Quadrant.q4, priority: 3, minutes: 20),
];

