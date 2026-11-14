#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
fw="$repo/AppleApp/Frameworks/RedBitShared.xcframework/macos-arm64"
bin="$(mktemp -d)/playback-settings-verify"
xcrun swiftc -module-cache-path /tmp/redbit-swift-module-cache -o "$bin" \
  -F "$fw" -framework RedBitShared \
  -Xlinker -rpath -Xlinker "$fw/RedBitShared.framework/Versions/A" \
  "$repo/scripts/settings-verify/main.swift"
for mode in missing off on; do "$bin" "$mode"; done
