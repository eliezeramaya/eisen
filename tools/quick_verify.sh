#!/usr/bin/env bash
# quick_verify.sh - Verificación rápida one-shot del entorno
set -euo pipefail

echo "🚀 Verificación Rápida Flutter/Dart/FVM"
echo "========================================"
echo ""

# 1. Flutter
if flutter --version &>/dev/null; then
    echo "✅ Flutter: $(flutter --version 2>&1 | head -1)"
else
    echo "❌ Flutter no disponible"
    exit 1
fi

# 2. Dart
if dart --version &>/dev/null; then
    echo "✅ Dart: $(dart --version 2>&1 | head -1)"
else
    echo "❌ Dart no disponible"
    exit 1
fi

# 3. FVM
if command -v fvm &>/dev/null; then
    echo "✅ FVM: v$(fvm --version)"
else
    echo "⚠️  FVM no instalado"
fi

# 4. Chrome
if flutter devices 2>/dev/null | grep -q chrome; then
    echo "✅ Chrome disponible para Web"
else
    echo "⚠️  Chrome no detectado"
fi

# 5. FVM en proyecto
if [[ -d ".fvm" ]]; then
    echo "✅ FVM configurado en proyecto"
    echo "   Use: fvm flutter run -d chrome"
else
    echo "ℹ️  FVM no configurado en proyecto actual"
fi

echo ""
echo "🎯 Estado: Listo para desarrollo"
echo ""
echo "Comandos rápidos:"
echo "  fvm flutter run -d chrome     # Ejecutar en navegador"
echo "  fvm flutter test               # Tests"
echo "  fvm flutter analyze            # Análisis estático"
echo "  ./tools/dev_env_check.sh       # Diagnóstico completo"
