# Checklist QA manual (smoke)

## Flujo de tareas
- [ ] Crear tarea con título, prioridad, minutos.
- [ ] Editar tarea existente y verificar persistencia.
- [ ] Eliminar tarea y confirmar desaparición.
- [ ] Mover tarea entre cuadrantes (drag/drop o controles).

## Filtros y vistas
- [ ] Aplicar filtros de categoría/focus space.
- [ ] Cambiar filtros de tiempo (hoy/semana/mes) y ver tareas correctas.
- [ ] Alternar vista matriz vs. lista (si aplica).

## UI/UX
- [ ] Botón de añadir abre sheet/modal correctamente.
- [ ] Safe areas y scroll funcionan en pantallas pequeñas.
- [ ] Controles de accesibilidad visibles (labels/semantics básicos).

## Notificaciones y settings
- [ ] Cambiar idioma/tema y verificar reflejo inmediato.
- [ ] Ajustar sliders de layout (topK, gamma, padding) sin errores.
- [ ] Cambiar tono de notificación y guardado en prefs.

## Dispositivos
- [ ] Probar en un dispositivo físico Android.
- [ ] Probar en Web (desktop) con viewport representativo.

## Post-release
- [ ] CI completo en verde.
- [ ] Issues críticos revisados/triage.
