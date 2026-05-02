# Plan de testing

**Last reviewed**: 2026-05-02

## Tipos de pruebas
- **Unitarias**: lógica pura de dominio, algoritmos (treemap, bandit, filtros, cálculos de stats).
- **Widget**: UI aislada (componentes y pantallas), con `ProviderScope` y overrides cuando aplique.
- **Integración (E2E)**: flows end-to-end en `integration_test/` con `IntegrationTestWidgetsFlutterBinding`.

> **Nota**: Los golden tests fueron eliminados del proyecto. La regresión visual se valida manualmente en QA.

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
integration_test/
```

## Comandos principales
- Todos los tests: `flutter test`
- Unit: `flutter test test/unit/`
- Widget: `flutter test test/widget/`
- Integración: `flutter test integration_test/`
- Cobertura: `flutter test --coverage` (genera `coverage/lcov.info`)

## Política
- Todo feature nuevo trae tests acordes (unit y/o widget).
- Flujos críticos deben tener al menos un test de integración en `integration_test/`.
- Mantener `dart analyze` limpio antes de abrir PR.
