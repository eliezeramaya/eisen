# Responsive Design Guide

This document summarizes the responsive system adopted by the app.

## Breakpoints

- xs: < 600
- sm: 600–904
- md: 905–1239
- lg: 1240–1439
- xl: ≥ 1440

See `lib/core/responsive/app_breakpoints.dart` and `responsive_extensions.dart`.

## Layout Tokens

- Spacing (8pt grid): 4, 8, 12, 16, 24, 32, 48
- Radius: 8, 12, 20
- Touch targets: 48x48 (mobile), ≥40x40 (desktop)

See `lib/core/responsive/layout_tokens.dart`.

## Adaptive Scaffold

Use `ResponsiveScaffold` for screens with app-wide navigation:

- xs/sm: Bottom NavigationBar
- md: NavigationRail
- lg/xl: Sidebar (NavigationDrawer) + AppBar

File: `lib/core/responsive/responsive_scaffold.dart`.

## Testing

Golden tests exercise five breakpoints and three text scales (1.0, 1.3, 1.6).

Run:

- flutter test
- flutter test --update-goldens (to refresh)

File: `test/golden/responsive_matrix_page_golden_test.dart`.