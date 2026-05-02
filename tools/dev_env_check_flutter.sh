#!/bin/bash
# Development Environment Check
# Validates Flutter, dependencies, and project setup

set -e

echo "Development Environment Check"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_section() { echo -e "\n${BLUE}> $1${NC}"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ERRORS=0
WARNINGS=0

# 1. Flutter SDK
print_section "Flutter SDK"
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
    print_success "Flutter installed: $FLUTTER_VERSION"
    
    # Check version
    if [[ $FLUTTER_VERSION == *"3.3"* ]] || [[ $FLUTTER_VERSION == *"3.4"* ]]; then
        print_success "Flutter 3.35+ detected"
    else
        print_warning "Flutter version may be old. Recommended: 3.35+"
        ((WARNINGS++))
    fi
else
    print_error "Flutter not found in PATH"
    ((ERRORS++))
fi

# 2. FVM
print_section "FVM (Flutter Version Management)"
if command -v fvm &> /dev/null; then
    FVM_VERSION=$(fvm --version 2>&1 | head -1)
    print_success "FVM installed: $FVM_VERSION"
    
    if [ -f ".fvm/fvm_config.json" ]; then
        print_success ".fvm config found"
    else
        print_warning ".fvm config not found. Run: fvm use stable"
        ((WARNINGS++))
    fi
else
    print_warning "FVM not installed (optional but recommended)"
    echo "    Install: dart pub global activate fvm"
    ((WARNINGS++))
fi

# 3. Dart SDK
print_section "Dart SDK"
if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version 2>&1)
    print_success "Dart installed: $DART_VERSION"
else
    print_error "Dart not found in PATH"
    ((ERRORS++))
fi

# 4. Dependencies
print_section "Project Dependencies"
if [ -f "pubspec.yaml" ]; then
    print_success "pubspec.yaml found"
    
    if [ -f "pubspec.lock" ]; then
        print_success "pubspec.lock exists (dependencies installed)"
    else
        print_warning "pubspec.lock missing. Run: flutter pub get"
        ((WARNINGS++))
    fi
    
    # Check for .packages
    if [ -f ".dart_tool/package_config.json" ]; then
        print_success "Package config up to date"
    else
        print_warning "Package config missing. Run: flutter pub get"
        ((WARNINGS++))
    fi
else
    print_error "pubspec.yaml not found. Are you in the project root?"
    ((ERRORS++))
fi

# 5. Build files
print_section "Build Configuration"
if [ -d "build" ]; then
    print_success "build/ directory exists"
else
    print_warning "build/ directory not found (normal on fresh clone)"
fi

if [ -f "l10n.yaml" ]; then
    print_success "l10n.yaml found"
    
    if [ -d "lib/l10n" ] && [ -f "lib/l10n/app_localizations.dart" ]; then
        print_success "Generated l10n files exist"
    else
        print_warning "l10n files not generated. Run: flutter gen-l10n"
        ((WARNINGS++))
    fi
else
    print_warning "l10n.yaml not found"
    ((WARNINGS++))
fi

# 6. Chrome (for web development)
print_section "Web Development"
if [ -n "$CHROME_EXECUTABLE" ]; then
    if [ -f "$CHROME_EXECUTABLE" ]; then
        print_success "Chrome path set and valid: $CHROME_EXECUTABLE"
    else
        print_error "CHROME_EXECUTABLE set but file not found: $CHROME_EXECUTABLE"
        ((ERRORS++))
    fi
elif command -v google-chrome &> /dev/null; then
    print_success "Chrome found via google-chrome command"
elif [ -f "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" ]; then
    print_success "Chrome found at Windows location (WSL)"
else
    print_warning "Chrome not found. Web debugging may not work."
    echo "    Set CHROME_EXECUTABLE or use: flutter run -d web-server"
    ((WARNINGS++))
fi

# 7. Git
print_section "Version Control"
if command -v git &> /dev/null; then
    print_success "Git installed"
    
    if [ -d ".git" ]; then
        BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
        print_success "Git repo initialized (branch: $BRANCH)"
    else
        print_warning "Not a git repository"
        ((WARNINGS++))
    fi
else
    print_warning "Git not found"
    ((WARNINGS++))
fi

# 8. Disk space
print_section "System Resources"
AVAILABLE=$(df -h . | awk 'NR==2 {print $4}')
print_success "Available disk space: $AVAILABLE"

# 9. Environment variables
print_section "Environment Variables"
if [ -f ".env" ]; then
    print_success ".env file found"
else
    print_warning ".env file not found (optional)"
    if [ -f ".env.example" ]; then
        echo "    Copy .env.example to .env if needed"
    fi
fi

# 10. VS Code integration
print_section "IDE Integration"
if [ -d ".vscode" ]; then
    print_success ".vscode/ directory found"
    
    if [ -f ".vscode/settings.json" ]; then
        print_success "VS Code settings configured"
    fi
    
    if [ -f ".vscode/launch.json" ]; then
        print_success "Debug configurations found"
    fi
else
    print_warning ".vscode/ directory not found (optional)"
fi

# Summary
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}Environment check passed!${NC}"
    echo ""
    echo "You're ready to develop. Try:"
    echo "  flutter run -d chrome"
    echo "  flutter test"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Environment check completed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Your environment is mostly ready, but some optional features may not work."
else
    echo -e "${RED}Environment check failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Fix the errors above before developing."
    exit 1
fi

echo ""
echo "Quick commands:"
echo "  flutter doctor          # Full Flutter diagnostics"
echo "  flutter pub get         # Install dependencies"
echo "  flutter gen-l10n        # Generate localization files"
echo "  flutter test            # Run tests"
echo "  flutter run -d chrome   # Launch web app"
