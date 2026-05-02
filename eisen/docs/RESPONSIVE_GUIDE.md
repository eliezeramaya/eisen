# Responsive Design Guide

**Last reviewed**: 2026-05-02

This document summarizes the responsive system adopted by the app.

## Breakpoints (DeviceClass)

| Nombre | Ancho | Uso |
|---|---|---|
| compact | < 600 px | móvil |
| medium | 600–904 px | tablet chica / móvil landscape |
| expanded | 905–1239 px | tablet / escritorio chico |
| large | ≥ 1240 px | escritorio |

Ver `lib/core/responsive/app_breakpoints.dart` y `responsive_extensions.dart`.

```dart
// Leer el DeviceClass actual
final dc = context.deviceClass;
if (dc.isCompact) { /* móvil */ }
if (dc.isExpandedUp) { /* tablet o mayor */ }
```

## Layout Tokens

- Spacing (8pt grid): 4, 8, 12, 16, 24, 32, 48
- Radius: 8, 12, 20
- Touch targets: 48x48 (mobile), ≥40x40 (desktop)

Ver `lib/core/responsive/layout_tokens.dart`.

## Adaptive Scaffold (AppShell)

La navegación global vive en `AppShell` (`lib/app/app_shell.dart`), que usa `ResponsiveScaffold` internamente:

- **compact / medium**: Bottom NavigationBar
- **expanded**: NavigationRail
- **large**: Sidebar permanente (NavigationDrawer)

Las páginas principales (`MatrixPage`, `FocusDashboardPage`, `StatsPage`, `SettingsScreen`) reciben `useShellNavigation: true` cuando son hospedadas por `AppShell`, suprimiendo sus propias acciones de navegación.

Ver `lib/core/responsive/responsive_scaffold.dart` y `lib/app/app_shell.dart`.