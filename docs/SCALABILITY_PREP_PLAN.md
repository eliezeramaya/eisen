# Scalability Prep Plan

## Estado actual del stack

- Flutter con Dart `>=3.5.0 <4.0.0`.
- Riverpod 3.x (`flutter_riverpod: ^3.0.3`) para estado reactivo.
- GoRouter para navegacion declarativa.
- SharedPreferences para preferencias, tareas locales y buffers ligeros.
- No hay dependencia Isar activa en `eisen/pubspec.yaml`; la estrategia de DB local queda documentada para cuando se active.
- Tests existentes: unit, widget y golden tests con `flutter_test`, `mocktail` y `golden_toolkit`.
- No hay Supabase ni SDKs externos de observabilidad activos.

## Riesgos tecnicos

- Varias preferencias y payloads historicos viven en SharedPreferences; conviene migrar entidades grandes a una DB local antes de sync cloud.
- `Task` es un modelo grande y manual; un refactor agresivo a Freezed ahora tendria alto riesgo.
- `flutter analyze` ya reporta issues preexistentes fuera del alcance de escalabilidad.
- El repo tiene un contrato de sync remoto no-op; aun falta cola offline-first real.
- La app debe seguir local-first para evitar exponer datos personales antes de tener consentimiento y auth.

## Cambios implementados

- `AppConfig` centralizado con `dart-define`.
- Feature flags centralizados con defaults desde `AppConfig` y overrides locales.
- Interfaces de observabilidad para logger, error reporting y analytics.
- Mapa centralizado de nombres de analytics events y propiedades comunes sin PII.
- Keys locales centralizadas para SharedPreferences.
- Contratos de sync futuro: metadata, status, queue y repository.
- Backend client stub preparado para Supabase sin inicializar SDK.
- Runner basico de migraciones locales no destructivas.
- Tests minimos de config, flags, storage keys, sync metadata y observabilidad.
- CI Flutter basico para format de la nueva capa core, analyze y tests. El format global queda pospuesto porque el repo actual tiene archivos legacy que `dart format` tocaria masivamente.

## Cambios pospuestos

- Activar `custom_lint` y `riverpod_lint`; se dejo preparado en `analysis_options.yaml`, pero no se agregaron para evitar introducir cientos de warnings en el MVP.
- Agregar `supabase_flutter`; debe hacerse solo cuando `ENABLE_CLOUD_SYNC` tenga auth y RLS listos.
- Migrar entidades a Isar o una DB local robusta; hoy no existe dependencia activa.
- Migrar modelos a Freezed de forma masiva.
- Implementar cola de sync real, resolucion de conflictos y retries persistentes.
- Ejecutar un PR separado solo de formato si se quiere activar `dart format --set-exit-if-changed .` sobre todo el repo.

## Criterios para activar Supabase

- `ENABLE_CLOUD_SYNC=true`.
- `SUPABASE_URL` y `SUPABASE_ANON_KEY` configurados por `dart-define` o secreto de CI.
- Auth implementado y probado.
- RLS activado por tabla y testeado con usuarios distintos.
- Sync offline-first con cola persistente y resolucion de conflictos.
- Consentimiento explicito del usuario para cloud sync.

## Criterios para migrar a Freezed

- El modelo cambia con frecuencia o tiene muchos campos opcionales.
- Se requiere serializacion segura y versionada.
- Hay tests de round-trip antes de migrar.
- Migrar primero modelos de menor superficie: `ClassificationMetadata`, `ClassificationResult`, `CategoryConfig`, `ClassificationRule`, `VocabularyAlias`.
- Migrar `Task` solo cuando haya cobertura suficiente de serializacion, sync y UI.
