#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fw="$repo/AppleApp/Frameworks/RedBitShared.xcframework/macos-arm64"
xcrun swiftc -O -module-cache-path /tmp/redbit-swift-module-cache -o "$scratch/verify" \
  -F "$fw" -framework RedBitShared \
  -Xlinker -rpath -Xlinker "$fw/RedBitShared.framework/Versions/A" \
  "$repo/AppleApp/Sources/PlaybackSession/SourceSubstitution.swift" "$repo/scripts/source-bridge-verify/main.swift"
"$scratch/verify"
