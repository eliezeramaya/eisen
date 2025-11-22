# 🛠️ Scripts de Automatización

Scripts de utilidad para el proyecto Eisen.

## 📋 Scripts Disponibles

### 1. `update_project_status.sh`
**Propósito:** Actualizar automáticamente las métricas en `docs/project_status.md`

**Uso:**
```bash
./scripts/update_project_status.sh
```

**Qué hace:**
- ✅ Analiza líneas de código (LOC)
- ✅ Cuenta archivos Dart y tests
- ✅ Calcula progreso de features
- ✅ Actualiza información Git
- ✅ Modifica `project_status.md` con nuevas métricas

**Automatización:**
- Se ejecuta automáticamente vía GitHub Actions
- Schedule diario a las 00:00 UTC
- También se ejecuta en cada push a `main`

Ver documentación completa en: [`docs/AUTO_UPDATE_STATUS.md`](../docs/AUTO_UPDATE_STATUS.md)

---

## 📝 Agregar Nuevo Script

1. Crear archivo en `scripts/`:
```bash
touch scripts/mi_script.sh
chmod +x scripts/mi_script.sh
```

2. Agregar shebang y set -e:
```bash
#!/bin/bash
set -e

# Tu código aquí
```

3. Documentar en este README

4. Si necesita automatización, crear workflow en `.github/workflows/`

---

## 🔧 Convenciones

- **Permisos**: Todos los scripts deben tener permisos de ejecución (`chmod +x`)
- **Error handling**: Usar `set -e` para fallar rápido
- **Output**: Usar emojis para mejor legibilidad (🔍 📊 ✅ ❌)
- **Variables**: Definir rutas al inicio del script
- **Documentación**: Comentar secciones complejas

---

## 🚀 Próximos Scripts

Ideas para futuros scripts de automatización:

- [ ] `run_coverage.sh` - Generar reporte de cobertura
- [ ] `check_todos.sh` - Encontrar TODOs/FIXMEs en el código
- [ ] `bump_version.sh` - Incrementar versión automáticamente
- [ ] `generate_changelog.sh` - Generar CHANGELOG desde commits
- [ ] `validate_pr.sh` - Validaciones pre-merge
- [ ] `deploy_staging.sh` - Deploy a ambiente de staging
