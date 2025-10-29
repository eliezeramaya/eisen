#!/usr/bin/env bash
# i18n management helper for Eisenhower Matrix
# Validates ARB files, runs gen-l10n, and checks for orphaned/missing keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
L10N_DIR="$PROJECT_DIR/l10n"

echo "i18n Management Tool"
echo "======================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Change to project directory
cd "$PROJECT_DIR"

# Function to print colored output
print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Validate ARB files exist
echo "Step 1: Checking ARB files..."
if [ ! -f "$L10N_DIR/app_en.arb" ]; then
    print_error "app_en.arb not found"
    exit 1
fi

if [ ! -f "$L10N_DIR/app_es.arb" ]; then
    print_error "app_es.arb not found"
    exit 1
fi

print_success "ARB files found (EN, ES)"
echo ""

# Step 2: Run ARB validation tests
echo "Step 2: Running ARB validation tests..."
if fvm flutter test test/unit/i18n/arb_validation_test.dart --no-pub 2>&1 | tee /tmp/i18n_test.log; then
    print_success "All ARB validation tests passed"
else
    print_error "ARB validation tests failed"
    echo ""
    echo "Check the output above for details on:"
    echo "  - Missing keys (keys in EN but not in ES)"
    echo "  - Orphaned keys (keys in ES but not in EN)"
    echo "  - Empty translations"
    echo "  - Placeholder mismatches"
    exit 1
fi
echo ""

# Step 3: Generate l10n files
echo "Step 3: Generating l10n files..."
if fvm flutter gen-l10n; then
    print_success "l10n files generated successfully"
else
    print_error "Failed to generate l10n files"
    exit 1
fi
echo ""

# Step 4: Verify generated files
echo "Step 4: Verifying generated files..."
GEN_DIR="lib/l10n"

if [ ! -f "$GEN_DIR/app_localizations.dart" ]; then
    print_error "app_localizations.dart not generated"
    exit 1
fi

if [ ! -f "$GEN_DIR/app_localizations_en.dart" ]; then
    print_warning "app_localizations_en.dart not found (may be generated differently)"
fi

if [ ! -f "$GEN_DIR/app_localizations_es.dart" ]; then
    print_warning "app_localizations_es.dart not found (may be generated differently)"
fi

print_success "Generated files verified"
echo ""

# Step 5: Show summary
echo "Summary"
echo "=========="

EN_KEYS=$(grep -c '"' "$L10N_DIR/app_en.arb" || echo "0")
ES_KEYS=$(grep -c '"' "$L10N_DIR/app_es.arb" || echo "0")

# Account for opening/closing braces
EN_KEYS=$((EN_KEYS / 2))
ES_KEYS=$((ES_KEYS / 2))

echo "  English (EN): $EN_KEYS keys"
echo "  Spanish (ES): $ES_KEYS keys"
echo ""

if [ "$EN_KEYS" -eq "$ES_KEYS" ]; then
    print_success "All languages have same number of keys"
else
    print_warning "Key count mismatch (EN: $EN_KEYS, ES: $ES_KEYS)"
fi

echo ""
print_success "i18n validation complete!"
echo ""
echo "Next steps:"
echo "  - Run 'flutter test' to verify all tests pass"
echo "  - Commit changes if ARB files were updated"
echo "  - Check untranslated.txt for pending translations"
