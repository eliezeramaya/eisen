#!/usr/bin/env bash
# fix_flutter_wsl.sh
# Corrige entorno Flutter/Dart en WSL2 para desarrollo Web/Desktop Linux
set -euo pipefail

FLUTTER_HOME="${HOME}/tools/flutter"
FLUTTER_CHANNEL="stable"

echo "🔍 Diagnóstico y reparación de Flutter en WSL2"
echo "================================================"

# 1. Verificar si Flutter ya existe
if [[ ! -d "$FLUTTER_HOME" ]]; then
    echo "⬇️  Clonando Flutter ${FLUTTER_CHANNEL}..."
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" "$FLUTTER_HOME"
else
    echo "✅ Flutter ya existe en $FLUTTER_HOME"
    cd "$FLUTTER_HOME"
    echo "📦 Actualizando Flutter..."
    git checkout "$FLUTTER_CHANNEL"
    git pull origin "$FLUTTER_CHANNEL"
fi

# 2. Limpiar PATH de duplicados y Windows
echo "🧹 Limpiando PATH de duplicados y rutas Windows..."
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/mnt/c/' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')

# 3. Añadir Flutter al PATH (solo si no está)
if [[ ":$PATH:" != *":${FLUTTER_HOME}/bin:"* ]]; then
    export PATH="${FLUTTER_HOME}/bin:$PATH"
fi

# 4. Verificar instalación
echo "🔎 Verificando Flutter/Dart..."
which flutter
which dart
flutter --version
dart --version

# 5. Limpiar cachés antiguos
echo "🧼 Limpiando cachés..."
flutter clean || true

# 6. Configurar targets
echo "⚙️  Configurando targets Web y Linux Desktop..."
flutter config --enable-web
flutter config --enable-linux-desktop

# 7. Precache assets
echo "📥 Descargando artefactos para Web..."
flutter precache --web --force

# 8. Doctor
echo "🩺 Flutter Doctor..."
flutter doctor -v

# 9. Instalar dependencias Linux Desktop (opcional, requiere sudo)
echo ""
echo "📝 Para habilitar Linux Desktop, instala dependencias:"
echo "   sudo apt update"
echo "   sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev"

# 10. Actualizar .bashrc si es necesario
BASHRC="${HOME}/.bashrc"
if ! grep -q "export PATH=\"\$HOME/tools/flutter/bin:\$PATH\"" "$BASHRC" 2>/dev/null; then
    echo ""
    read -p "¿Añadir Flutter al PATH permanente en ~/.bashrc? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "" >> "$BASHRC"
        echo "# Flutter SDK (WSL Linux)" >> "$BASHRC"
        echo "export PATH=\"\$HOME/tools/flutter/bin:\$PATH\"" >> "$BASHRC"
        echo "✅ PATH actualizado en ~/.bashrc (ejecuta 'source ~/.bashrc')"
    fi
fi

echo ""
echo "✅ Reparación completada. Ejecuta './tools/dev_env_check.sh' para validar."
