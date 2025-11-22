# Flutter Environment Troubleshooting (WSL2)

![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue) ![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Linux-green) ![WSL2](https://img.shields.io/badge/WSL2-Ubuntu%2024.04-orange)

**Última actualización:** 21 Noviembre 2025

## 🎯 Guía de Diagnóstico y Solución

Esta guía te ayudará a resolver problemas comunes de Flutter/Dart en WSL2, especialmente cuando hay conflictos entre instalaciones de Windows y Linux.

---

## 📑 Índice

- [Quick Fix (TL;DR)](#-quick-fix-tldr)
- [Verificación Rápida](#-checklist-de-verificación-rápida)
- [Problemas Comunes](#-síntomas-comunes-y-soluciones)
- [Migración Golden Tests](#-migración-de-golden-tests-golden_toolkit--alchemist)
- [Scripts de Automatización](#-scripts-de-automatización)
- [Flujos de Trabajo](#-flujo-de-trabajo-recomendado)
- [CI/CD](#-configuración-cicd-github-actions)
- [FAQ](#-faq-preguntas-frecuentes)
- [Troubleshooting Específico Eisen](#-troubleshooting-específico-del-proyecto-eisen)

---

## ⚡ Quick Fix (TL;DR)

**Si solo quieres verificar que todo funciona:**

```bash
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh  # ¿Todo verde? → Listo ✅
```

**Si hay problemas:**

```bash
./tools/fix_flutter_wsl.sh  # Reparación automática
source ~/.bashrc
./tools/dev_env_check.sh    # Verificar
```

**Desarrollo diario con FVM (recomendado):**

```bash
cd ~/timmr_eisen/eisen/eisen
fvm flutter run -d chrome  # Web dev
fvm flutter test           # Tests
```

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

### Tabla de Diagnóstico Rápido

| Síntoma | Causa Probable | Solución Rápida | Detalle |
|---------|----------------|-----------------|---------|
| `Permission denied` al ejecutar `fvm flutter` | Permisos FVM incorrectos | `./tools/fix_flutter_wsl.sh` | [Ver §7](#7-fvm-gestión-de-versiones-por-proyecto) |
| `No such file or directory .../dart` | Flutter Windows en PATH | Limpiar PATH + script | [Ver §1](#1-error-no-such-file-or-directory-bincachedart-sdkbindart) |
| PATH con duplicados | `.bashrc` mal configurado | Limpiar `.bashrc` | [Ver §2](#2-path-con-duplicados-o-múltiples-instalaciones) |
| Android toolchain missing | Normal en WSL para Web | Ignorar o instalar Android | [Ver §3](#3-flutter-doctor-android-toolchain-missing) |
| Missing clang, cmake, ninja | Linux toolchain incompleta | `apt install` dependencias | [Ver §4](#4-linux-desktop-missing-clang-cmake-ninja-pkg-config) |
| Flutter cache corrupto | Archivos SDK dañados | `git clean -xfd` | [Ver §5](#5-flutter-cache-corrupto) |
| Warnings `golden_toolkit` | Paquete discontinuado | Migrar a `alchemist` | [Ver migración](#-migración-de-golden-tests-golden_toolkit--alchemist) |

---

### 1. Error: "No such file or directory .../bin/cache/dart-sdk/bin/dart"

**Causa:** Flutter/Dart de Windows (`/mnt/c/...`) mezclado con WSL Linux.

**Solución:**
```bash
# Opción 1: Con script automático (recomendado)
./tools/fix_flutter_wsl.sh

# Opción 2: Manual - Limpiar ~/.bashrc de rutas Windows
nano ~/.bashrc
# Eliminar líneas como: export PATH="/mnt/c/src/flutter/bin:$PATH"

# Recargar y verificar
source ~/.bashrc
./tools/dev_env_check.sh
```

**Validación:**
```bash
which flutter  # Debe mostrar: /home/eliezer/tools/flutter/bin/flutter
which dart     # Debe mostrar: /home/eliezer/tools/flutter/bin/dart
```

---

### 2. PATH con duplicados o múltiples instalaciones

**Síntoma:** `which flutter` muestra rutas repetidas o `/mnt/c/`.

**Solución:**
```bash
# Ver PATH desglosado para diagnóstico
echo $PATH | tr ':' '\n' | grep -E "(flutter|dart)"

# Limpiar ~/.bashrc
nano ~/.bashrc

# Debe tener SOLO esta línea de Flutter:
export PATH="$HOME/tools/flutter/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"  # Para FVM y herramientas Dart

# NO debe tener:
# - /mnt/c/src/flutter/bin
# - Duplicados de $HOME/tools/flutter/bin

# Recargar y validar
source ~/.bashrc
echo $PATH | tr ':' '\n' | grep flutter  # Debe aparecer UNA vez
```

**Script de limpieza automática:**

El proyecto incluye `~/.bashrc_flutter_cleanup` que elimina duplicados automáticamente. Asegúrate de tener en `~/.bashrc`:

```bash
[ -f ~/.bashrc_flutter_cleanup ] && source ~/.bashrc_flutter_cleanup
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

**¿Por qué usar FVM?**
- ✅ Versiones diferentes por proyecto
- ✅ CI/CD reproducible
- ✅ Sin conflictos globales
- ✅ Cambio rápido entre versiones

**Instalar FVM:**
```bash
dart pub global activate fvm

# Añadir a PATH si no está (verificar con: which fvm)
export PATH="$HOME/.pub-cache/bin:$PATH"
# Añadir a ~/.bashrc para permanencia
```

**Configurar proyecto:**
```bash
cd ~/timmr_eisen/eisen/eisen
fvm install stable      # Descarga Flutter stable
fvm use stable          # Configura proyecto (.fvmrc)

# Verificar
fvm flutter --version
```

**Comandos con FVM:**
```bash
# Desarrollo
fvm flutter run -d chrome
fvm flutter run -d linux

# Testing
fvm flutter test
fvm flutter test --update-goldens

# Análisis
fvm flutter analyze
fvm flutter pub outdated

# Build
fvm flutter build web --release
fvm flutter build linux --release
```

**Integración VS Code:**

El proyecto ya incluye `.vscode/settings.json` configurado:
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": { "**/.fvm": true },
  "files.watcherExclude": { "**/.fvm": true }
}
```

**Troubleshooting FVM:**
```bash
# Permisos incorrectos (común en WSL)
chmod +x ~/.fvm/versions/stable/bin/cache/dart-sdk/bin/*
find ~/.fvm/versions/stable/bin/cache/artifacts/engine/linux-x64 -type f -exec chmod +x {} \;

# Verificar configuración
fvm list                    # Versiones instaladas
fvm flutter doctor -v       # Diagnóstico completo
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

### Resumen de Scripts Disponibles

| Script | Propósito | Cuándo Usar |
|--------|-----------|-------------|
| `fix_flutter_wsl.sh` | Reparación completa entorno | Primera vez o problemas graves |
| `dev_env_check.sh` | Validación rápida | Cada semana o antes de trabajar |
| `project_bootstrap.sh` | Setup proyecto completo | Clone nuevo o reset |
| `quick_verify.sh` | Verificación one-shot | Diagnóstico rápido |

### fix_flutter_wsl.sh

**Funcionalidad:**
- Instala/actualiza Flutter stable en `~/tools/flutter`
- Limpia PATH de rutas Windows y duplicados
- Configura Web y Desktop targets
- Ejecuta `flutter doctor` y precache
- Ofrece actualizar `~/.bashrc` interactivamente

**Uso:**
```bash
cd ~/timmr_eisen/eisen
./tools/fix_flutter_wsl.sh

# El script preguntará si deseas:
# - Clonar Flutter (si no existe)
# - Actualizar Flutter (si existe)
# - Actualizar ~/.bashrc
```

### dev_env_check.sh

**Funcionalidad:**
- Valida que Flutter/Dart apunten a instalación Linux
- Detecta contaminación PATH con rutas `/mnt/c/`
- Verifica duplicados en PATH
- Comprueba instalación FVM
- **Exit code != 0 si hay problemas** (útil para CI)

**Uso:**
```bash
./tools/dev_env_check.sh

# En scripts CI:
if ! ./tools/dev_env_check.sh; then
  echo "Environment check failed"
  exit 1
fi
```

### project_bootstrap.sh

**Funcionalidad:**
- Instala/activa FVM si no existe
- Configura FVM en proyecto (`fvm use stable`)
- Ejecuta `pub get`, `analyze`, `test`
- Muestra comandos útiles y dispositivos disponibles

**Uso:**
```bash
cd ~/timmr_eisen/eisen
./tools/project_bootstrap.sh

# Automático en CI:
# - Detecta si FVM está instalado
# - Configura versión Flutter del proyecto
# - Valida que tests pasen
```

### quick_verify.sh

**Funcionalidad:**
- Verificación rápida one-shot
- Valida Flutter, Dart, FVM, Chrome
- Muestra estado del proyecto FVM
- Lista comandos inmediatos

**Uso:**
```bash
./tools/quick_verify.sh  # < 5 segundos
```

---

## 🎯 Flujo de Trabajo Recomendado

### Para Desarrolladores

#### 1. Primera vez (setup inicial)
```bash
cd ~/timmr_eisen/eisen

# Validar/reparar entorno
./tools/fix_flutter_wsl.sh
source ~/.bashrc

# Verificar
./tools/dev_env_check.sh

# Bootstrap proyecto
./tools/project_bootstrap.sh
```

#### 2. Desarrollo diario
```bash
cd ~/timmr_eisen/eisen/eisen

# Desarrollo Web (recomendado)
fvm flutter run -d chrome

# Tests durante desarrollo
fvm flutter test --watch

# Análisis estático
fvm flutter analyze

# Build producción
fvm flutter build web --release
# Salida en: build/web/
```

#### 3. Verificación periódica
```bash
# Cada semana o tras problemas
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh

# Si hay problemas
./tools/fix_flutter_wsl.sh
source ~/.bashrc
```

### Para DevOps/CI

```bash
# En CI pipeline (GitHub Actions, GitLab CI, etc.)
./tools/dev_env_check.sh || exit 1  # Validar entorno
./tools/project_bootstrap.sh        # Setup FVM + deps
cd eisen
fvm flutter test                    # Tests
fvm flutter analyze                 # Linting
fvm flutter build web --release     # Build
```

### Para Nuevos en el Proyecto

```bash
# Clone
git clone https://github.com/eliezeramaya/eisen.git
cd eisen

# Setup completo (one command)
./tools/fix_flutter_wsl.sh && \
source ~/.bashrc && \
./tools/project_bootstrap.sh

# Verificar que todo funciona
cd eisen
fvm flutter test

# Empezar a desarrollar
fvm flutter run -d chrome
```

---

## 🤖 Configuración CI/CD (GitHub Actions)

### Ejemplo workflow completo

Crear `.github/workflows/flutter-ci.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      # FVM Setup (recomendado)
      - uses: kuhnroyal/flutter-fvm-config-action@v2
        with:
          path: 'eisen'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version-file: eisen/.fvmrc
          cache: true
      
      # Alternativamente, usar scripts del proyecto
      - name: Validate environment
        run: |
          cd eisen
          ../tools/dev_env_check.sh
      
      - name: Bootstrap project
        run: ./tools/project_bootstrap.sh
      
      - name: Run tests
        run: |
          cd eisen
          fvm flutter test --coverage
      
      - name: Analyze
        run: |
          cd eisen
          fvm flutter analyze
      
      - name: Build web
        run: |
          cd eisen
          fvm flutter build web --release
      
      # Upload coverage (opcional)
      - uses: codecov/codecov-action@v4
        with:
          files: eisen/coverage/lcov.info
          
      # Upload artifacts
      - uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: eisen/build/web/
```

### Configuración mínima (sin FVM action)

```yaml
steps:
  - uses: actions/checkout@v4
  
  - name: Setup Flutter
    uses: subosito/flutter-action@v2
    with:
      channel: 'stable'
      cache: true
  
  - name: Install FVM
    run: dart pub global activate fvm
  
  - name: Configure project
    run: |
      cd eisen
      fvm install stable
      fvm use stable --force
  
  - name: Test
    run: |
      cd eisen
      fvm flutter test
```

---

## ❓ FAQ (Preguntas Frecuentes)

### General

**P: ¿Debo usar FVM o Flutter global?**  
R: **FVM recomendado**. Permite versiones diferentes por proyecto, evita conflictos y facilita CI reproducible.

**P: ¿Funciona en Windows nativo?**  
R: Sí, pero esta guía es específica para **WSL2 Ubuntu**. Para Windows nativo consulta [docs oficiales](https://docs.flutter.dev/get-started/install/windows).

**P: ¿Necesito Android SDK en WSL?**  
R: **No para Web/Desktop**. Si necesitas Android, mejor usa Windows nativo o instala Android Studio completo en Linux.

**P: ¿Cuánto espacio ocupa el setup completo?**  
R: ~2-3 GB (Flutter SDK + FVM + dependencias proyecto).

### Troubleshooting

**P: `flutter doctor` muestra Android toolchain missing, ¿es problema?**  
R: **No** si solo desarrollas para Web/Linux Desktop. Ignora el warning.

**P: ¿Cómo sé qué versión de Flutter usar?**  
R: El proyecto usa **FVM**. La versión está definida en `eisen/.fvmrc`. Usa `fvm flutter --version` dentro del proyecto.

**P: Tests golden fallan en CI pero pasan en local**  
R: Asegúrate de:
- Usar misma versión Flutter (FVM ayuda con esto)
- Mismas fonts instaladas
- Considerar usar `alchemist` que es más robusto para CI

**P: PATH sigue teniendo duplicados después de limpiar `.bashrc`**  
R: WSL añade rutas automáticamente. Usa el script `~/.bashrc_flutter_cleanup` que limpia dinámicamente cada vez que abres un shell.

### Desarrollo

**P: ¿Puedo usar hot reload en Web?**  
R: Sí, `fvm flutter run -d chrome` tiene hot reload completo.

**P: ¿Cómo desarrollo para Linux Desktop?**  
R: Instala toolchain (`sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev`) y ejecuta `fvm flutter run -d linux`.

**P: ¿Qué navegador usa Flutter Web por defecto?**  
R: Chrome/Chromium. Se puede configurar con `flutter run -d web-server` para cualquier navegador.

**P: ¿Cómo actualizo dependencias del proyecto?**  
R: `cd eisen && fvm flutter pub upgrade` (actualiza compatibles) o `fvm flutter pub upgrade --major-versions` (breaking changes).

---

## 🔧 Troubleshooting Específico del Proyecto Eisen

### Problemas con Treemap Rendering

**Síntoma:** Treemap no se renderiza correctamente o tiene glitches visuales.

**Causas comunes:**
- Flutter engine incorrecto (Windows en WSL)
- Canvas size cero
- Layout constraints incorrectos

**Solución:**
```bash
# Verificar engine
./tools/dev_env_check.sh

# Limpiar build cache
cd eisen
fvm flutter clean
fvm flutter pub get

# Verificar en Web (más estable)
fvm flutter run -d chrome --release
```

### Issues con Isar Database en WSL

**Síntoma:** Errores al abrir database o corrupciones.

**Causa:** Isar usa native bindings que pueden tener problemas de permisos en WSL.

**Solución:**
```bash
# Verificar permisos del proyecto
ls -la eisen/

# Si hay problemas, regenerar schemas
cd eisen
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Limpiar database local (desarrollo)
rm -rf .dart_tool/isar/
```

### Riverpod: Provider Updates Not Triggering

**Síntoma:** UI no se actualiza cuando cambia estado Riverpod.

**Causa común:** Hot reload puede no actualizar providers correctamente.

**Solución:**
```bash
# Hot restart (no solo reload)
# En VS Code: Ctrl+Shift+F5
# O desde terminal: 'R' durante flutter run

# Si persiste, rebuild completo
fvm flutter clean && fvm flutter run -d chrome
```

### Performance Issues en WSL

**Síntoma:** Build/test lentos en WSL vs Windows nativo.

**Optimizaciones:**
```bash
# 1. Asegurar proyecto en filesystem Linux (NO /mnt/c/)
pwd  # Debe mostrar /home/usuario/..., NO /mnt/c/...

# 2. Aumentar memoria WSL (.wslconfig en Windows)
# En Windows: C:\Users\TuUsuario\.wslconfig
[wsl2]
memory=8GB
processors=4

# 3. Usar build cache
export PUB_CACHE="$HOME/.pub-cache"

# 4. Excluir directorios en Windows Defender
# Añadir: C:\Users\TuUsuario\AppData\Local\Packages\CanonicalGroupLimited...
```

### Golden Tests: Diferencias entre Plataformas

**Síntoma:** Golden tests pasan en WSL pero fallan en macOS/Windows o viceversa.

**Causa:** Diferencias de rendering engine, fonts, antialiasing.

**Solución:**
```bash
# Opción 1: Generar goldens en CI (plataforma única)
# Ver sección CI/CD arriba

# Opción 2: Usar alchemist con platformGoldensConfig
# Ver sección de migración golden_toolkit → alchemist

# Opción 3: Tolerancia de diferencias
fvm flutter test --update-goldens --platform-specific  # Flag futuro
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

### Documentación Oficial
- [Flutter en WSL](https://docs.flutter.dev/get-started/install/linux) - Guía oficial instalación Linux
- [Flutter Web](https://docs.flutter.dev/platform-integration/web) - Específico desarrollo Web
- [FVM Documentation](https://fvm.app/) - Gestor versiones Flutter
- [Alchemist Package](https://pub.dev/packages/alchemist) - Golden tests modernos

### Herramientas Relacionadas
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
- [Dart Package Search](https://pub.dev/)

### Comunidad y Soporte
- [Flutter Discord](https://discord.gg/flutter)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
- [Stack Overflow - Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)

### Documentación del Proyecto Eisen
- `docs/ARCHITECTURE.md` - Arquitectura del proyecto
- `docs/project_status.md` - Estado actual y roadmap
- `docs/THEME_TOKENS.md` - Sistema de diseño
- `docs/RESPONSIVE_GUIDE.md` - Guía responsive layouts
- `docs/archive/` - Documentos históricos

---

## 🐛 Reportar Problemas

Si encuentras un problema no cubierto en esta guía:

### 1. Ejecuta diagnóstico completo
```bash
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh > diagnostico.txt
fvm flutter doctor -v >> diagnostico.txt 2>&1
echo "---PATH---" >> diagnostico.txt
echo $PATH | tr ':' '\n' >> diagnostico.txt
echo "---FVM---" >> diagnostico.txt
fvm list >> diagnostico.txt 2>&1
echo "---VERSIONS---" >> diagnostico.txt
flutter --version >> diagnostico.txt 2>&1
dart --version >> diagnostico.txt 2>&1
```

### 2. Incluye información del sistema
```bash
echo "---SYSTEM---" >> diagnostico.txt
uname -a >> diagnostico.txt
lsb_release -a >> diagnostico.txt 2>&1
echo "---DISK---" >> diagnostico.txt
df -h ~ >> diagnostico.txt
```

### 3. Crea issue en GitHub
- Adjunta `diagnostico.txt`
- Describe el problema específico
- Indica pasos para reproducir
- Menciona qué has intentado

---

**Última actualización:** 21 Noviembre 2025  
**Mantenedores:** Equipo Eisen  
**Licencia:** MIT
