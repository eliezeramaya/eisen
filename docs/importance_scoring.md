# Importance Scoring

**Feature**: `features/importance/`  
**Estado**: ✅ Implementado y funcional  
**Última actualización**: Abril 2026  
**Last reviewed**: 2026-05-02

---

## Resumen

El módulo de Importance Scoring calcula un puntaje de importancia personalizado por tarea usando un motor híbrido Bayesiano + heurístico. Los pesos del modelo se sincronizan en Supabase para persistencia entre sesiones y dispositivos.

---

## Arquitectura

```
features/importance/
├── importance_service.dart     # Motor principal de scoring
├── providers.dart              # Riverpod providers
└── (bandit_service.dart)       # Referenciado pero pendiente implementación completa
    models/
    ├── importance_features.dart    # Feature vector por tarea
    └── importance_weights.dart     # Pesos Bayesianos (mu, sigma)
```

---

## ImportanceService

**Archivo**: `lib/features/importance/importance_service.dart`

### Responsabilidad

Combina señales explícitas del usuario, señales conductuales y contexto temporal para producir un score de importancia por tarea. El modelo aprende gradualmente de las acciones del usuario.

### Fórmula de score

$$\text{score} = \alpha \cdot e + \beta \cdot b + \gamma \cdot c$$

Donde:
- $e$ — señal explícita (`inTop3`): 1.0 si fue elegida en check-in, 0.0 si no
- $b$ — señal conductual (sigmoid sobre combinación lineal de features)
- $c$ — ajuste contextual (`contextFit`): qué tan bien encaja con el horario de foco
- $\alpha, \beta, \gamma$ — pesos aprendidos (`ImportanceWeights.mu[0,1,2]`)

### Señal conductual (`_behavioral`)

Combinación lineal con pesos fijos heurísticos, pasada por una función sigmoidea:

| Feature | Peso | Significado |
|---------|------|-------------|
| `deadlineSoon` | 2.0 | Vence pronto (0–1) |
| `focus7d` | 1.4 | Tiempo dedicado en últimos 7 días (0–1) |
| `snoozePenalty` | 1.0 | Penalización por posponer (0–1) |
| `editsNorm` | 0.8 | Cantidad normalizada de ediciones (0–1) |
| `recencyView` | 0.6 | Recencia de última visualización (0–1) |
| `textHint` | 1.0 | Señales textuales de urgencia (0–1) |

$$b = \sigma(2.0 \cdot \text{deadlineSoon} + 1.4 \cdot \text{focus7d} + \ldots)$$

---

## Aprendizaje Bayesiano (Online)

### `updateWeights`

Actualiza los pesos $\mu$ (media) y $\Sigma$ (matriz de covarianza) con la señal de reward del usuario (interacción con la tarea recomendada):

$$\Sigma_{ij} \mathrel{+}= x_i \cdot x_j$$
$$\mu_i \mathrel{+}= 0.1 \cdot (\text{reward} - \mu_i) \cdot x_i$$

Donde $x = [e, b, c]$ son las tres señales normalizadas.

Después de actualizar, sincroniza con Supabase.

---

## Sincronización Supabase

### Tabla: `importance_weights`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `user_id` | string | ID del usuario |
| `mu` | array[3] | Medias de los pesos $[\alpha, \beta, \gamma]$ |
| `sigma` | array[3][3] | Matriz de covarianza 3×3 |
| `updated_at` | timestamp | Última actualización |

La operación usa `upsert` (INSERT o UPDATE por `user_id`). Los errores de red se capturan silenciosamente para no interrumpir la UX.

---

## Explicabilidad (`explain`)

El servicio genera etiquetas legibles para mostrar al usuario por qué una tarea fue sugerida:

| Condición | Explicación mostrada |
|-----------|---------------------|
| `deadlineSoon > 0.7` | "Vence pronto" |
| `focus7d > 0.6` | "Le has dedicado tiempo" |
| `inTop3 == true` | "Elegida en tu check-in" |
| `contextFit > 0.7` | "Coincide con tu horario de foco" |
| (ninguna) | "Sugerida por equilibrio semanal" |

---

## Providers (Riverpod)

**Archivo**: `lib/features/importance/providers.dart`

| Provider | Tipo | Descripción |
|----------|------|-------------|
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Cliente Supabase singleton |
| `banditProvider` | `Provider<BanditService>` | Servicio bandit para selección de acciones |
| `importanceServiceProvider` | `Provider<ImportanceService>` | Motor de scoring inyectado con Supabase + Ref |

---

## Modelos de Datos

### `ImportanceFeatures`
Vector de features por tarea. Todos los campos son `double` en rango `[0, 1]`:
- `inTop3` (bool): si fue elegida explícitamente
- `deadlineSoon`, `focus7d`, `snoozePenalty`, `editsNorm`, `recencyView`, `textHint`
- `contextFit`: ajuste con el perfil de horario del usuario

### `ImportanceWeights`
Pesos del modelo Bayesiano:
- `userId` (String): dueño de los pesos
- `mu` (List<double>, 3): medias $[\alpha, \beta, \gamma]$
- `sigma` (List<List<double>>, 3×3): matriz de covarianza

---

## Extensiones Futuras

- **Modelo offline-first**: cachear los pesos localmente (Isar/SharedPreferences) para funcionar sin conexión.
- **Historial de rewards**: guardar el historial de interacciones para análisis y debugging.
- **Integración UI**: superficie de score en la vista de tarea o en sugerencias de la pantalla principal.
- **A/B testing de fórmulas**: probar variantes del modelo heurístico contra el Bayesiano.
- **BanditService completo**: integrar `bandit_service.dart` para selección de acciones dentro del contexto de importancia.
