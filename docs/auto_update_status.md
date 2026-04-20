# 🤖 Actualización Automática de Project Status

Sistema automatizado para mantener actualizado `docs/project_status.md` con métricas del proyecto.

## 📋 Componentes

### 1. Script de Actualización
**Archivo:** `scripts/update_project_status.sh`

**Funciones:**
- ✅ Analiza líneas de código (LOC)
- ✅ Cuenta archivos Dart y features
- ✅ Analiza cobertura de tests (unit/widget/golden)
- ✅ Obtiene información Git (commit, branch, fecha)
- ✅ Calcula progreso de features
- ✅ Actualiza métricas en `project_status.md`
- ✅ Genera resumen de cambios

**Uso manual:**
```bash
./scripts/update_project_status.sh
```

### 2. GitHub Action
**Archivo:** `.github/workflows/update-project-status.yml`

**Triggers:**
- 🕐 **Diariamente a las 00:00 UTC** (9:00 PM El Salvador)
- 🚀 **Push a main** en archivos relevantes (`lib/`, `test/`, `pubspec.yaml`)
- 🔧 **Manual** via workflow_dispatch

**Proceso:**
1. Checkout del repositorio
2. Ejecuta script de análisis
3. Detecta cambios en `project_status.md`
4. Commit automático si hay cambios
5. Push al branch actual
6. Genera resumen en GitHub Actions

## 🎯 Métricas Actualizadas Automáticamente

### En Sección 1.2 - Header
- ✅ Commit hash actual
- ✅ Fecha de última actualización

### En Sección 9.1 - Estado Actual
- ✅ **LOC** (Lines of Code)
- ✅ **Archivos** Dart totales
- ✅ **Progreso Global** (% completado)
- ✅ **Tests** (conteo de archivos)

## 🔧 Configuración

### Permisos Requeridos
El workflow necesita:
- ✅ `contents: write` - Para hacer commit y push

### Variables Personalizables

En `scripts/update_project_status.sh`:
```bash
FEATURES_TOTAL=15  # Total de features esperados
```

## 📊 Ejemplo de Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RESUMEN DE ACTUALIZACIÓN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Fecha:            21 de Noviembre 2025
🔖 Commit:           db8b9f2
🌿 Branch:           main

📈 Código:
   • LOC:            15000 líneas
   • Archivos:       55 archivos .dart
   • Features:       8 módulos

🧪 Tests:
   • Unit:           28 archivos
   • Widget:         5 archivos
   • Golden:         3 archivos

✅ Progreso:         78% completado
   • Completados:    5/15 features

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🚀 Ejecución Manual

### Localmente
```bash
cd /home/eliezer/timmr_eisen/eisen
./scripts/update_project_status.sh
```

### GitHub Actions UI
1. Ve a **Actions** → **Update Project Status Daily**
2. Click **Run workflow**
3. Selecciona branch y ejecuta

## 📝 Commit Automático

Cuando detecta cambios, hace commit con:
```
🤖 Auto-update project status [2025-11-21]

- Updated metrics and progress
- Automated daily update
```

## 🔍 Verificación

Para verificar que funciona:
```bash
# 1. Ejecutar script
./scripts/update_project_status.sh

# 2. Ver cambios
git diff docs/project_status.md

# 3. Si hay cambios, commit manual para probar
git add docs/project_status.md
git commit -m "test: verificar auto-update"
```

## ⚠️ Notas Importantes

1. **Primer run**: El workflow se activará después del push a `main`
2. **Schedule**: Corre a las 00:00 UTC diariamente
3. **Solo actualiza si hay cambios**: No hace commits vacíos
4. **Preserva formato**: Usa `sed` para actualizar solo números específicos

## 🔄 Mantenimiento

### Agregar Nueva Métrica

1. Editar `scripts/update_project_status.sh`:
```bash
# Calcular nueva métrica
NEW_METRIC=$(calcular_algo)

# Actualizar en archivo
sed -i "s/PatternToMatch: [0-9]*/PatternToMatch: $NEW_METRIC/g" "$TEMP_FILE"
```

2. Commit cambios:
```bash
git add scripts/update_project_status.sh
git commit -m "feat: add new metric tracking"
```

### Cambiar Frecuencia

Editar `.github/workflows/update-project-status.yml`:
```yaml
schedule:
  # Cada 12 horas
  - cron: '0 */12 * * *'
  
  # Cada lunes a las 9:00 UTC
  - cron: '0 9 * * 1'
```

## 🎨 Personalización

El script puede extenderse para:
- ✅ Analizar cobertura de código con `lcov`
- ✅ Calcular complejidad ciclomática
- ✅ Detectar TODOs/FIXMEs
- ✅ Analizar dependencias obsoletas
- ✅ Generar changelog automático
- ✅ Notificar en Slack/Discord

## 📚 Referencias

- [GitHub Actions Cron Syntax](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)
- [Git Automation Best Practices](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
