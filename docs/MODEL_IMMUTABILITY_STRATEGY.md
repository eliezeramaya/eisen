# Model Immutability Strategy

## Principio

No migrar todo a Freezed de una vez. La prioridad es mantener la app compilando, preservar datos locales y mejorar modelos donde el beneficio sea claro.

## Primeros candidatos

1. `ClassificationMetadata`
2. `ClassificationResult`
3. `CategoryConfig`
4. `ClassificationRule`
5. `VocabularyAlias`
6. `SavedView`
7. `Task`

`Task` debe migrarse al final porque toca UI, storage, filtros, treemap, workflow, archivo y sync futuro.

## Criterios para migrar un modelo

- Tiene muchos campos opcionales.
- Requiere `copyWith` seguro con limpieza explicita de nulls.
- Requiere serializacion versionada.
- Participa en sync cloud.
- Tiene tests de round-trip antes del cambio.

## Freezed readiness

Agregar Freezed solo cuando el repo acepte `build_runner` como parte del flujo normal. Antes de eso, mantener modelos manuales con:

- constructores inmutables;
- `copyWith`;
- tests de serializacion;
- comentarios de compatibilidad para campos legacy.
