# Data Storage Strategy

## Regla de almacenamiento

SharedPreferences debe usarse para datos pequenos, preferencias y flags:

- `settings.*`: preferencias de usuario.
- `ui.*`: densidad, tema, layout, etiquetas de cuadrantes.
- `filters.*`: filtros activos.
- `feature_flags.*`: overrides locales de desarrollo.
- `onboarding.*`: progreso de onboarding.
- `local_schema.*`: version local y migraciones.

Una DB local como Isar debe usarse para entidades consultables y sincronizables:

- tasks
- archived tasks
- classification metadata
- classification correction events
- category configs
- classification rules
- vocabulary aliases
- saved views

## Estado actual

El `pubspec.yaml` actual no tiene Isar activo. La app usa SharedPreferences como storage principal historico. Esto es aceptable para el MVP, pero no debe crecer indefinidamente para datos sincronizables.

## Keys centralizadas

Las nuevas keys deben vivir en:

- `lib/core/storage/local_storage_keys.dart`

Antes de agregar una key nueva se debe revisar si pertenece a `settings`, `filters`, `feature_flags`, `onboarding`, `ui` o `local_schema`.

## Migraciones

El runner base esta en:

- `lib/core/storage/local_schema_version.dart`
- `lib/core/storage/local_migration_runner.dart`

Las migraciones deben:

- correr una sola vez por version;
- no borrar datos si falla una migracion;
- reportar errores via `ErrorReporter`;
- mantener compatibilidad con payloads antiguos.

## Camino recomendado

1. Mantener SharedPreferences para preferencias y toggles.
2. Introducir DB local para entidades sincronizables.
3. Migrar tareas y clasificacion con tests de round-trip.
4. Activar sync cloud solo despues de auth, RLS y cola offline-first.
