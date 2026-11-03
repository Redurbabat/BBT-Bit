#!/usr/bin/env bash
# Pure-Foundation regression checks for iOS/KMP network error presentation.
set -euo pipefail
cd "$(dirname "$0")/.."
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
swiftc AppleApp/Sources/App/UserFacingRequestError.swift \
  scripts/network-errors-verify/main.swift -o "$out/network-errors-verify"
"$out/network-errors-verify"
