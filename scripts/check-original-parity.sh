#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-parity.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 \
  AppleApp/Sources/PlaybackSession/AutoplaySeedState.swift \
  AppleApp/Sources/PlaybackSession/QueueEntry.swift \
  AppleApp/Sources/PlaybackSession/AutomixPreviewRequest.swift \
  AppleApp/Sources/PlaybackSession/MixWaveform.swift \
  AppleApp/Sources/PlaybackSession/PlaylistSyncPolicy.swift \
  AppleApp/Sources/UI/ReleaseRepository.swift \
  scripts/original-parity-verify/PreviewAdapters.swift \
  scripts/original-parity-verify/check.swift -o "$check_dir/check"
"$check_dir/check"
python3 - "$check_dir/playlist.swift" <<'PY'
from pathlib import Path
import sys
source = Path('AppleApp/Sources/PlaybackSession/DownloadStore.swift').read_text()
methods = '    func setAppActive(' + source.split('    func setAppActive(', 1)[1].split('    private func pump()', 1)[0]
if sys.platform == 'linux':
    # Plattformadapter: Linux hat Apples Energiesparmodus nicht.
    methods = methods.replace('ProcessInfo.processInfo.isLowPowerModeEnabled', 'false')
adapters = Path('scripts/original-parity-verify/PlaylistAdapters.swift').read_text()
Path(sys.argv[1]).write_text(adapters.replace('    // PRODUCTION_PLAYLIST_SYNC', methods))
PY
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 \
  AppleApp/Sources/PlaybackSession/QueueEntry.swift \
  AppleApp/Sources/PlaybackSession/PlaylistSyncPolicy.swift \
  "$check_dir/playlist.swift" -o "$check_dir/playlist"
"$check_dir/playlist"
