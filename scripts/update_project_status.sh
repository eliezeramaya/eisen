#!/bin/bash
# Script para actualizar automáticamente project_status.md
# Analiza el estado del proyecto y actualiza métricas

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS_FILE="$PROJECT_ROOT/docs/project_status.md"
TEMP_FILE="$PROJECT_ROOT/docs/project_status.md.tmp"

# El código Flutter está en el subdirectorio eisen/
FLUTTER_ROOT="$PROJECT_ROOT/eisen"

echo "🔍 Analizando estado del proyecto..."
echo "📁 Proyecto: $PROJECT_ROOT"
echo "📁 Flutter: $FLUTTER_ROOT"

# Navegar al directorio del proyecto Flutter
cd "$FLUTTER_ROOT"

# ============================================================================
# 1. ANÁLISIS DE CÓDIGO
# ============================================================================

echo "📊 Contando líneas de código..."

# Contar LOC en lib/
LOC_LIB=$(find lib -name "*.dart" -type f -exec wc -l {} + 2>/dev/null | tail -n 1 | awk '{print $1}' || echo "0")

# Contar archivos Dart
DART_FILES=$(find lib -name "*.dart" -type f | wc -l)

# Contar archivos de test
TEST_FILES=$(find test -name "*.dart" -type f 2>/dev/null | wc -l || echo "0")

# Contar features (directorios en lib/features/)
FEATURES_COUNT=$(find lib/features -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l || echo "0")

echo "  ✓ LOC: $LOC_LIB"
echo "  ✓ Archivos Dart: $DART_FILES"
echo "  ✓ Tests: $TEST_FILES"
echo "  ✓ Features: $FEATURES_COUNT"

# ============================================================================
# 2. ANÁLISIS DE TESTS
# ============================================================================

echo "🧪 Analizando cobertura de tests..."

# Contar tests unitarios
UNIT_TESTS=$(find test/unit -name "*_test.dart" -type f 2>/dev/null | wc -l || echo "0")

# Contar tests de widget
WIDGET_TESTS=$(find test/widget -name "*_test.dart" -type f 2>/dev/null | wc -l || echo "0")

# Contar golden tests
GOLDEN_TESTS=$(find test/golden -name "*_test.dart" -type f 2>/dev/null | wc -l || echo "0")

echo "  ✓ Unit tests: $UNIT_TESTS"
echo "  ✓ Widget tests: $WIDGET_TESTS"
echo "  ✓ Golden tests: $GOLDEN_TESTS"

# ============================================================================
# 3. ANÁLISIS GIT
# ============================================================================

echo "📝 Obteniendo información Git..."

CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")

# Obtener última fecha de commit
LAST_COMMIT_DATE=$(git log -1 --format=%cd --date=format:'%d de %B %Y' 2>/dev/null || date '+%d de %B %Y')

echo "  ✓ Commit: $CURRENT_COMMIT"
echo "  ✓ Branch: $CURRENT_BRANCH"
echo "  ✓ Commits: $COMMIT_COUNT"

# ============================================================================
# 4. ANÁLISIS DE FEATURES COMPLETADOS
# ============================================================================

echo "🎯 Analizando features completados..."

# Contar features que tienen al menos un archivo de presentación
FEATURES_COMPLETED=$(find lib/features -maxdepth 2 -type d -name "presentation" 2>/dev/null | wc -l || echo "0")
FEATURES_TOTAL=15  # Total features esperados según roadmap

# Calcular porcentaje de manera segura
if [ "$FEATURES_TOTAL" -gt 0 ]; then
    PROGRESS_PERCENT=$(( (FEATURES_COMPLETED * 100) / FEATURES_TOTAL ))
else
    PROGRESS_PERCENT=0
fi

echo "  ✓ Features completados: $FEATURES_COMPLETED/$FEATURES_TOTAL ($PROGRESS_PERCENT%)"

# ============================================================================
# 5. ACTUALIZAR project_status.md
# ============================================================================

echo "✏️  Actualizando $STATUS_FILE..."

if [ ! -f "$STATUS_FILE" ]; then
    echo "❌ Error: $STATUS_FILE no existe"
    exit 1
fi

# Crear copia temporal
cp "$STATUS_FILE" "$TEMP_FILE"

# Actualizar commit hash
sed -i "s/Commit \`[a-f0-9]*\`/Commit \`$CURRENT_COMMIT\`/g" "$TEMP_FILE"

# Actualizar fecha de última actualización
CURRENT_DATE=$(date '+%d de %B %Y')
sed -i "s/\*\*Última actualización\*\*:.*/\*\*Última actualización\*\*: $CURRENT_DATE/g" "$TEMP_FILE"

# Actualizar métricas en sección 9.1
sed -i "s/LOC: ~[0-9,+]*/LOC: ~$LOC_LIB+/g" "$TEMP_FILE"
sed -i "s/Archivos: [0-9]+/Archivos: $DART_FILES+/g" "$TEMP_FILE"

# Actualizar progreso global (buscar patrón "Progreso Global: XX% completo")
sed -i "s/Progreso Global: [0-9]*% completo/Progreso Global: $PROGRESS_PERCENT% completo/g" "$TEMP_FILE"

# Actualizar conteo de tests
if grep -q "Unit tests: ⚠️" "$TEMP_FILE"; then
    sed -i "s/Unit tests: ⚠️ Parcial/Unit tests: ⚠️ $UNIT_TESTS archivos/g" "$TEMP_FILE"
fi

# Mover el archivo temporal al original
mv "$TEMP_FILE" "$STATUS_FILE"

echo "✅ Archivo actualizado exitosamente"

# ============================================================================
# 6. GENERAR RESUMEN
# ============================================================================

cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RESUMEN DE ACTUALIZACIÓN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Fecha:            $CURRENT_DATE
🔖 Commit:           $CURRENT_COMMIT
🌿 Branch:           $CURRENT_BRANCH

📈 Código:
   • LOC:            $LOC_LIB líneas
   • Archivos:       $DART_FILES archivos .dart
   • Features:       $FEATURES_COUNT módulos

🧪 Tests:
   • Unit:           $UNIT_TESTS archivos
   • Widget:         $WIDGET_TESTS archivos
   • Golden:         $GOLDEN_TESTS archivos

✅ Progreso:         $PROGRESS_PERCENT% completado
   • Completados:    $FEATURES_COMPLETED/$FEATURES_TOTAL features

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

echo ""
echo "🎉 Actualización completada"
