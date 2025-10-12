# Eisenhower Treemap Flutter

Interactive, performant Eisenhower Matrix as a squarified treemap. Built with Flutter 3.x, Riverpod, go_router, and a custom layout/painter. Liquid-glass aesthetic, AA+ accessible, and ready for Web/Mobile.

Highlights
- Custom squarified treemap (no external treemap packages)
- Riverpod state management with local persistence
- Liquid-glass theme via ThemeExtension tokens
- Keyboard shortcuts (desktop/web), gestures (tap/double-tap/drag)
- Tests (unit + widget) and GitHub Actions CI

Getting started
- flutter pub get
- flutter run -d chrome (or your device)
- flutter test

Structure
- lib/app: app shell, router
- lib/core: theme, a11y, utils, services
- lib/features/matrix: domain, application, presentation, infra
- l10n: ARB files (en/es)

Docs
- See docs/ARCHITECTURE.md and docs/THEME_TOKENS.md


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
