Treemap Audit (Eisen)
====================

Objetivo: asegurar tiles visibles, áreas válidas, layout estable, y zoom/hit-test coherentes.

Cambios clave aplicados
- Weight seguro: clamp + finito + no negativo (entities.dart)
- Zero-sum seguro: distribución uniforme de áreas si sum(weights) ≤ 0
- Ratio de shelf y orientación: usar lado corto + fallback si worstRatio > 20
- Normalización geométrica: clamp de rects al área del cuadrante y asserts de suma de áreas ±1%
- Stacking mínimo: soporte `minTileArea01` (44×44 px) y overlay +N
- Pintado estable: snapping a pixeles y deflate con gap "seguro" en tiles diminutos
- Modo debug: overlays de cuadrantes, shelves e inspección de id/área/ratio

Archivos relevantes
- `lib/features/eisen_matrix/domain/treemap_layout.dart`
- `lib/features/eisen_matrix/presentation/widgets/treemap_canvas.dart`
- `lib/features/eisen_matrix/presentation/widgets/treemap_debug.dart`

Comprobaciones (asserts/overlays)
- `_checkFinite`, `_checkRect`, `_checkAreaSum` activas con `debugTreemap = true`
- Overlays: borde azul de cuadrantes, shelves tenue, label amarillo por tile (id/área/ratio)

Pruebas añadidas
- `test/unit/weights_finite_test.dart`
- `test/unit/areas_sum_test.dart`
- `test/unit/min_tile_test.dart`
- `test/unit/shelf_ratio_test.dart`
- `test/widget/zoom_hit_test.dart`

Cómo validar
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run -d chrome`

Notas de UX/visibilidad
- En modo "minimal" + tema oscuro, los tiles eran negros con borde negro (difícil de ver). El modo debug añade labels/overlays para detectar. Si persiste, desactiva "minimal" desde Settings o ajusta paleta minimal.

Lema: “Un treemap bien hecho se siente: cada tile respira, cada gesto orienta, ningún píxel se pierde.”

