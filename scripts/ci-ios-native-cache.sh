#!/usr/bin/env bash
# Build or restore Kotlin/Native and Rust xcframeworks for Codemagic's iOS IPA.
# Tar archives preserve macOS framework symlinks unsupported by Codemagic caches.
set -euo pipefail

kind="${1:-}"
case "$kind" in
  kotlin|rust) ;;
  *) echo "Usage: $0 kotlin|rust" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_ROOT="${BBT_IOS_FRAMEWORK_CACHE_DIR:-$HOME/.cache/bbt-bit/ios-frameworks}"
mkdir -p "$CACHE_ROOT"

case "$kind" in
  kotlin)
    source_paths=(shared gradle gradlew gradle.properties settings.gradle.kts build.gradle.kts buildSrc build-logic scripts/build-shared-framework.sh scripts/ci-ios-native-cache.sh)
    output_paths=(AppleApp/Frameworks/BitChordShared.xcframework)
    ;;
  rust)
    source_paths=(native-core Cargo.toml Cargo.lock rust-toolchain rust-toolchain.toml scripts/build-native-core.sh scripts/ci-ios-native-cache.sh)
    output_paths=(AppleApp/Frameworks/NativeCoreFFI.xcframework AppleApp/Generated/NativeCore.swift)
    ;;
esac

fingerprint="$(
  {
    printf 'BBT-Bit native-cache v2\nkind=%s\n' "$kind"
    xcodebuild -version
    if [[ "$kind" == "kotlin" ]]; then
      java -version 2>&1
    else
      rustc --version
      cargo --version
    fi
    while IFS= read -r -d '' source_file; do
      [[ -f "$ROOT/$source_file" ]] || continue
      printf '%s\n' "$source_file"
      shasum -a 256 "$ROOT/$source_file" | awk '{print $1}'
    done < <(git -C "$ROOT" ls-files -z -- "${source_paths[@]}")
  } | shasum -a 256 | awk '{print $1}'
)"
archive="$CACHE_ROOT/$kind.tar.gz"
key_file="$CACHE_ROOT/$kind.key"
checksum_file="$CACHE_ROOT/$kind.archive-sha256"
start="$(date +%s)"

valid_outputs() {
  for output in "${output_paths[@]}"; do
    [[ -e "$ROOT/$output" ]] || return 1
  done
}

if [[ "${BBT_IOS_NATIVE_CACHE_DISABLE:-0}" != "1" ]] &&
   [[ -f "$archive" && -f "$key_file" && -f "$checksum_file" ]] &&
   [[ "$(cat "$key_file")" == "$fingerprint" ]] &&
   [[ "$(shasum -a 256 "$archive" | awk '{print $1}')" == "$(cat "$checksum_file")" ]]; then
  for output in "${output_paths[@]}"; do rm -rf "$ROOT/$output"; done
  if tar -xzf "$archive" -C "$ROOT" && valid_outputs; then
    echo "BBT_NATIVE_CACHE_HIT=$kind"
    echo "BBT_NATIVE_SECONDS_$kind=$(($(date +%s) - start))"
    exit 0
  fi
  echo "warning: $kind archive could not be restored; rebuilding" >&2
fi

echo "BBT_NATIVE_CACHE_MISS=$kind"
export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
case "$kind" in
  kotlin)
    export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21)}"
    CONFIG=release "$ROOT/scripts/build-shared-framework.sh"
    ;;
  rust)
    # UniFFI's current bindgen reads a host macOS static library.
    export NATIVE_TARGETS="aarch64-apple-darwin aarch64-apple-ios"
    "$ROOT/scripts/build-native-core.sh"
    ;;
esac

valid_outputs || { echo "error: missing $kind build outputs" >&2; exit 1; }
temporary="$(mktemp "$CACHE_ROOT/.new-$kind.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
tar -czf "$temporary" -C "$ROOT" "${output_paths[@]}"
checksum="$(shasum -a 256 "$temporary" | awk '{print $1}')"
mv -f "$temporary" "$archive"
printf '%s\n' "$checksum" > "$checksum_file"
printf '%s\n' "$fingerprint" > "$key_file"
trap - EXIT
echo "BBT_NATIVE_CACHE_STORED=$kind"
echo "BBT_NATIVE_SECONDS_$kind=$(($(date +%s) - start))"
