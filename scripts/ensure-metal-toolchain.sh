#!/usr/bin/env bash
set -euo pipefail

# Xcode 26 liefert den Metal-Compiler als optionale offizielle Komponente.
# Nur die Entwicklungsumgebung wird vorbereitet; keine Fremdkomponenten in der App.
if ! xcrun metal --version >/dev/null 2>&1; then
  xcodebuild -downloadComponent metalToolchain
fi
xcrun metal --version
