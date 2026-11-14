#!/usr/bin/env bash
# Fetch the development/CI Automix graphs into native-core/fixtures/models/.
#
# All three models are downloaded from public pinned GitHub releases.
# Private BBT-Bit release links return 404 to unauthenticated iPhones.
# This developer cache remains outside AppleApp/Resources (nothing is bundled). The tests in models.rs and
# the corpus scorecard read the same directory by default.
#
# Pinned to release tags and checked against the length and SHA-256 the app
# itself verifies (see AutomixModelStore.swift). A tag can be re-pointed; a
# digest and a byte count cannot, and a dev box and a listener's device must end
# up with the same bytes or parity claims mean nothing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/native-core/fixtures/models"
mkdir -p "$DEST"

# Beat This! final0, dynamic int8 (CPJKU, MIT).
BEAT_URL="https://github.com/Redurbabat/RED-Bit/releases/download/model-beat-this-final0-v1/beat_this_full_int8.onnx"
BEAT_SHA="9f10e5efa37d3e120da2121141825fe54b23b487b32dd25a54f89039fd8f85cb"
BEAT_BYTES=23478460

# Core ML archive for Beat This! final0 (Neural Engine, CPJKU/MIT).
COREML_URL="https://github.com/Redurbabat/RED-Bit/releases/download/model-beat-this-final0-coreml-v1/beat_this_final0_coreml.aar"
COREML_SHA="4f545c60ac59282bd8601104a94ff4123f5304d4e5e233311f6ec67243975fff"
COREML_BYTES=18818981

# open-unmix umxhq vocals, dynamic int8 on MatMul/Gemm only (SigSep/Inria, MIT).
VOCALS_URL="https://github.com/Redurbabat/RED-Bit/releases/download/model-umxhq-vocals-v1/vocals_umxhq_int8.onnx"
VOCALS_SHA="7eba6bebce0cc2e2d3b5c0e490a8074e66ce27f64170c6802b245740dcaf21ef"
VOCALS_BYTES=23209009

fetch() {
  local url="$1" out="$2" want_sha="$3" want_bytes="$4"
  if [[ -s "$out" ]]; then
    local got_sha got_bytes
    got_sha="$(shasum -a 256 "$out" | awk '{print $1}')"
    got_bytes="$(stat -f%z "$out")"
    if [[ "$got_sha" == "$want_sha" && "$got_bytes" == "$want_bytes" ]]; then
      echo "already present and verified: $out"
      return
    fi
  fi
  echo "downloading $(basename "$out")…"
  curl -L --fail --retry 3 -o "$out.tmp" "$url"
  local got_sha got_bytes
  got_sha="$(shasum -a 256 "$out.tmp" | awk '{print $1}')"
  got_bytes="$(stat -f%z "$out.tmp")"
  if [[ "$got_sha" != "$want_sha" || "$got_bytes" != "$want_bytes" ]]; then
    rm -f "$out.tmp"
    echo "checksum or size mismatch for $(basename "$out")" >&2
    echo "  expected $want_bytes bytes, sha256 $want_sha" >&2
    echo "  got      $got_bytes bytes, sha256 $got_sha" >&2
    exit 1
  fi
  mv "$out.tmp" "$out"
  echo "verified $(basename "$out")"
}

fetch "$BEAT_URL" "$DEST/beat_this.onnx" "$BEAT_SHA" "$BEAT_BYTES"
fetch "$COREML_URL" "$DEST/beat_this_final0_coreml.aar" "$COREML_SHA" "$COREML_BYTES"
fetch "$VOCALS_URL" "$DEST/vocals_umxhq_int8.onnx" "$VOCALS_SHA" "$VOCALS_BYTES"
ls -lh "$DEST"/*.onnx "$DEST"/*.aar
