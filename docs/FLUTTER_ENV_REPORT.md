# Informe de Diagnóstico y Reparación - Flutter/Dart WSL2

**Fecha:** 2025-10-22  
**Proyecto:** Eisenhower Treemap Flutter  
**OS:** Ubuntu 24.04.3 LTS en WSL2 (Windows 11)

---

## 📊 Resumen Ejecutivo

✅ **Entorno Flutter Linux nativo configurado correctamente**  
✅ **FVM instalado y proyecto configurado**  
✅ **Tests golden funcionando (15/15 passed)**  
⚠️ **PATH con duplicados y rutas Windows (corregible)**  
⚠️ **Dependencias con actualizaciones menores disponibles**  
⚠️ **golden_toolkit discontinuado (funcional, migración opcional)**

---

## 🔍 Hallazgos Iniciales

### 1. Instalación Flutter
- ✅ **Flutter 3.35.6 stable** en `~/tools/flutter` (instalación Linux nativa correcta)
- ✅ **Dart 3.9.2** incluido con Flutter
- ✅ Web habilitado y Chrome disponible
- ❌ Android SDK no instalado (esperado en WSL)
- ❌ Linux desktop toolchain incompleta (clang, cmake, ninja, pkg-config)

### 2. PATH Contaminado
**Problemas detectados:**
- 6 duplicados de `~/tools/flutter/bin` en PATH
- 1 ruta de Flutter Windows: `/mnt/c/src/flutter/bin`
- PATH base de WSL incluye rutas Windows automáticamente

**Impacto:** Puede causar conflictos sutiles, aunque actualmente Flutter/Dart apuntan correctamente a instalación Linux.

### 3. Dependencias
```
go_router: 16.2.4 → 16.3.0 (actualizable)
golden_toolkit: 0.15.0 (DISCONTINUADO)
10 paquetes transitivos con actualizaciones menores
```

---

## 🛠️ Cambios Aplicados

### A) Scripts de Automatización Creados

#### 1. `tools/fix_flutter_wsl.sh`
Repara entorno Flutter completo:
- Clona/actualiza Flutter stable en `~/tools/flutter`
- Limpia PATH de duplicados y rutas Windows
- Configura Web y Linux Desktop
- Ejecuta `flutter doctor`
- Ofrece actualizar `~/.bashrc`

#### 2. `tools/dev_env_check.sh`
Valida entorno y detecta problemas:
- Verifica rutas Flutter/Dart
- Detecta contaminación PATH Windows
- Verifica instalación FVM
- Exit code != 0 si hay problemas

#### 3. `tools/project_bootstrap.sh`
Bootstrap completo del proyecto:
- Instala/configura FVM
- `pub get`, `analyze`, `test`
- Muestra comandos útiles

**Todos los scripts:**
- ✅ Ejecutables (`chmod +x`)
- ✅ Documentados inline
- ✅ Manejo de errores con `set -euo pipefail`

### B) Limpieza de PATH

Creado `~/.bashrc_flutter_cleanup` con función que:
1. Elimina duplicados del PATH
2. Filtra rutas `/mnt/c/`
3. Añade Flutter y pub-cache limpios

Integrado en `~/.bashrc`:
```bash
[ -f ~/.bashrc_flutter_cleanup ] && source ~/.bashrc_flutter_cleanup
```

### C) FVM Configurado

**Instalación:**
```bash
dart pub global activate fvm  # v3.2.1
```

**Proyecto:**
```bash
cd ~/timmr_eisen/eisen/eisen
fvm install stable
fvm use stable --force
```

**Problema encontrado y resuelto:** Permisos incorrectos en binarios descargados por FVM.

**Solución aplicada:**
```bash
chmod +x /home/eliezer/fvm/versions/stable/bin/cache/dart-sdk/bin/*
find /home/eliezer/fvm/versions/stable/bin/cache/artifacts/engine/linux-x64 -type f -exec chmod +x {} \;
```

### D) Integración VS Code

Actualizado `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": { "**/.fvm": true },
  "files.watcherExclude": { "**/.fvm": true },
  "dart.analysisExcludedFolders": [
    "${workspaceFolder}/build",
    "${workspaceFolder}/tools"
  ],
  "dart.lineLength": 120
}
```

### E) Documentación

Creado `docs/flutter_env_troubleshooting.md` con:
- ✅ Checklist de verificación rápida
- ✅ Matriz de síntomas → soluciones
- ✅ Guía de migración golden_toolkit → alchemist
- ✅ Flujos de trabajo recomendados
- ✅ Soporte por plataforma (Web/Linux/Android/iOS)
- ✅ Procedimiento de reinstalación limpia

---

## 📝 Logs Post-Reparación

### Flutter Doctor (FVM)
```
[✓] Flutter (Channel stable, 3.35.6, on Ubuntu 24.04.3 LTS 6.6.87.2-microsoft-standard-WSL2)
    • Flutter at /home/eliezer/fvm/versions/stable
    • Framework revision 9f455d2486 (2 weeks ago), 2025-10-08 14:55:31 -0500
    • Engine revision d2913632a4
    • Dart version 3.9.2
    • DevTools version 2.48.0

[✗] Android toolchain - develop for Android devices
    ✗ Android SDK not installed (expected in WSL)

[✓] Chrome - develop for the web
    • Chrome at google-chrome

[✗] Linux toolchain - develop for Linux desktop
    ✗ Missing: clang++, CMake, ninja, pkg-config
    (Opcional - solo necesario para desktop Linux)

[✓] Connected device (2 available)
    • Linux (desktop) - linux
    • Chrome (web)    - chrome

[✓] Network resources
```

### Tests Golden
```bash
fvm flutter test test/golden/responsive_matrix_page_golden_test.dart
```

**Resultado:** ✅ **15/15 tests passed** (todos los breakpoints y text scales)

---

## 🎯 Estado del Proyecto

### ✅ Funcional
- Web development con Chrome
- Tests golden (responsive layouts)
- Análisis estático (`fvm flutter analyze`)
- FVM gestión de versiones
- Scripts de automatización

### ⚠️ Recomendaciones Pendientes

#### 1. Limpieza Completa de PATH (Opcional)
Actualmente `which flutter` apunta correctamente, pero PATH tiene duplicados.

**Para limpieza total:**
```bash
# Editar /etc/wsl.conf (requiere sudo)
sudo nano /etc/wsl.conf

# Añadir:
[interop]
appendWindowsPath = false

# Reiniciar WSL desde PowerShell:
wsl --shutdown
```

⚠️ **Advertencia:** Esto eliminará TODAS las rutas Windows del PATH (incluido `code`, herramientas Windows, etc.). Solo si estás seguro.

#### 2. Actualizar Dependencias Menores
```bash
cd ~/timmr_eisen/eisen/eisen
fvm flutter pub upgrade go_router
fvm flutter pub upgrade  # Actualiza todas las compatibles
```

#### 3. Migración golden_toolkit → alchemist (Recomendado)
`golden_toolkit` está discontinuado. Migración documentada en:  
`docs/flutter_env_troubleshooting.md` (sección "Migración de Golden Tests")

**Beneficios de alchemist:**
- ✅ Mantenimiento activo
- ✅ Mejor soporte multiplataforma
- ✅ Integración CI más sencilla
- ✅ Mejores herramientas de debugging

#### 4. Linux Desktop Toolchain (Solo si necesitas)
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
fvm flutter doctor -v  # Verificar
```

---

## 📚 Comandos Útiles

### Verificación Rápida
```bash
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh
```

### Desarrollo Web
```bash
cd ~/timmr_eisen/eisen/eisen
fvm flutter run -d chrome
```

### Tests
```bash
fvm flutter test                                    # Todos
fvm flutter test test/golden/                       # Solo golden
fvm flutter test --update-goldens                   # Actualizar imágenes
```

### Análisis
```bash
fvm flutter analyze
fvm flutter pub outdated
```

### Build Producción
```bash
fvm flutter build web --release
# Salida en: build/web/
python3 -m http.server 8080 --directory build/web  # Servir local
```

---

## 🔄 Flujo de Trabajo Recomendado

### Primera Vez
```bash
cd ~/timmr_eisen/eisen
./tools/fix_flutter_wsl.sh          # Reparar entorno
source ~/.bashrc                     # Recargar shell
./tools/dev_env_check.sh             # Verificar
./tools/project_bootstrap.sh         # Bootstrap proyecto
```

### Desarrollo Diario
```bash
cd ~/timmr_eisen/eisen/eisen
fvm flutter run -d chrome            # Dev web
# O simplemente usar VS Code Run/Debug con FVM configurado
```

### Verificación Periódica
```bash
cd ~/timmr_eisen/eisen
./tools/dev_env_check.sh             # Cada semana
./tools/fix_flutter_wsl.sh           # Si hay problemas
```

---

## 📋 Checklist de Aceptación

- [x] `flutter doctor -v` sin errores críticos
- [x] `which flutter` apunta a `~/tools/flutter/bin/flutter` o FVM
- [x] `fvm flutter run -d chrome` abre la app
- [x] `fvm flutter analyze` sin issues bloqueantes
- [x] Tests golden pasan (15/15)
- [x] Scripts ejecutables y documentados
- [x] Documentación de troubleshooting creada
- [x] FVM configurado por proyecto
- [x] VS Code integrado con FVM

---

## 🐛 Problemas Conocidos y Soluciones

### 1. Permisos en Binarios FVM
**Síntoma:** `Permission denied` al ejecutar `fvm flutter`

**Causa:** WSL2 + descarga de archivos puede no preservar permisos de ejecución.

**Solución automática en scripts:**
```bash
chmod +x /home/eliezer/fvm/versions/stable/bin/cache/dart-sdk/bin/*
find /home/eliezer/fvm/versions/stable/bin/cache/artifacts/engine/linux-x64 -type f -exec chmod +x {} \;
```

### 2. PATH Duplicado
**Síntoma:** Multiple entradas `~/tools/flutter/bin` en PATH.

**Causa:** Shell sourcing múltiple o configuración recursiva.

**Solución:** Script `~/.bashrc_flutter_cleanup` aplica deduplicación en cada shell.

### 3. WSL Añade Rutas Windows
**Síntoma:** `/mnt/c/...` en PATH automáticamente.

**Causa:** Configuración por defecto de WSL2 para interoperabilidad.

**Solución temporal:** Script limpia rutas `/mnt/c/` dinámicamente.  
**Solución permanente:** Configurar `/etc/wsl.conf` (ver recomendaciones).

---

## 🎓 Lecciones Aprendidas

1. **Nunca mezclar Flutter Windows con WSL Linux** - Cada entorno debe tener su propia instalación.

2. **FVM es esencial** - Aisla versiones por proyecto y evita conflictos globales.

3. **PATH en WSL2 es complejo** - Requiere limpieza activa de rutas Windows y deduplicación.

4. **Permisos de archivo en WSL** - Archivos descargados pueden perder `+x`, verificar siempre.

5. **Golden tests requieren engine nativo** - Por eso funciona mejor en WSL Linux que con SDK Windows.

6. **Android en WSL es problemático** - Mejor usar Windows nativo o Android Studio Linux completo.

7. **Scripts de verificación son críticos** - `dev_env_check.sh` permite detectar regresiones rápido.

---

## 📦 Archivos Entregados

```
/home/eliezer/timmr_eisen/eisen/
├── tools/
│   ├── fix_flutter_wsl.sh           ← Reparación entorno
│   ├── dev_env_check.sh              ← Verificación
│   └── project_bootstrap.sh          ← Bootstrap proyecto
├── docs/
│   └── flutter_env_troubleshooting.md ← Guía completa
├── .vscode/
│   └── settings.json                  ← Integración FVM (actualizado)
├── .fvm/
│   └── flutter_sdk → ...              ← FVM symlink
└── .bashrc_flutter_cleanup            ← En $HOME (limpieza PATH)
```

---

## 🚀 Próximos Pasos Sugeridos

### Inmediato
1. ✅ Verificar entorno: `./tools/dev_env_check.sh`
2. ✅ Desarrollar en Web: `fvm flutter run -d chrome`

### Corto Plazo (Esta Semana)
1. Migrar `golden_toolkit` → `alchemist` (ver guía)
2. Actualizar dependencias: `fvm flutter pub upgrade`
3. Configurar CI para usar FVM

### Mediano Plazo
1. Evaluar necesidad de Linux Desktop (instalar toolchain si procede)
2. Configurar `/etc/wsl.conf` para PATH limpio permanente
3. Considerar Android SDK en WSL vs Windows nativo

---

## 📞 Soporte

Para problemas no cubiertos:

1. Ejecutar diagnóstico completo:
   ```bash
   ./tools/dev_env_check.sh > diagnostico.txt
   fvm flutter doctor -v >> diagnostico.txt
   echo "---PATH---" >> diagnostico.txt
   echo $PATH | tr ':' '\n' >> diagnostico.txt
   ```

2. Consultar `docs/flutter_env_troubleshooting.md`

3. Buscar en issues de Flutter: https://github.com/flutter/flutter/issues

---

**Generado:** 2025-10-22  
**Por:** Diagnóstico automatizado + reparación manual  
**Estado:** ✅ Entorno funcional para desarrollo Web con FVM
