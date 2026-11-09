#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-live-test.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT

# Der echte Monitor läuft isoliert mit kontrollierten Player-/Modelladaptern.
# Dies prüft Export und Messung; SwiftUI und native Frameworks brauchen Xcode.
python3 - "$check_dir/monitor.swift" <<'PY'
from pathlib import Path
import sys
source = Path('AppleApp/Sources/UI/AutomixLiveTestView.swift').read_text()
monitor = source.split('struct AutomixLiveTestView: View {', 1)[0]
monitor = monitor.replace('import SwiftUI\n', '').replace('import BitChordShared\n', '')
observed = monitor
if sys.platform == 'linux':
    # Linux hat keine App-UI; hier nur die unveränderten Mess-/Exportmethoden prüfen.
    monitor = monitor.replace('import Observation\n', '').replace('@Observable\n', '')
    monitor = monitor.replace('@ObservationIgnored ', '')
controller = Path('AppleApp/Sources/PlaybackSession/PlaybackController.swift').read_text()
errors = controller.split('    var lastError: String?', 1)[1].split('    var recoveringEntryID:', 1)[0]
adapters = Path('scripts/automix-live-verify/check.swift').read_text()
adapters = adapters.replace('    // PRODUCTION_ERROR_STATE', '    var lastError: String?' + errors)
Path(sys.argv[1]).write_text(monitor + '\n' + adapters)
observedAdapters = adapters.replace('@MainActor final class PlaybackController',
                                    '@MainActor @Observable final class PlaybackController')
Path(sys.argv[1]).with_suffix('.observed.swift').write_text(observed + '\n' + observedAdapters)
PY
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 -typecheck \
  AppleApp/Sources/PlaybackSession/PlaybackProgressTracker.swift \
  AppleApp/Sources/PlaybackSession/PlaybackDiagnosticFailure.swift \
  "$check_dir/monitor.observed.swift"
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 \
  AppleApp/Sources/PlaybackSession/PlaybackProgressTracker.swift \
  AppleApp/Sources/PlaybackSession/PlaybackDiagnosticFailure.swift \
  "$check_dir/monitor.swift" -o "$check_dir/check"
"$check_dir/check"
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 \
  AppleApp/Sources/PlaybackSession/PlaybackProgressTracker.swift \
  scripts/test-playback-progress.swift -o "$check_dir/progress"
"$check_dir/progress"
