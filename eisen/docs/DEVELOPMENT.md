# Development Guide

**Last reviewed**: 2026-05-02

This guide covers setting up the development environment, running the app, and common development tasks.

## Prerequisites

- **Flutter**: 3.35+ stable (3.9.2+ recommended)
- **Dart**: 3.5+ (comes with Flutter)
- **FVM**: Recommended for Flutter version management
- **Chrome/Edge**: For web development (or use `web-server` device)
- **IDE**: VS Code or Android Studio with Flutter/Dart plugins

### Platform-Specific

**Linux (WSL2)**:
- Run `./tools/fix_flutter_wsl.sh` to configure environment
- Chrome must be accessible from WSL

**macOS**:
- Xcode for iOS development
- CocoaPods installed

**Windows**:
- Visual Studio with C++ tools for Windows development
- Android Studio for Android development

## Setup

### 1. Clone and Install

```bash
# Clone the repository
git clone https://github.com/eliezeramaya/eisen.git
cd eisen/eisen

# If using FVM (recommended)
fvm use 3.35.0  # or your preferred stable version

# Install dependencies
flutter pub get

# Generate localizations
flutter gen-l10n
```

### 2. Environment Check

Run the environment verification script:

```bash
./tools/dev_env_check.sh
```

This checks:
- Flutter installation and version
- Connected devices
- Required tools (dart, flutter, pub)
- Platform-specific setup

### 3. Configuration

**Environment Variables** (optional):
- Copy `.env.example` to `.env` if it exists
- Supabase sync is disabled by default (`ENABLE_CLOUD_SYNC=false`)

**No additional configuration needed for local-only development**.

## Running the App

### Web (Development)

```bash
# Chrome (recommended for debugging)
flutter run -d chrome

# Or use the convenience script
./scripts/dev_web.sh

# Web server (no Chrome window)
flutter run -d web-server
```

### Mobile

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Specific device
flutter run -d <device-id>

# Debug mode with hot reload (default)
flutter run

# Profile mode (performance testing)
flutter run --profile

# Release mode
flutter run --release
```

### Desktop

```bash
# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

## Development Workflow

### Common Commands

```bash
# Run all tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage

# Watch mode (run tests on file change)
flutter test --watch

# Analyze code (linting)
flutter analyze

# Format code
dart format lib/ test/

# Generate code (if using code generation)
flutter pub run build_runner build

# Clean build artifacts
flutter clean
```

### Localization

```bash
# Generate l10n files from ARB
flutter gen-l10n

# Validate i18n coverage
./scripts/validate_i18n.sh

# Edit translations
# - English: l10n/app_en.arb
# - Spanish: l10n/app_es.arb
```

See `l10n/README.md` for localization guidelines.

### Hot Reload / Hot Restart

**During `flutter run`**:
- Press `r` - Hot reload (preserves state)
- Press `R` - Hot restart (resets state)
- Press `q` - Quit
- Press `h` - Help

**Hot reload limitations**:
- Doesn't work for enum changes
- Doesn't work for global variable initialization
- Use hot restart (R) for these cases

## Building for Release

### Web

```bash
# Production web build
flutter build web --release

# Output: build/web/
# Deploy: Upload build/web/ contents to web server

# With web renderer (default: auto)
flutter build web --release --web-renderer canvaskit
```

### Mobile

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode to archive
```

### Desktop

```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## Testing

See [testing_plan.md](testing_plan.md) for full testing strategy.

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/domain/task_test.dart

# With coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Tests

**Unit tests** (`test/unit/`):
- Test pure domain logic
- No Flutter dependencies
- Use `test` package

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task', () {
    test('copyWith updates fields', () {
      final task = Task(id: '1', title: 'Original');
      final updated = task.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, '1'); // unchanged
    });
  });
}
```

**Widget tests** (`test/widget/`):
- Test UI components
- Use `ProviderScope` for Riverpod
- Mock dependencies with overrides

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('MyWidget displays title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: MyWidget()),
      ),
    );
    
    expect(find.text('Title'), findsOneWidget);
  });
}
```

**Integration tests** (`integration_test/`):
- Test full user flows
- Use `IntegrationTestWidgetsFlutterBinding`

## Troubleshooting

### Common Issues

**"Flutter SDK not found"**:
- Ensure Flutter is in PATH: `export PATH="$PATH:/path/to/flutter/bin"`
- Or use FVM: `fvm flutter run`

**"Gradle build failed" (Android)**:
- Clean: `flutter clean && flutter pub get`
- Update Gradle: Check `android/build.gradle.kts`
- Invalidate caches in Android Studio

**"Pods install failed" (iOS)**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

**WSL2 Chrome issues**:
- Run `./tools/fix_flutter_wsl.sh`
- Ensure `BROWSER` environment variable is set

**Hot reload not working**:
- Hot restart instead: Press `R`
- If still broken: `flutter clean` and restart

See [flutter_env_troubleshooting.md](/docs/flutter_env_troubleshooting.md) for more issues.

## Code Organization

### Adding a New Feature

1. **Create feature module**: `lib/features/my_feature/`
2. **Structure**:
   ```
   my_feature/
   ├── data/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   └── repositories/
   └── presentation/
       ├── pages/
       └── widgets/
   ```
3. **Add route**: Update `lib/app/router.dart`
4. **Add tests**: `test/unit/my_feature/` and `test/widget/my_feature/`

### State Management

Use Riverpod providers:

```dart
// Domain state
final myFeatureProvider = NotifierProvider<MyFeatureController, MyFeatureState>(
  MyFeatureController.new,
);

// Controller
class MyFeatureController extends Notifier<MyFeatureState> {
  @override
  MyFeatureState build() => MyFeatureState.initial();
  
  void doSomething() {
    state = state.copyWith(/* updates */);
  }
}
```

### Adding Dependencies

```bash
# Add to pubspec.yaml
flutter pub add package_name

# Dev dependencies
flutter pub add --dev package_name

# Update dependencies
flutter pub upgrade
```

## CI/CD

**GitHub Actions** (`.github/workflows/`):
- `ci.yaml` - Runs tests and analysis on push/PR
- Checks: `flutter analyze`, `flutter test`, `dart format`

**Pre-commit checks**:
- Run `flutter analyze` before committing
- Run `flutter test` before pushing

## Performance Profiling

```bash
# Profile mode (optimized but debuggable)
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Performance overlay
# Press 'P' during flutter run
```

## Documentation

- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Testing**: [testing_plan.md](testing_plan.md)
- **Responsive**: [RESPONSIVE_GUIDE.md](RESPONSIVE_GUIDE.md)
- **Theme**: [THEME_TOKENS.md](THEME_TOKENS.md)
- **Privacy**: [PRIVACY_IMPLEMENTATION.md](PRIVACY_IMPLEMENTATION.md)
- **Roadmap**: [/docs/project_status.md](/docs/project_status.md)

## Getting Help

- **Issues**: File bugs/features on GitHub Issues
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: All changes require PR review
- **Style Guide**: Follow Dart/Flutter style guide (enforced by `flutter analyze`)

## Useful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Material 3 Design](https://m3.material.io/)
