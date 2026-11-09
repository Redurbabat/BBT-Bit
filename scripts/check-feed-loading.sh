#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-feed-loading.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
python3 - "$check_dir" <<'PY'
from pathlib import Path
import sys
work = Path(sys.argv[1])
models = Path('AppleApp/Sources/App/InnertubeHome.swift').read_text().split('final class InnertubeFeed:', 1)[0]
(work/'Models.swift').write_text(models.replace('import BitChordShared\n', ''))
loader = Path('AppleApp/Sources/UI/FeedViews.swift').read_text().split('@MainActor @Observable\nfinal class FeedLoader', 1)[1].split('/// Shared shelf heading:', 1)[0]
loader = 'import Foundation\nimport Observation\n@MainActor @Observable\nfinal class FeedLoader' + loader
(work/'LoaderObserved.swift').write_text(loader)
(work/'Loader.swift').write_text(loader.replace('import Observation\n', '').replace('@Observable\n', ''))
PY
sources=("$check_dir/Models.swift" scripts/feed-loading-verify/Adapters.swift scripts/feed-loading-verify/check.swift)
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 -typecheck "${sources[@]}" "$check_dir/LoaderObserved.swift"
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 "${sources[@]}" "$check_dir/Loader.swift" -o "$check_dir/check"
"$check_dir/check"
