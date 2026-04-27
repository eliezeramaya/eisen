# Performance Guidelines

## Riverpod

- Evitar `ref.watch` global dentro de filas o tiles renderizados masivamente.
- Resolver preferencias globales en el padre y pasar datos simples a hijos.
- Usar `.select` cuando un widget depende de un campo puntual.
- Evitar clasificar o recalcular datos pesados dentro de `build()`.

## Treemap

- Calcular pesos visuales antes del `CustomPainter.paint`.
- Mantener helpers puros para scoring y visual weight.
- Memoizar layouts cuando la lista y configuracion no cambian.
- Invalidar por cuadrante cuando sea posible.

## Clasificacion

- Clasificar al crear o editar, no durante render.
- Guardar metadata calculada en la tarea.
- Recalcular solo cuando cambia texto, categoria, reglas o aliases.

## Listas largas

- Usar virtualizacion con `ListView.builder`.
- Paginacion o filtros para vistas historicas.
- Evitar cargar archivo completo con widgets pesados si crece mucho.

## Analytics y errores

- No serializar payloads grandes.
- No enviar texto completo de tareas.
- Usar eventos agregados con metadata corta.
