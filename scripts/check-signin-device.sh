#!/usr/bin/env bash
# Offline regression test for the device identity advertised during Google sign-in.
set -euo pipefail
cd "$(dirname "$0")/.."

out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
swiftc -swift-version 5 \
  AppleApp/Sources/UI/SignInUserAgent.swift \
  scripts/signin-device-verify/main.swift \
  -o "$out/signin-device-verify"
"$out/signin-device-verify"

# The page and the authenticated profile request must use the same identity.
grep -Fq 'webView.customUserAgent = SignInUserAgent.browser()' AppleApp/Sources/UI/YtMusicLoginView.swift
grep -Fq '"User-Agent": SignInUserAgent.browser()' AppleApp/Sources/UI/YtMusicLoginView.swift
! grep -Fq 'SignInUserAgent.desktopSafari()' AppleApp/Sources/UI/YtMusicLoginView.swift
