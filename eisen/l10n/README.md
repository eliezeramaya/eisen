# Internationalization (i18n)

This directory contains the Application Resource Bundle (ARB) files for internationalization.

## Supported Languages

- **English (EN)**: `app_en.arb` - Base language
- **Spanish (ES)**: `app_es.arb` - Full translation

## File Structure

```
l10n/
├── app_en.arb          # English translations (source of truth)
├── app_es.arb          # Spanish translations
├── untranslated.txt    # Tracking file for pending translations
└── README.md           # This file
```

## Adding New Translations

### 1. Add to English (base language)

Edit `app_en.arb` and add your key-value pair:

```json
{
  "myNewKey": "My new translation",
  "existingKey": "Existing translation"
}
```

**Key naming conventions:**
- Use `camelCase` (start with lowercase)
- Be descriptive and specific
- Group related keys with prefixes (e.g., `settings*`, `minimap*`, `axis*`)

### 2. Add to all other languages

Add the same key to `app_es.arb` with the translated value:

```json
{
  "myNewKey": "Mi nueva traducción",
  "existingKey": "Traducción existente"
}
```

### 3. Placeholders (optional)

For dynamic values, use placeholders:

**app_en.arb:**
```json
{
  "greeting": "Hello, {name}!",
  "@greeting": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**app_es.arb:**
```json
{
  "greeting": "¡Hola, {name}!"
}
```

**Note:** Placeholder names must match exactly across all languages.

### 4. Generate and validate

Run the validation script:

```bash
./scripts/validate_i18n.sh
```

Or manually:

```bash
flutter gen-l10n
flutter test test/unit/i18n/arb_validation_test.dart
```

## Validation Tests

The i18n validation suite (`test/unit/i18n/arb_validation_test.dart`) checks:

- ✅ **Valid JSON** - All ARB files are valid JSON
- ✅ **No orphaned keys** - ES doesn't have keys missing in EN
- ✅ **No missing keys** - ES has all keys from EN
- ✅ **Key count match** - Same number of keys across languages
- ✅ **Naming conventions** - All keys use camelCase
- ✅ **No empty values** - All translations have content
- ✅ **Placeholder consistency** - Placeholders match across languages
- ✅ **Proper formatting** - 2-space indented JSON

## CI/CD Integration

The GitHub Actions workflow automatically:

1. Runs `flutter gen-l10n` to generate localization code
2. Verifies generated files exist
3. Runs ARB validation tests
4. Fails the build if:
   - Keys are missing or orphaned
   - Placeholders don't match
   - ARB files are invalid JSON

See `.github/workflows/ci.yaml` for details.

## Usage in Code

### Import generated localizations

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### Access translations

```dart
// In a widget with BuildContext
Text(AppLocalizations.of(context)!.appTitle)

// With placeholders
Text(AppLocalizations.of(context)!.greeting('John'))
```

### Supported locales

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

## Troubleshooting

### "Missing keys" error in tests

One or more languages are missing keys that exist in English.

**Fix:** Add the missing keys to the appropriate ARB file(s).

### "Orphaned keys" error in tests

A language has keys that don't exist in English (the base language).

**Fix:** Either:
- Add the key to `app_en.arb` if it should exist
- Remove the key from the other language file(s)

### "Placeholder mismatch" error

Placeholder names don't match between languages.

**Fix:** Ensure placeholder syntax `{name}` is identical across all ARB files for the same key.

### Generated files not found

`flutter gen-l10n` hasn't been run or failed.

**Fix:**
```bash
flutter pub get
flutter gen-l10n
```

## Best Practices

1. **Always update English first** - It's the source of truth
2. **Keep keys in sync** - Run validation after every change
3. **Use descriptive keys** - `settingsShowAxisLegends` not `setting1`
4. **Group related keys** - Use prefixes for organization
5. **Test in both languages** - Verify translations in the app
6. **Short and clear** - Translations should fit UI constraints
7. **Consistent tone** - Match the app's voice across languages

## Adding a New Language

1. Create new ARB file: `l10n/app_XX.arb` (where XX is language code)
2. Copy structure from `app_en.arb`
3. Translate all values
4. Update `l10n.yaml` if needed (usually automatic)
5. Add validation tests for the new language
6. Run `./scripts/validate_i18n.sh` to verify

## Resources

- [Flutter Internationalization Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
