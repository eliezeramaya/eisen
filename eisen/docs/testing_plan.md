# Plan de testing

## Tipos de pruebas
- Unitarias: lógica pura de dominio, algoritmos (treemap, bandit, filtros, cálculos de stats).
- Widget: UI aislada (componentes y pantallas), con `ProviderScope` y overrides cuando aplique.
- Golden: regresión visual con `matchesGoldenFile` (golden_toolkit disponible).
- Integración (E2E): flows end-to-end en `integration_test/` con `IntegrationTestWidgetsFlutterBinding`.

## Estructura de carpetas
```
test/
  unit/
    domain/
    application/
    infrastructure/
  widget/
    screens/
    components/
  golden/
    goldens/
integration_test/
```

## Comandos principales
- Unit/Widget: `flutter test test/unit test/widget`
- Goldens: `flutter test test/golden`  
  - Regenerar: `flutter test --update-goldens test/golden`
- Integración: `flutter test integration_test`
- Cobertura: `flutter test --coverage` (genera `coverage/lcov.info`)

## Política
- Todo feature nuevo trae tests acordes (unit y/o widget).  
- Cambios de UI deben considerar goldens; si cambian, regenerar y subir imágenes.  
- Flujos críticos deben tener al menos un test de integración en `integration_test/`.  
- No romper goldens en CI: ejecutar sin `--update-goldens` y revisar diffs si fallan.  
- Mantener `dart analyze` limpio antes de abrir PR.
