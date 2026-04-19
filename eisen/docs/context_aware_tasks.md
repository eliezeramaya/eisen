# context_aware_tasks

## Proposito

`context_aware_tasks` prioriza tareas existentes segun el contexto activo del usuario, con foco en ubicacion. El MVP combina coincidencia por `locationTag`, cercania geografica y prioridad para que la lista no se comporte como un filtro binario.

## Decisiones clave

- Se reutilizo la entidad `Task` existente en `features/eisen_matrix` para evitar una arquitectura paralela.
- La feature vive dentro de `lib/features/tasks/` como un submodulo pequeno porque hoy solo existia UI de tareas minima y la app ya centraliza el backlog real en `matrixControllerProvider`.
- El modo automatico usa presets mockeados y conmutables en vez de geolocalizacion real para no agregar dependencias ni bloquear el MVP por permisos nativos.
- La formula de ranking actual es `locationMatch * 0.5 + proximityScore * 0.3 + priorityWeight * 0.2`.

## Archivos tocados

- `lib/features/eisen_matrix/domain/entities.dart`
- `lib/features/eisen_matrix/data/local_repo.dart`
- `lib/features/eisen_matrix/presentation/controllers/matrix_controller.dart`
- `lib/app/router.dart`
- `lib/features/eisen_matrix/presentation/pages/matrix_page.dart`
- `lib/features/eisen_matrix/presentation/widgets/toolbar.dart`
- `lib/features/tasks/context_aware/domain/context_state.dart`
- `lib/features/tasks/context_aware/domain/context_aware_task_scoring.dart`
- `lib/features/tasks/context_aware/application/context_aware_tasks_controller.dart`
- `lib/features/tasks/context_aware/presentation/pages/context_aware_tasks_page.dart`
- `lib/features/tasks/context_aware/presentation/widgets/context_aware_task_card.dart`
- `test/unit/application/tasks/context_aware_scoring_test.dart`
- `test/widget/screens/tasks/context_aware_tasks_page_test.dart`

## Limitaciones del MVP

- No hay GPS real ni permisos del sistema enlazados a plataforma.
- El contexto automatico rota entre presets mock para demostrar la UX y el ranking.
- La metadata contextual se cargo solo en el dataset demo y en tareas que el usuario edite desde codigo; la hoja de alta simple aun no expone campos de ubicacion.
- No se persiste el estado UI del modo auto/manual.

## Siguientes pasos

- Conectar permisos reales y geolocalizacion por plataforma.
- Exponer `locationTag`, coordenadas y radio en el editor de tareas.
- Persistir la preferencia auto/manual en `UiPrefs`.
- Añadir deep link o entrada dedicada en navegacion principal si la pantalla gana uso real.
