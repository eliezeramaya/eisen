# Supabase Readiness

## Estado

Eisen no inicializa Supabase todavia. El contrato vive detras de:

- `lib/core/backend/backend_client.dart`
- `lib/core/backend/backend_provider.dart`
- `lib/core/backend/supabase_backend_client.dart`

El stub solo se considera configurado cuando `ENABLE_CLOUD_SYNC=true` y existen `SUPABASE_URL` y `SUPABASE_ANON_KEY`.

## Tablas futuras

- `profiles`
- `tasks`
- `archived_tasks`
- `classification_rules`
- `vocabulary_aliases`
- `classification_correction_events`
- `saved_views`

## RLS futura

- Todas las tablas sincronizables deben tener `user_id`.
- Policies por tabla:
  - select solo si `auth.uid() = user_id`;
  - insert solo si `auth.uid() = user_id`;
  - update/delete solo si `auth.uid() = user_id`.
- No usar service-role key en cliente.

## Estrategia offline-first

- La app local sigue siendo fuente de verdad mientras no haya usuario autenticado.
- Cada entidad sincronizable debe tener `SyncMetadata`.
- Cambios locales entran a una `SyncQueue`.
- El servidor recibe creates/updates/deletes idempotentes.
- Conflictos se resuelven con version, timestamps y reglas por entidad.

## Reglas de activacion

- No sincronizar sin autenticacion.
- No sincronizar sin consentimiento claro.
- No enviar notas o contenido sensible a analytics.
- No activar `ENABLE_CLOUD_SYNC` en prod sin pruebas de RLS.
