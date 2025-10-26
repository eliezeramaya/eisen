# Cambios Aplicados - Diagnóstico Flutter/Dart WSL2

## 📝 Resumen de Cambios

### Desktop Settings (+ Preview) y mejoras de painter

- Nueva pantalla de Ajustes de escritorio (`/settings`) con Sidebar/Content/Footer y Live Preview opcional en pantallas ≥1280 px.
- Atajos globales (desktop): `Cmd+,` (macOS) / `Ctrl+,` (Windows/Linux).
- Apply/Cancel/Reset: Apply persiste en `UiPrefsController` y fuerza recomputo inmediato del treemap; Cancel revierte staged; Reset carga defaults (requiere Apply).
- Live Preview: mini‑treemap alimentado por valores staged (Top‑K, Gamma, Min Area, Padding).
- Painter: líneas divisorias de cuadrantes con `outlineVariant` 28%, borde hairline 1 px en tiles, overlay 8% en hover/focus, placas de cuadrante opcionales (surfaceContainerLow) y snap threshold en lerp para reducir micro‑vibración.
- Placeholders por cuadrante cuando está vacío, con copy guía.

### Nuevos Archivos Creados

#### Scripts de Automatización (`tools/`)

1. **`tools/fix_flutter_wsl.sh`** (242 líneas)
   - Clona/actualiza Flutter stable en `~/tools/flutter`
   - Limpia PATH de duplicados y rutas Windows
   - Configura Web/Desktop targets
   - Ejecuta `flutter doctor` y precache
   - Ofrece actualizar `~/.bashrc` interactivamente

2. **`tools/dev_env_check.sh`** (108 líneas)
   - Valida que Flutter/Dart apunten a Linux nativo
   - Detecta contaminación PATH con rutas `/mnt/c/`
   - Verifica duplicados en PATH
   - Comprueba instalación FVM
   - Exit code != 0 si hay problemas

3. **`tools/project_bootstrap.sh`** (92 líneas)
   - Instala/activa FVM si no existe
   - Configura FVM en proyecto (`fvm use stable`)
   - Ejecuta `pub get`, `analyze`, `test`
   - Muestra comandos útiles y dispositivos disponibles

4. **`tools/quick_verify.sh`** (51 líneas)
   - Verificación rápida one-shot
   - Valida Flutter, Dart, FVM, Chrome
   - Muestra estado del proyecto FVM
   - Lista comandos inmediatos

**Permisos:** Todos ejecutables (`chmod +x`)

#### Documentación (`docs/`)

1. **`docs/flutter_env_troubleshooting.md`** (~450 líneas)
   - Guía completa de diagnóstico y solución
   - Checklist de verificación rápida
   - 7 síntomas comunes + soluciones
   - Guía de migración `golden_toolkit` → `alchemist`
   - Configuración FVM + VS Code
   - Flujos de trabajo recomendados
   - Matriz de soporte por plataforma
   - Procedimiento de reinstalación limpia

2. **`docs/FLUTTER_ENV_REPORT.md`** (~420 líneas)
   - Informe completo de diagnóstico
   - Hallazgos iniciales detallados
   - Cambios aplicados (A-E)
   - Logs post-reparación
   - Estado del proyecto
   - Recomendaciones pendientes
   - Checklist de aceptación
   - Problemas conocidos y soluciones
   - Lecciones aprendidas

#### Configuración Sistema (`~/`)

1. **`~/.bashrc_flutter_cleanup`**
   ```bash
   # Función clean_path() que:
   # - Elimina duplicados del PATH
   # - Filtra rutas /mnt/c/
   # - Añade Flutter y pub-cache limpios
   ```

2. **`~/.bashrc`** (modificado)
   - Añadida línea: `[ -f ~/.bashrc_flutter_cleanup ] && source ~/.bashrc_flutter_cleanup`

---

### Archivos Modificados

#### 1. `eisen/.vscode/settings.json`

**Antes:**
```json
{
  "dart.flutterSdkPath": ".fvm/versions/stable",
  "dart.sdkPath": "tools/flutter/bin/cache/dart-sdk",
  "dart.analysisExcludedFolders": [
    "${workspaceFolder}/build",
    "${workspaceFolder}/tools"
  ]
}
```

**Después:**
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  },
  "dart.analysisExcludedFolders": [
    "${workspaceFolder}/build",
    "${workspaceFolder}/tools"
  ],
  "dart.lineLength": 120
}
```

**Cambios:**
- ✅ Actualizado path FVM a symlink estándar `.fvm/flutter_sdk`
- ✅ Excluido directorio `.fvm` de búsqueda y watchers (mejora performance)
- ✅ Añadido `dart.lineLength: 120` para consistencia

#### 2. `eisen/README.md`

**Antes:**
```markdown
Getting started
- flutter pub get
- scripts/dev_web.sh (debug) or scripts/dev_web.sh --release
- flutter test

Structure
- lib/app: app shell, router
- lib/core: theme, a11y, utils, services
[...]
```

**Después:**
```markdown
## 🚀 Quick Start

### Prerequisites
- Flutter 3.35+ (stable)
- FVM (recommended for version management)
- Chrome (for web development)

### Setup with FVM (Recommended)
[comandos fvm detallados]

### Development
[comandos con fvm para run/test/analyze/build]

### Without FVM
[comandos flutter tradicionales]

### Scripts
- `scripts/dev_web.sh` - Launch web dev server
- `tools/quick_verify.sh` - Quick environment check
- `tools/dev_env_check.sh` - Full environment validation

## 📁 Project Structure
[estructura actualizada con tools/ y docs/]

## 📖 Documentation
- `docs/ARCHITECTURE.md`
- `docs/THEME_TOKENS.md`
- `docs/RESPONSIVE_GUIDE.md`
- `docs/flutter_env_troubleshooting.md` ← NUEVO
- `docs/FLUTTER_ENV_REPORT.md` ← NUEVO

## 🛠️ Environment & Configuration
[instrucciones FVM, WSL, VS Code]
```

**Cambios:**
- ✅ Añadida sección Quick Start con FVM
- ✅ Documentados todos los nuevos scripts
- ✅ Referencias a documentación de troubleshooting
- ✅ Comandos con `fvm flutter` como primarios

---

### Archivos Generados (FVM)

#### Proyecto
- `eisen/.fvm/` - Configuración FVM local
- `eisen/.fvmrc` - Archivo de configuración FVM (versión stable)
- `eisen/.gitignore` - Actualizado para excluir `.fvm/` (recomendado)

#### Sistema
- `~/fvm/versions/stable/` - Flutter stable gestionado por FVM
- `~/.pub-cache/bin/fvm` - Ejecutable FVM global

---

## 🔧 Configuración FVM Aplicada

### Global
```bash
dart pub global activate fvm  # v3.2.1
export PATH="$HOME/.pub-cache/bin:$PATH"  # Añadido a bashrc_flutter_cleanup
```

### Proyecto
```bash
cd ~/timmr_eisen/eisen/eisen
fvm install stable       # Descarga Flutter stable
fvm use stable --force   # Configura proyecto
```

### Permisos Reparados
```bash
# Dart SDK
chmod +x ~/fvm/versions/stable/bin/cache/dart-sdk/bin/*

# Engine Linux
find ~/fvm/versions/stable/bin/cache/artifacts/engine/linux-x64 -type f -exec chmod +x {} \;
```

**Causa del problema:** WSL2 + descarga de archivos no preserva permisos de ejecución.

---

## 📊 Impacto y Beneficios

### Antes
- ❌ PATH contaminado con duplicados y rutas Windows
- ❌ Sin gestión de versiones Flutter por proyecto
- ❌ Configuración VS Code apuntando a paths incorrectos
- ❌ Sin scripts de diagnóstico/reparación
- ❌ Sin documentación de troubleshooting WSL

### Después
- ✅ PATH limpio dinámicamente en cada shell
- ✅ FVM gestiona versiones Flutter por proyecto
- ✅ VS Code integrado correctamente con FVM
- ✅ 4 scripts ejecutables de automatización
- ✅ 2 documentos completos de troubleshooting
- ✅ README actualizado con quick start FVM
- ✅ Tests golden funcionando (15/15 passed)

---

## 🎯 Validación Final

### Entorno
```bash
$ which flutter
/home/eliezer/tools/flutter/bin/flutter

$ which dart
/home/eliezer/tools/flutter/bin/dart

$ fvm --version
3.2.1

$ flutter --version
Flutter 3.35.6 • channel stable
Dart 3.9.2
```

### Proyecto
```bash
$ cd ~/timmr_eisen/eisen/eisen && fvm flutter --version
Flutter 3.35.6 • channel stable (via FVM)

$ fvm flutter test test/golden/responsive_matrix_page_golden_test.dart
00:14 +15: All tests passed!
```

### Scripts
```bash
$ ./tools/quick_verify.sh
✅ Flutter: 3.35.6
✅ Dart: 3.9.2
✅ FVM: v3.2.1
✅ FVM configurado en proyecto

$ ./tools/dev_env_check.sh
✅ Flutter OK: /home/eliezer/tools/flutter/bin/flutter
✅ Dart OK: /home/eliezer/tools/flutter/bin/dart
✅ FVM instalado: 3.2.1
✅ Entorno validado correctamente
```

---

## 📦 Archivos para Commit

### Staging Actual
```
A  docs/FLUTTER_ENV_REPORT.md
A  docs/flutter_env_troubleshooting.md
M  eisen/.vscode/settings.json
M  eisen/README.md
A  tools/dev_env_check.sh
A  tools/fix_flutter_wsl.sh
A  tools/project_bootstrap.sh
A  tools/quick_verify.sh
```

### Recomendado Añadir
```bash
git add eisen/.fvmrc                    # Configuración FVM del proyecto
echo ".fvm/" >> eisen/.gitignore        # Excluir versión Flutter local
git add eisen/.gitignore
```

### NO Commitear
- `~/.bashrc`
- `~/.bashrc_flutter_cleanup`
- `~/fvm/` (instalación local del usuario)

**Razón:** Configuraciones específicas del usuario/máquina.

---

## 🚀 Mensaje de Commit Sugerido

```
chore(devex): Add Flutter/Dart WSL2 environment setup and FVM integration

- Add 4 automation scripts for environment repair and validation
  - tools/fix_flutter_wsl.sh: Complete Flutter setup for WSL2
  - tools/dev_env_check.sh: Environment validation with exit codes
  - tools/project_bootstrap.sh: FVM setup + dependencies + tests
  - tools/quick_verify.sh: One-shot quick verification

- Add comprehensive documentation
  - docs/flutter_env_troubleshooting.md: Complete WSL2 setup guide
  - docs/FLUTTER_ENV_REPORT.md: Diagnostic and repair report

- Configure FVM (Flutter Version Management) for project
  - Update .vscode/settings.json for FVM SDK path
  - Add FVM configuration (.fvmrc)
  - Update README with FVM quick start

- Fix PATH cleanup for WSL2
  - Remove Windows Flutter paths contamination
  - Remove duplicates dynamically
  - Add ~/.bashrc_flutter_cleanup (user-specific)

- Update README.md
  - Add FVM setup instructions
  - Document new scripts
  - Add troubleshooting references

Impact:
  ✅ Environment validated (Flutter 3.35.6, Dart 3.9.2, FVM 3.2.1)
  ✅ Golden tests passing (15/15)
  ✅ Reproducible setup for new developers
  ✅ CI-ready (use FVM in GitHub Actions)

Refs: #responsive-audit, #devex-wsl2-flutter
```

---

## 📚 Próximos Pasos Recomendados

1. **Commit y Push** de cambios actuales
2. **CI Integration**: Actualizar GitHub Actions para usar FVM
3. **Migración golden_toolkit**: Seguir guía en `flutter_env_troubleshooting.md`
4. **Actualización dependencias**: `fvm flutter pub upgrade`
5. **PATH permanente**: Evaluar configurar `/etc/wsl.conf` (opcional)

---

**Generado:** 2025-10-22  
**Cambios aplicados por:** Diagnóstico y reparación automatizada Flutter/Dart WSL2
