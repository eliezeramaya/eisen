#!/usr/bin/env bash
set -euo pipefail

# Dev script to run the app in Chrome with optional .env overrides.
# Usage:
#   scripts/dev_web.sh                # debug, try Chrome, fallback to web-server
#   scripts/dev_web.sh --release      # release mode
# Env:
#   CHROME_EXECUTABLE=/path/to/chrome
#   WEB_RENDERER=canvaskit|html (default: canvaskit)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

# Load .env if present
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

export WEB_RENDERER="${WEB_RENDERER:-canvaskit}"
if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then
  export CHROME_EXECUTABLE
fi

flutter --version >/dev/null 2>&1 || {
  echo "Flutter not found on PATH. Ensure 'export PATH=\"$HOME/flutter/bin:$PATH\"' or system install." >&2
  exit 1
}

# Ensure web is enabled (idempotent)
flutter config --enable-web >/dev/null 2>&1 || true

flutter pub get

HAS_CHROME=$(flutter devices | grep -i "chrome" -c || true)
# Detect if --web-renderer flag is supported
if flutter run -h 2>/dev/null | grep -q -- "--web-renderer"; then
  RENDER_ARGS=(--web-renderer "$WEB_RENDERER")
else
  # Fallback for older Flutter: use Skia via dart-define for canvaskit; default to no extra flag
  if [[ "${WEB_RENDERER}" == "canvaskit" ]]; then
    RENDER_ARGS=(--dart-define=FLUTTER_WEB_USE_SKIA=true)
  else
    RENDER_ARGS=()
  fi
fi
MODE=""
if [[ "${1:-}" == "--release" ]]; then
  MODE="--release"
fi

if [[ "$HAS_CHROME" -gt 0 ]]; then
  echo "Running on Chrome..."
  flutter run -d chrome ${RENDER_ARGS[@]} $MODE
else
  echo "Chrome not detected. Starting web-server and print URL..."
  flutter run -d web-server ${RENDER_ARGS[@]} $MODE
fi
