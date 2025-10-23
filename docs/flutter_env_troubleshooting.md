# Flutter Environment Troubleshooting (WSL2)

## 🎯 Guía de Diagnóstico y Solución

Esta guía te ayudará a resolver problemas comunes de Flutter/Dart en WSL2, especialmente cuando hay conflictos entre instalaciones de Windows y Linux.

---

## 📋 Checklist de Verificación Rápida

Ejecuta el script de verificación:
```bash
./tools/dev_env_check.sh
```

Si todo está OK, deberías ver:
- ✅ Flutter apuntando a `~/tools/flutter/bin/flutter`
- ✅ Dart apuntando a `~/tools/flutter/bin/dart`
- ✅ Sin rutas `/mnt/c/` en PATH
- ✅ FVM instalado

---

## 🔍 Síntomas Comunes y Soluciones

### 1. Error: "No such file or directory .../bin/cache/dart-sdk/bin/dart"

**Causa:** Flutter/Dart de Windows (`/mnt/c/...`) mezclado con WSL Linux.

**Solución:**
```bash
# Ejecutar script de reparación
./tools/fix_flutter_wsl.sh

# Limpiar ~/.bashrc de rutas Windows
nano ~/.bashrc
# Eliminar líneas como: export PATH="/mnt/c/src/flutter/bin:$PATH"

# Recargar
source ~/.bashrc
./tools/dev_env_check.sh
```

---

### 2. PATH con duplicados o múltiples instalaciones

**Síntoma:** `which flutter` muestra rutas repetidas o `/mnt/c/`.

**Solución:**
```bash
# Ver PATH desglosado
echo $PATH | tr ':' '\n'

# Limpiar ~/.bashrc
nano ~/.bashrc

# Debe tener SOLO esta línea de Flutter:
export PATH="$HOME/tools/flutter/bin:$PATH"

# NO debe tener:
# - /mnt/c/src/flutter/bin
# - Duplicados de $HOME/tools/flutter/bin

# Recargar
source ~/.bashrc
```

---

### 3. Flutter Doctor: Android toolchain missing

**Causa:** Android SDK no disponible en WSL (normal para Web/Desktop).

**Solución:** Ignora este error si solo desarrollas para Web/Linux Desktop.

Para Android, usa **Windows nativo** o instala Android Studio en WSL:
```bash
# Solo si necesitas Android en WSL
sudo apt update
sudo apt install -y openjdk-17-jdk
# Descarga Android Studio Linux y configura SDK
flutter config --android-sdk /path/to/android-sdk
```

---

### 4. Linux Desktop: Missing clang, cmake, ninja, pkg-config

**Síntoma:** `flutter doctor` muestra errores de Linux toolchain.

**Solución:**
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev

# Verificar
flutter doctor -v
```

---

### 5. Flutter cache corrupto

**Síntomas:**
- Errores extraños de SDK
- Archivos faltantes en `bin/cache/`
- Comportamiento inconsistente

**Solución:**
```bash
cd ~/tools/flutter
git clean -xfd
git pull origin stable
flutter doctor -v
flutter precache --web --force
```

---

### 6. Dependencias desactualizadas (golden_toolkit discontinuado)

**Síntoma:** Warnings sobre paquetes discontinuados.

**Solución:**
```bash
cd ~/timmr_eisen/eisen/eisen/eisenhower_treemap_flutter

# Ver estado
flutter pub outdated

# Opción 1: Mantener golden_toolkit (funciona pero sin soporte)
# Sin cambios necesarios

# Opción 2: Migrar a alchemist (recomendado)
# Ver sección de migración abajo
```

---

### 7. FVM: Gestión de versiones por proyecto

**Instalar FVM:**
```bash
dart pub global activate fvm
export PATH="$HOME/.pub-cache/bin:$PATH"
```

**Configurar proyecto:**
```bash
cd ~/timmr_eisen/eisen/eisen/eisenhower_treemap_flutter
fvm install stable
fvm use stable

# Usar comandos con FVM
fvm flutter run -d chrome
fvm flutter test
fvm flutter analyze
```

**Integración VS Code:**
Añadir a `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  }
}
```

---

## 🔄 Migración de Golden Tests: golden_toolkit → alchemist

### ¿Por qué migrar?

`golden_toolkit` está **discontinuado** y no recibirá actualizaciones. `alchemist` es la alternativa moderna mantenida activamente con mejores features:
- Soporte multiplataforma (Web, Desktop, Mobile)
- Mejores herramientas de debugging
- Integración CI más sencilla

### Pasos de migración

**1. Actualizar `pubspec.yaml`:**
```yaml
dev_dependencies:
  # golden_toolkit: ^0.15.0  # REMOVER
  alchemist: ^0.8.0           # AÑADIR
```

**2. Crear configuración de Alchemist:**
```bash
# Crear archivo test/flutter_test_config.dart
cat > test/flutter_test_config.dart << 'EOF'
import 'dart:async';
import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(
        enabled: true,
      ),
    ),
    run: testMain,
  );
}
EOF
```

**3. Ejemplo de test golden con Alchemist:**
```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eisen/app/app.dart';

void main() {
  goldenTest(
    'MatrixPage responsive layouts',
    fileName: 'matrix_page',
    builder: () => GoldenTestGroup(
      children: [
        // XS - Mobile
        GoldenTestScenario(
          name: 'xs_mobile_1x',
          constraints: const BoxConstraints(maxWidth: 390, maxHeight: 844),
          child: const EisenApp(),
        ),
        // SM - Tablet portrait
        GoldenTestScenario(
          name: 'sm_tablet_1x',
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: const EisenApp(),
        ),
        // MD - Tablet landscape
        GoldenTestScenario(
          name: 'md_tablet_landscape',
          constraints: const BoxConstraints(maxWidth: 1024, maxHeight: 768),
          child: const EisenApp(),
        ),
        // LG - Desktop
        GoldenTestScenario(
          name: 'lg_desktop',
          constraints: const BoxConstraints(maxWidth: 1366, maxHeight: 900),
          child: const EisenApp(),
        ),
        // XL - Large desktop
        GoldenTestScenario(
          name: 'xl_large_desktop',
          constraints: const BoxConstraints(maxWidth: 1600, maxHeight: 1024),
          child: const EisenApp(),
        ),
      ],
    ),
  );
}
```

**4. Ejecutar tests:**
```bash
fvm flutter test --update-goldens  # Generar nuevos goldens
fvm flutter test                   # Verificar
```

---

## 🚀 Scripts de Automatización

### fix_flutter_wsl.sh
Repara entorno Flutter completo:
- Instala/actualiza Flutter stable
- Limpia PATH de Windows
- Configura Web/Desktop
- Ejecuta doctor

### dev_env_check.sh
Valida entorno y detecta problemas:
- Verifica rutas Flutter/Dart
- Detecta contaminación PATH
- Muestra versiones

### project_bootstrap.sh
Bootstrap completo del proyecto:
- Configura FVM
- Instala dependencias
- Ejecuta tests
- Muestra comandos útiles

---

## 🎯 Flujo de Trabajo Recomendado

### 1. Primera vez (setup inicial)
```bash
cd ~/timmr_eisen/eisen
./tools/fix_flutter_wsl.sh
./tools/dev_env_check.sh
./tools/project_bootstrap.sh
```

### 2. Desarrollo diario
```bash
cd ~/timmr_eisen/eisen/eisen/eisenhower_treemap_flutter

# Desarrollo Web
fvm flutter run -d chrome

# Tests
fvm flutter test

# Análisis
fvm flutter analyze

# Build producción
fvm flutter build web --release
```

### 3. Verificación periódica
```bash
# Cada semana o tras problemas
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh

# Si hay problemas
./tools/fix_flutter_wsl.sh
```

---

## 📊 Matriz de Soporte por Plataforma

| Target | WSL2 | Recomendación |
|--------|------|---------------|
| **Web (Chrome)** | ✅ Full | **Desarrollo principal** |
| **Linux Desktop** | ✅ Full | Requiere deps nativas |
| **Android** | ⚠️ Limitado | Usar Windows nativo |
| **iOS** | ❌ No | Solo macOS |
| **Windows Desktop** | ⚠️ Limitado | Usar Windows nativo |

---

## 🆘 Última Opción: Reinstalación Limpia

Si nada funciona:
```bash
# Backup proyecto
cd ~
tar -czf eisen_backup.tar.gz timmr_eisen/

# Eliminar Flutter
rm -rf ~/tools/flutter
rm -rf ~/.flutter
rm -rf ~/.pub-cache

# Limpiar bashrc
nano ~/.bashrc
# Eliminar TODAS las líneas de Flutter/Dart

# Reinstalar desde cero
source ~/.bashrc
./tools/fix_flutter_wsl.sh
./tools/project_bootstrap.sh
```

---

## 📚 Recursos Adicionales

- [Flutter en WSL](https://docs.flutter.dev/get-started/install/linux)
- [FVM Documentation](https://fvm.app/)
- [Alchemist Package](https://pub.dev/packages/alchemist)
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)

---

## 🐛 Reportar Problemas

Si encuentras un problema no cubierto:

1. Ejecuta diagnóstico completo:
   ```bash
   ./tools/dev_env_check.sh > diagnostico.txt
   flutter doctor -v >> diagnostico.txt
   echo "---PATH---" >> diagnostico.txt
   echo $PATH | tr ':' '\n' >> diagnostico.txt
   ```

2. Adjunta `diagnostico.txt` al crear issue en el repositorio.

---

**Última actualización:** 2025-10-22
