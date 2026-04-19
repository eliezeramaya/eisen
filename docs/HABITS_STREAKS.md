# Habits & Streaks

**Feature**: `features/habits/`  
**Estado**: ✅ Implementado y funcional  
**Última actualización**: Abril 2026

---

## Resumen

El módulo de hábitos y rachas calcula cuántos días consecutivos el usuario ha completado al menos una tarea. Se usa en la pantalla de estadísticas para mostrar motivación y constancia.

---

## Arquitectura

```
features/habits/
└── streaks_service.dart     # Lógica de cálculo de racha
```

El módulo es intencionalmente minimalista: un solo servicio sin capa de datos ni UI propia. La UI se integra en `features/stats/`.

---

## StreaksService

**Archivo**: `lib/features/habits/streaks_service.dart`

### Responsabilidad

Calcula el número de días consecutivos (terminando hoy) en los que el usuario completó al menos una tarea.

### API

```dart
class StreaksService {
  int streakDays(List<Task> tasks)
}
```

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `tasks`   | `List<Task>` | Lista de tareas con `completedAt` poblado |

**Retorna**: `int` — número de días de racha consecutiva. `0` si no hay actividad reciente o la lista está vacía.

### Algoritmo

1. Toma la fecha de hoy (`DateTime.now()`) como punto de partida.
2. Itera hacia atrás día a día.
3. Para cada día verifica si existe al menos una tarea con `completedAt` dentro de ese día (rango `[dayStart, dayStart+1día)`).
4. Incrementa el contador mientras haya actividad; rompe al primer día sin actividad.

```
Hoy     = D
D-0 ✅ → streak 1
D-1 ✅ → streak 2
D-2 ✅ → streak 3
D-3 ❌ → break → resultado: 3
```

### Notas de implementación

- Usa `Task.completedAt` (campo `DateTime?` en la entidad `Task`).
- No persiste nada; es una función pura sobre la lista de tareas en memoria.
- Las tareas sin `completedAt` (no completadas) se ignoran.

---

## Integración en Stats

El `StreaksService` se consume en la capa de estadísticas para mostrar la racha actual al usuario junto con badges motivacionales.

**Provider implícito**: El servicio no tiene provider propio; se instancia o inyecta donde se necesita.

---

## Tests

Los tests de `StreaksService` se encuentran en:
```
test/unit/features/habits/streaks_service_test.dart
```

Casos cubiertos:
- Lista vacía → 0
- Una tarea completada hoy → 1
- Racha múltiple días consecutivos
- Brecha en la racha (rompe la cadena)
- Tareas completadas antes del período activo

---

## Extensiones Futuras

- **Racha mensual / semana**: variante que cuente semanas con actividad en lugar de días.
- **Meta de hábito**: permitir al usuario definir un objetivo (ej. 7 días seguidos) y notificar al alcanzarlo.
- **Persistencia de mejor racha**: guardar el récord histórico del usuario.
- **Integración con Badges/Achievements**: desbloquear logros visuales al superar umbrales.
