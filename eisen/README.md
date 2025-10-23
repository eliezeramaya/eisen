# Eisenhower Treemap Flutter

Interactive, performant Eisenhower Matrix as a squarified treemap. Built with Flutter 3.x, Riverpod, go_router, and a custom layout/painter. Liquid-glass aesthetic, AA+ accessible, and ready for Web/Mobile.

Highlights
- Custom squarified treemap (no external treemap packages)
- Riverpod state management with local persistence
- Liquid-glass theme via ThemeExtension tokens
- Keyboard shortcuts (desktop/web), gestures (tap/double-tap/drag)
- Tests (unit + widget) and GitHub Actions CI

## 🚀 Quick Start

### Prerequisites
- Flutter 3.35+ (stable)
- FVM (recommended for version management)
- Chrome (for web development)

### Setup with FVM (Recommended)
```bash
# First time setup
cd ~/timmr_eisen/eisen
./tools/fix_flutter_wsl.sh          # (WSL only) Repair environment
./tools/project_bootstrap.sh        # Setup FVM + dependencies

# Or manually
cd eisenhower_treemap_flutter
fvm install stable
fvm use stable
fvm flutter pub get
```

### Development
```bash
# Web (Chrome)
fvm flutter run -d chrome

# Tests
fvm flutter test
fvm flutter test test/golden/  # Golden tests only

# Analysis
fvm flutter analyze

# Build production
fvm flutter build web --release
```

### Without FVM
```bash
flutter pub get
flutter run -d chrome
flutter test
```

### Scripts
- `scripts/dev_web.sh` - Launch web dev server (auto Chrome detection)
- `tools/quick_verify.sh` - Quick environment check
- `tools/dev_env_check.sh` - Full environment validation

## 📁 Project Structure
- `lib/app`: App shell, router
- `lib/core`: Theme, a11y, utils, services, responsive
- `lib/features/eisen_matrix`: Domain, data, presentation
- `l10n`: ARB files (en/es)
- `test/`: Unit, widget, and golden tests
- `tools/`: Environment setup and validation scripts
- `docs/`: Architecture, theme tokens, troubleshooting

## 📖 Documentation
- `docs/ARCHITECTURE.md` - System architecture and patterns
- `docs/THEME_TOKENS.md` - Design system and theming
- `docs/RESPONSIVE_GUIDE.md` - Responsive design guidelines
- `docs/flutter_env_troubleshooting.md` - WSL/Flutter setup guide
- `docs/FLUTTER_ENV_REPORT.md` - Environment diagnostic report

## 🛠️ Environment & Configuration
- Copy `.env.example` to `.env` to override `CHROME_EXECUTABLE` and `WEB_RENDERER`
- `scripts/dev_web.sh` tries Chrome first and falls back to `web-server`
- WSL users: See `docs/flutter_env_troubleshooting.md` for setup guide
- FVM configuration in `.vscode/settings.json` for VS Code integration


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
