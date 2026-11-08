#!/usr/bin/env python3
"""Verify all three pinned, publicly downloadable BBT-Bit Automix models.

Offline by default (safe during CI/IPA packaging). Use --online to check
GitHub's public release metadata. This does not download the actual model
bytes; use MODELS_LIVE=1 bash scripts/check-models.sh for that test on macOS.
"""
import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = "bagumamartin/BitChord"
BASE = f"https://github.com/{REPO}/releases/download"
MODELS = (
    ("beat", "BEAT", "model-beat-this-final0-v1", "beat_this_full_int8.onnx",
     23478460, "9f10e5efa37d3e120da2121141825fe54b23b487b32dd25a54f89039fd8f85cb"),
    ("beatCoreML", "COREML", "model-beat-this-final0-coreml-v1", "beat_this_final0_coreml.aar",
     18818981, "4f545c60ac59282bd8601104a94ff4123f5304d4e5e233311f6ec67243975fff"),
    ("vocals", "VOCALS", "model-umxhq-vocals-v1", "vocals_umxhq_int8.onnx",
     23209009, "7eba6bebce0cc2e2d3b5c0e490a8074e66ce27f64170c6802b245740dcaf21ef"),
)


def check(condition, message):
    if not condition:
        raise ValueError(message)


def field(pattern, text, label):
    match = re.search(pattern, text)
    check(match is not None, "missing " + label)
    return match.group(1)


def offline():
    store = (ROOT / "AppleApp/Sources/PlaybackSession/AutomixModelStore.swift").read_text()
    script = (ROOT / "scripts/fetch-automix-models.sh").read_text()
    codemagic = (ROOT / "codemagic.yaml").read_text()
    check("https://github.com/Redurbabat/BBT-Bit/releases/download/" not in store,
          "private release URL produces HTTP 404 for an unauthenticated iPhone")
    for ident, shell, tag, filename, length, digest in MODELS:
        marker = f"static let {ident} = ModelSpec("
        check(store.count(marker) == 1, f"missing/duplicate model: {ident}")
        body = store.split(marker, 1)[1].split("\n        )", 1)[0]
        url = f"{BASE}/{tag}/{filename}"
        actual_url = field(r'url:\s*URL\(string:\s*"([^"]+)"\)', body, f"{ident}.url")
        actual_sha = field(r'sha256:\s*"([0-9a-f]+)"', body, f"{ident}.sha256")
        actual_len = int(field(r'byteCount:\s*([\d_]+)', body, f"{ident}.byteCount").replace("_", ""))
        check(actual_url == url, f"wrong public URL: {ident}")
        check(actual_sha == digest, f"wrong checksum: {ident}")
        check(actual_len == length, f"wrong asset length: {ident}")
        for name, expected in (
            (shell + "_URL", '"' + url + '"'),
            (shell + "_SHA", '"' + digest + '"'),
            (shell + "_BYTES", str(length)),
        ):
            check(f"{name}={expected}" in script, f"developer script mismatched: {name}")
        check('fetch "$' + shell + '_URL"' in script, f"missing fetch for: {ident}")
        print(f"PASS {ident}: public URL, SHA-256 and {length} bytes")
    check("python3 scripts/verify-automix-model-sources.py" in codemagic,
          "Codemagic must check model sources before both IPA workflows")


def online():
    for ident, _, tag, filename, length, digest in MODELS:
        api = f"https://api.github.com/repos/{REPO}/releases/tags/{tag}"
        req = urllib.request.Request(
            api, headers={"Accept": "application/vnd.github+json",
                          "User-Agent": "BBT-Bit-Model-Verification"}
        )
        with urllib.request.urlopen(req, timeout=25) as response:
            release = json.load(response)
        assets = [asset for asset in release.get("assets", []) if asset.get("name") == filename]
        check(len(assets) == 1, f"{ident}: missing public asset")
        asset = assets[0]
        check(not release.get("draft", True), f"{ident}: draft release inaccessible")
        check(asset.get("size") == length, f"{ident}: public size changed")
        check(asset.get("digest") == "sha256:" + digest, f"{ident}: public SHA-256 changed")
        check(asset.get("browser_download_url") == f"{BASE}/{tag}/{filename}",
              f"{ident}: public download URL changed")
        print(f"PASS {ident}: public GitHub release metadata")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--online", action="store_true", help="check live GitHub release metadata")
    args = parser.parse_args()
    try:
        offline()
        if args.online:
            online()
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(f"FAIL Automix source verification: {error}", file=sys.stderr)
        return 1
    print("PASS all three Automix model sources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
