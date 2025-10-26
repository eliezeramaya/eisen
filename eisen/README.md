# Eisenhower Treemap Flutter

> Interactive, performant Eisenhower Matrix as a squarified treemap. Built with Flutter 3.x, Riverpod, and custom layout algorithms.

<p align="center">
  <a href="https://github.com/eliezeramaya/eisen/actions/workflows/ci.yaml"><img src="https://github.com/eliezeramaya/eisen/actions/workflows/ci.yaml/badge.svg" alt="CI Status"/></a>
  <img src="https://img.shields.io/badge/Flutter-3.35%2B-02569B?logo=flutter" alt="Flutter 3.35+"/>
  <img src="https://img.shields.io/badge/Dart-3.9%2B-0175C2?logo=dart" alt="Dart 3.9+"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Mobile-lightgrey" alt="Platform"/>
</p>

## ✨ Highlights

- 🎯 **Custom Squarified Treemap** - No external treemap packages, optimized for Eisenhower layout
- ⚡ **High Performance** - Path caching, incremental updates, sub-16ms layouts
- 🎨 **Liquid-Glass Theme** - Material 3 with custom tokens and WCAG AA accessibility
- 🧪 **Well Tested** - 40+ unit/widget tests, golden tests, CI/CD integration
- 🌍 **i18n Ready** - English/Spanish with ARB validation
- 🔐 **Privacy-First** - Opt-in telemetry with SHA-256 ID anonymization
- ♿ **Accessible** - WCAG 2.1 Level AA, keyboard shortcuts, screen reader support
- 📱 **Responsive** - Adaptive layouts for mobile, tablet, desktop, and web

## 🚀 Quick Start

### Prerequisites

- **Flutter**: 3.35+ stable (3.9.2+ recommended)
- **FVM**: Recommended for version management
- **Chrome**: For web development (or use `web-server` device)

### Setup

```bash
# Clone the repository
git clone https://github.com/eliezeramaya/eisen.git
cd eisen/eisenhower_treemap_flutter

# WSL2 only: Fix environment
./tools/fix_flutter_wsl.sh

# Install dependencies
flutter pub get

# Generate localizations
flutter gen-l10n

# Check environment
./tools/dev_env_check.sh
```

### Run

```bash
# Web (Chrome)
flutter run -d chrome
# or with script
./scripts/dev_web.sh

# Mobile (if device connected)
flutter run

# Web server (no Chrome needed)
flutter run -d web-server
```

### Development Workflow

```bash
# Run tests
flutter test                      # All tests
flutter test test/unit/           # Unit tests only
flutter test test/widget/         # Widget tests only
flutter test test/golden/         # Golden tests only

# Analysis
flutter analyze                   # Lint & static analysis
./scripts/validate_i18n.sh        # i18n validation

# Build
flutter build web --release       # Production web build
flutter build apk --release       # Android APK
flutter build ios --release       # iOS (macOS only)
```

## ⌨️ Atajos de Teclado / Keyboard Shortcuts

| Acción | Atajo (Web/Desktop) |
|---|---|
| Zoom en cuadrante | Doble clic/doble tap sobre cuadrante |
| Salir de zoom | `Esc` |
| Navegar tiles/selección | `←` `→` `↑` `↓` |
| Expandir stack “+N” | Clic/Tap sobre el chip “+N” del cuadrante |
| Seleccionar tile | Clic/Tap sobre tile |
| Editar tile | `Enter` sobre tile o icono editar |
| Crear nueva tarea | `N` o botón “+” |
| Eliminar tarea | `Delete` / `Backspace` |
| Buscar | `Ctrl/Cmd + F` |
| Ayuda | `?` |

Notas:
- En desktop, la navegación por teclado asume foco en el canvas/área de matriz.
- En móvil, prioriza gestos: tap para seleccionar, doble tap para zoom.

## 📐 Breakpoints (xs/sm/md/lg/xl)

| Nombre | Ancho | Densidad recomendada | TextScale recomendada | Uso |
|---|---|---|---|---|
| xs | <600 px | Cómoda (por defecto) | 1.0–1.3 (accesibilidad 1.6) | móvil chico |
| sm | 600–904 px | Cómoda | 1.0–1.3 (accesibilidad 1.6) | móvil grande / tablet chica |
| md | 905–1239 px | Cómoda | 1.0–1.3 (accesibilidad 1.6) | tablet |
| lg | 1240–1439 px | Compacta | 1.0–1.3 | desktop común |
| xl | ≥1440 px | Compacta | 1.0–1.3 | desktop amplio |

Referencias: lib/core/responsive/app_breakpoints.dart y docs/RESPONSIVE_GUIDE.md.
Recomendaciones:
- Targets táctiles mínimos: 48×48 px (móvil), ≥40×40 px (desktop).
- En pantallas lg/xl, activar “Compact” si se muestran muchas tareas.

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Golden Tests

**Run golden tests:**
```bash
flutter test test/golden/
```

**Regenerate golden images:**
```bash
# Delete existing goldens
rm -rf test/golden/goldens/

# Regenerate (will fail first time to create new goldens)
flutter test test/golden/ --update-goldens

# Or use the update flag on individual tests
flutter test test/golden/treemap_canvas_golden_test.dart --update-goldens
```

**Golden test workflow:**
1. Make UI changes
2. Run `flutter test test/golden/` - will fail if UI changed
3. Review diffs (goldens are committed to git)
4. If changes are correct: `flutter test test/golden/ --update-goldens`
5. Commit new golden images

**Note**: Golden tests are platform-specific. CI runs on Linux. For consistent results, regenerate on the same platform as CI.

## Modo Minimalista
Actívalo en Ajustes → “Modo minimalista”. Reduce cromo/ruido visual, bordes hairline y etiquetas en el treemap solo cuando interactúas (focus/hover/selección). Mantiene AA en texto y UI.

Goldens:
```bash
cd eisen
flutter test --update-goldens
```

### Mobile Branding (Launchers & Splash)

Comandos útiles (requiere assets en `assets/branding/`):

```bash
cd eisen

# Iconos adaptativos (usa config en pubspec.yaml)
flutter pub get
flutter pub run flutter_launcher_icons

# Splash (Android 12+ incluido)
flutter pub run flutter_native_splash:create
```

Asegúrate de ubicar:
- `assets/branding/icon.png`
- `assets/branding/icon_foreground.png`
- `assets/branding/splash.png`

#### Regeneración de goldens y política (ES)
- Regenerar goldens localmente:
  ```bash
  cd eisen
  flutter test --update-goldens
  ```
- Política de revisión: inspeccionar visualmente los difs y, si cambian, adjuntar capturas/before-after en la PR (los PNG de fallos suelen generarse bajo `test/**/failures/`).

### Test Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## 📁 Project Structure

```
lib/
├── app/                    # App shell, routing
│   ├── app.dart           # Root MaterialApp
│   └── router.dart        # go_router configuration
├── core/                   # Shared infrastructure
│   ├── a11y/              # Accessibility utilities
│   ├── constants/         # Layout, theme constants
│   ├── responsive/        # Responsive breakpoints
│   ├── services/          # Telemetry, storage, metrics
│   ├── theme/             # Theme tokens, colors, typography
│   ├── utils/             # Helpers, extensions
│   └── widgets/           # Reusable widgets
├── features/
│   ├── eisen_matrix/      # Core Eisenhower Matrix feature
│   │   ├── data/          # Repositories, persistence
│   │   ├── domain/        # Entities, business logic, treemap
│   │   │   ├── entities.dart
│   │   │   ├── treemap_layout.dart  # Squarified treemap
│   │   │   ├── bandit_service.dart  # Exploration/exploitation
│   │   │   └── usecases/  # Use case layer
│   │   └── presentation/  # UI, controllers, widgets
│   │       ├── controllers/
│   │       ├── pages/
│   │       └── widgets/
│   └── stats/             # Statistics & analytics feature
├── l10n/                   # Generated localizations
└── main.dart              # App entry point

test/
├── unit/                   # Unit tests
│   ├── core/              # Core utilities tests
│   ├── domain/            # Business logic tests
│   └── i18n/              # Localization tests
├── widget/                 # Widget tests
└── golden/                 # Golden screenshot tests

docs/
├── ARCHITECTURE.md         # System design, patterns
├── THEME_TOKENS.md        # Design system documentation
├── PRIVACY.md             # Privacy policy
└── PRIVACY_IMPLEMENTATION.md  # Privacy tech docs

tools/
├── fix_flutter_wsl.sh     # WSL2 environment repair
└── dev_env_check.sh       # Development environment validation

scripts/
├── dev_web.sh             # Launch web dev server
└── validate_i18n.sh       # i18n validation
```

## 🎨 Architecture

### Design Patterns

- **Clean Architecture**: Domain / Data / Presentation layers
- **Use Cases**: Single-responsibility business logic units
- **Repository Pattern**: Abstract data persistence
- **State Management**: Riverpod with immutable state
- **Dependency Injection**: Riverpod providers

### Key Components

**Treemap Layout** (`treemap_layout.dart`):
- Squarified algorithm with aspect ratio optimization
- EMA smoothing for stable animations
- Incremental updates (only dirty quadrants)
- Path caching for performance

**BanditService** (`bandit_service.dart`):
- Thompson sampling for task exploration
- Configurable seed for reproducibility
- Tie-breaking for stable ordering

**Matrix Controller** (`matrix_controller.dart`):
- Riverpod Notifier for state management
- Use case orchestration
- Persistent storage via SharedPreferences

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for detailed architecture documentation.

## 🌍 Internationalization

### Supported Languages
- 🇬🇧 English (en)
- 🇪🇸 Spanish (es)

### Adding Translations

1. **Edit ARB files:**
   ```
   l10n/app_en.arb  # English (source)
   l10n/app_es.arb  # Spanish
   ```

2. **Generate code:**
   ```bash
   flutter gen-l10n
   ```

3. **Validate:**
   ```bash
   ./scripts/validate_i18n.sh
   ```

4. **Use in code:**
   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   
   Text(AppLocalizations.of(context)!.appTitle)
   ```

See [`l10n/README.md`](l10n/README.md) for complete i18n guide.

## 🔐 Privacy & Security

- **Local-first**: All data stored on device (SharedPreferences)
- **Opt-in telemetry**: Disabled by default with consent dialog
- **ID anonymization**: SHA-256 hashing with device-specific salt
- **No PII collection**: Task content never leaves device
- **GDPR/CCPA compliant**: User consent, opt-out, data minimization

See [`docs/PRIVACY.md`](docs/PRIVACY.md) for full privacy policy.

## 🛠️ Configuration

### Environment Variables

Create `.env` file (optional):
```bash
# Chrome executable path (WSL2)
CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# Web renderer (html or canvaskit)
WEB_RENDERER=html
```

### FVM Configuration

```bash
# Install FVM
dart pub global activate fvm

# Use Flutter stable
fvm install stable
fvm use stable

# Run commands with fvm prefix
fvm flutter run -d chrome
fvm flutter test
```

### VS Code Integration

`.vscode/settings.json` is configured for FVM. Install Flutter extension:
```
ext install Dart-Code.flutter
```

## 📊 Performance

### Metrics

- **Layout Time**: < 5ms for incremental updates, < 20ms for full recompute
- **Frame Time**: Consistent 60fps on web/mobile
- **LCP (Web)**: Measured via PerformanceObserver API
- **Build Size**: ~2MB gzip (web release)

### Optimizations

- ✅ Path caching in CustomPainter
- ✅ Incremental layout updates
- ✅ RepaintBoundary widgets
- ✅ shouldRepaint optimization
- ✅ Debounced search
- ✅ Lazy loading for large lists

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Run environment check: `./tools/dev_env_check.sh`
4. Make changes
5. Run tests: `flutter test`
6. Run analysis: `flutter analyze`
7. Commit: `git commit -am 'Add feature'`
8. Push: `git push origin feature/my-feature`
9. Create Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `flutter analyze` before committing
- Add tests for new features
- Update documentation

### CI/CD

GitHub Actions runs on every push:
- ✅ `flutter analyze`
- ✅ `flutter test`
- ✅ `flutter build web --release`
- ✅ i18n validation
- ✅ Golden test comparison (Linux)

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) | System architecture, patterns, and design decisions |
| [`THEME_TOKENS.md`](docs/THEME_TOKENS.md) | Design system, color palette, typography |
| [`PRIVACY.md`](docs/PRIVACY.md) | Privacy policy and data handling |
| [`PRIVACY_IMPLEMENTATION.md`](docs/PRIVACY_IMPLEMENTATION.md) | Privacy technical implementation |
| [`l10n/README.md`](l10n/README.md) | Internationalization guide |

## 🐛 Troubleshooting

### WSL2 Issues

```bash
# Fix Flutter environment
./tools/fix_flutter_wsl.sh

# Check environment
./tools/dev_env_check.sh

# Manual Chrome path
export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
```

### Build Issues

```bash
# Clean build
flutter clean
flutter pub get
flutter gen-l10n

# Clear cache
rm -rf build/
rm -rf .dart_tool/
```

### Test Issues

```bash
# Update golden tests
flutter test test/golden/ --update-goldens

# Run specific test
flutter test test/unit/domain/weight_monotonicity_test.dart -r expanded
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Riverpod community for state management patterns
- Eisenhower Matrix methodology by President Dwight D. Eisenhower
- Squarified treemap algorithm by Bruls, Huizing, and van Wijk

---

**Built with ❤️ using Flutter**
