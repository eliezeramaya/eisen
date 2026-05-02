#!/bin/bash
# WSL2 Flutter Environment Repair Script
# Fixes common issues with Flutter on WSL2

set -e

echo "WSL2 Flutter Environment Repair"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on WSL
if ! grep -q microsoft /proc/version 2>/dev/null; then
    print_warning "Not running on WSL. This script is for WSL2 only."
    exit 0
fi

print_success "Running on WSL2"

# 1. Fix Flutter Path
echo ""
echo "1. Checking Flutter path..."
if [ ! -d "$HOME/tools/flutter" ]; then
    print_error "Flutter not found at ~/tools/flutter"
    echo "   Expected location: $HOME/tools/flutter"
    echo "   Install Flutter or update PATH in your shell config"
else
    print_success "Flutter found at ~/tools/flutter"
fi

# 2. Add Flutter to PATH if needed
if ! grep -q "tools/flutter/bin" ~/.bashrc; then
    echo ""
    echo "2. Adding Flutter to PATH..."
    echo 'export PATH="$HOME/tools/flutter/bin:$PATH"' >> ~/.bashrc
    print_success "Added Flutter to ~/.bashrc"
    print_warning "Run 'source ~/.bashrc' or restart terminal"
else
    print_success "Flutter already in PATH"
fi

# 3. Fix Chrome path for WSL
echo ""
echo "3. Checking Chrome executable..."
CHROME_PATH="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
if [ -f "$CHROME_PATH" ]; then
    print_success "Chrome found at Windows location"
    
    # Add to environment if not present
    if ! grep -q "CHROME_EXECUTABLE" ~/.bashrc; then
        echo 'export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"' >> ~/.bashrc
        print_success "Added CHROME_EXECUTABLE to ~/.bashrc"
    fi
else
    print_warning "Chrome not found at default Windows location"
    echo "   Expected: $CHROME_PATH"
    echo "   Set CHROME_EXECUTABLE manually if Chrome is elsewhere"
fi

# 4. Fix permissions
echo ""
echo "4. Fixing Flutter SDK permissions..."
if [ -d "$HOME/tools/flutter" ]; then
    chmod -R u+w "$HOME/tools/flutter" 2>/dev/null || true
    print_success "Flutter SDK permissions updated"
fi

# 5. Clear Flutter cache
echo ""
echo "5. Clearing Flutter cache..."
if command -v flutter &> /dev/null; then
    flutter clean 2>/dev/null || true
    rm -rf ~/.flutter-devtools 2>/dev/null || true
    print_success "Flutter cache cleared"
fi

# 6. Check WSL version
echo ""
echo "6. Checking WSL version..."
WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -i ubuntu | awk '{print $NF}')
if [ "$WSL_VERSION" = "2" ]; then
    print_success "Running WSL2 (recommended)"
else
    print_warning "Not running WSL2. Upgrade for better performance."
    echo "   Run in PowerShell: wsl --set-version Ubuntu 2"
fi

# 7. Check disk space
echo ""
echo "7. Checking disk space..."
AVAILABLE=$(df -h . | awk 'NR==2 {print $4}')
print_success "Available space: $AVAILABLE"

# Summary
echo ""
echo "=========================================="
echo "Repair complete!"
echo ""
echo "Next steps:"
echo "  1. source ~/.bashrc    # Reload environment"
echo "  2. flutter doctor       # Verify installation"
echo "  3. flutter pub get      # Install dependencies"
echo ""
echo "If issues persist, see: docs/flutter_env_troubleshooting.md"
