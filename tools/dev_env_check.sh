#!/usr/bin/env bash
# dev_env_check.sh
# Valida que Flutter/Dart apunten a instalación Linux nativa (no Windows)
set -euo pipefail

EXIT_CODE=0

echo "🔍 Verificación de entorno Flutter/Dart en WSL2"
echo "================================================"

# 1. Verificar Flutter
FLUTTER_PATH=$(which flutter 2>/dev/null || echo "")
if [[ -z "$FLUTTER_PATH" ]]; then
    echo "❌ Flutter no encontrado en PATH"
    EXIT_CODE=1
elif [[ "$FLUTTER_PATH" == /mnt/c/* ]]; then
    echo "❌ Flutter apunta a Windows: $FLUTTER_PATH"
    echo "   💡 Ejecuta './tools/fix_flutter_wsl.sh' para corregir"
    EXIT_CODE=1
elif [[ "$FLUTTER_PATH" == "$HOME/tools/flutter/bin/flutter" ]]; then
    echo "✅ Flutter OK: $FLUTTER_PATH"
else
    echo "⚠️  Flutter encontrado en ruta no estándar: $FLUTTER_PATH"
fi

# 2. Verificar Dart
DART_PATH=$(which dart 2>/dev/null || echo "")
if [[ -z "$DART_PATH" ]]; then
    echo "❌ Dart no encontrado en PATH"
    EXIT_CODE=1
elif [[ "$DART_PATH" == /mnt/c/* ]]; then
    echo "❌ Dart apunta a Windows: $DART_PATH"
    EXIT_CODE=1
elif [[ "$DART_PATH" == "$HOME/tools/flutter/bin/dart" ]]; then
    echo "✅ Dart OK: $DART_PATH"
else
    echo "⚠️  Dart encontrado en ruta no estándar: $DART_PATH"
fi

# 3. Verificar contaminación PATH
WINDOWS_FLUTTER_COUNT=$(echo "$PATH" | tr ':' '\n' | grep -c '^/mnt/c/.*flutter' || true)
if [[ $WINDOWS_FLUTTER_COUNT -gt 0 ]]; then
    echo "⚠️  PATH contiene $WINDOWS_FLUTTER_COUNT ruta(s) Flutter de Windows:"
    echo "$PATH" | tr ':' '\n' | grep '^/mnt/c/.*flutter'
    echo "   💡 Limpia ~/.bashrc y elimina referencias a /mnt/c/..."
fi

# 4. Verificar duplicados
FLUTTER_BIN_COUNT=$(echo "$PATH" | tr ':' '\n' | grep -c '/flutter/bin' || true)
if [[ $FLUTTER_BIN_COUNT -gt 1 ]]; then
    echo "⚠️  PATH contiene $FLUTTER_BIN_COUNT duplicados de flutter/bin"
    echo "   💡 Limpia duplicados en ~/.bashrc"
fi

# 5. Versiones
echo ""
echo "📦 Versiones instaladas:"
flutter --version 2>&1 | head -1 || true
dart --version 2>&1 | head -1 || true

# 6. FVM
if command -v fvm &>/dev/null; then
    echo "✅ FVM instalado: $(fvm --version 2>&1 | head -1)"
else
    echo "⚠️  FVM no instalado (recomendado para gestión de versiones)"
    echo "   💡 Instala con: dart pub global activate fvm"
fi

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ Entorno validado correctamente"
else
    echo "❌ Se encontraron problemas. Ejecuta './tools/fix_flutter_wsl.sh'"
fi

exit $EXIT_CODE
