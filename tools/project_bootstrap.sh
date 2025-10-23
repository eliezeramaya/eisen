#!/usr/bin/env bash
# project_bootstrap.sh
# Bootstrap completo del proyecto con FVM, deps, análisis y tests
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/eisenhower_treemap_flutter" || cd "$PROJECT_ROOT"

echo "🚀 Bootstrap del proyecto Eisenhower Treemap"
echo "=============================================="

# 1. Verificar entorno
if ! command -v flutter &>/dev/null; then
    echo "❌ Flutter no encontrado. Ejecuta './tools/fix_flutter_wsl.sh' primero"
    exit 1
fi

# 2. Instalar/activar FVM si no existe
if ! command -v fvm &>/dev/null; then
    echo "📦 Instalando FVM..."
    dart pub global activate fvm
    export PATH="$HOME/.pub-cache/bin:$PATH"
fi

# 3. Configurar FVM para el proyecto
echo "🔧 Configurando FVM..."
if [[ ! -d ".fvm" ]]; then
    fvm install stable
    fvm use stable --force
else
    echo "   FVM ya configurado"
fi

# 4. Obtener dependencias
echo "📥 Obteniendo dependencias..."
fvm flutter pub get

# 5. Análisis estático
echo "🔍 Análisis estático..."
fvm flutter analyze || {
    echo "⚠️  Se encontraron issues en el análisis (continúa)"
}

# 6. Tests unitarios
echo "🧪 Ejecutando tests..."
fvm flutter test || {
    echo "⚠️  Algunos tests fallaron (continúa)"
}

# 7. Verificar disponibilidad de Chrome
if fvm flutter devices | grep -q chrome; then
    echo "✅ Chrome disponible para desarrollo web"
    echo ""
    echo "🌐 Para lanzar en Chrome:"
    echo "   cd $(basename "$PWD")"
    echo "   fvm flutter run -d chrome"
else
    echo "⚠️  Chrome no detectado"
fi

# 8. Verificar Linux desktop
if fvm flutter devices | grep -q linux; then
    echo "✅ Linux desktop disponible"
    echo ""
    echo "🐧 Para lanzar en Linux:"
    echo "   cd $(basename "$PWD")"
    echo "   fvm flutter run -d linux"
else
    echo "⚠️  Linux desktop no disponible (instala: clang, cmake, ninja-build, pkg-config, libgtk-3-dev)"
fi

echo ""
echo "✅ Bootstrap completado"
echo ""
echo "📝 Comandos útiles:"
echo "   fvm flutter run -d chrome          # Ejecutar en navegador"
echo "   fvm flutter test                   # Tests"
echo "   fvm flutter build web --release    # Build producción"
echo "   fvm flutter analyze                # Análisis estático"
