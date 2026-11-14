#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-home-discovery.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
python3 - "$check_dir" <<'PY'
from pathlib import Path
import sys
work = Path(sys.argv[1])
models = Path('AppleApp/Sources/App/InnertubeHome.swift').read_text().split('private struct FeedPage', 1)[0]
(work/'Models.swift').write_text(models.replace('import RedBitShared\n', ''))
targets = Path('AppleApp/Sources/UI/QueueCoverDrop.swift').read_text().split('extension ShelfCard {', 1)[1].split('struct QueueCardDragSource', 1)[0]
(work/'Targets.swift').write_text('import Foundation\nextension ShelfCard {' + targets)
peek = Path('AppleApp/Sources/UI/AlbumPeek.swift').read_text().split('@MainActor @Observable final class', 1)[1].split('struct AlbumPeekContents', 1)[0]
peek = 'import Foundation\nimport Observation\n@MainActor @Observable final class' + peek
(work/'PeekObserved.swift').write_text(peek)
home = Path('AppleApp/Sources/UI/Library/HomeDiscoveryModel.swift').read_text()
for name, source in [('Peek.swift', peek), ('Home.swift', home)]:
    (work/name).write_text(source.replace('import Observation\n', '').replace('@Observable ', ''))
queue = Path('AppleApp/Sources/PlaybackSession/PlaybackController+Queue.swift').read_text()
methods = '    func playNext(_ entry:' + queue.split('    func playNext(_ entry:', 1)[1].split('    /// Upstream `playRadio`', 1)[0]
adapters = Path('scripts/home-discovery-verify/Adapters.swift').read_text().replace('    // PRODUCTION_PLAY_NEXT', methods)
(work/'Adapters.swift').write_text(adapters)
PY
sources=(
  AppleApp/Sources/App/AppTestEvidence.swift
  AppleApp/Sources/PlaybackSession/QueueEntry.swift
  AppleApp/Sources/PlaybackSession/HomeDiscoveryPolicy.swift
  AppleApp/Sources/PlaybackSession/QueueDragRegistry.swift
  AppleApp/Sources/PlaybackSession/QueueNextAction.swift
  "$check_dir/Models.swift" "$check_dir/Targets.swift" "$check_dir/Adapters.swift"
  scripts/home-discovery-verify/check.swift
)
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 -typecheck "${sources[@]}" \
  "$check_dir/PeekObserved.swift" AppleApp/Sources/UI/Library/HomeDiscoveryModel.swift
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 "${sources[@]}" \
  "$check_dir/Peek.swift" "$check_dir/Home.swift" -o "$check_dir/check"
"$check_dir/check"
