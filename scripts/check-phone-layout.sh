#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-phone-layout.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
python3 - "$check_dir/coordinator.swift" <<'PY'
from pathlib import Path
import sys
source = Path('AppleApp/Sources/UI/LiquidMotion/LogoGlassBloom.swift').read_text()
coordinator = 'enum LogoGlassBloomPhase' + source.split('enum LogoGlassBloomPhase', 1)[1].split('/// Misst sichtbare Toolbar-Aktionen', 1)[0]
coordinator = coordinator.replace('@Observable\n', '').replace('@ObservationIgnored ', '')
adapter = Path('scripts/phone-layout-verify/check.swift').read_text()
Path(sys.argv[1]).write_text(adapter.replace('// PRODUCTION_LOGO_COORDINATOR', coordinator))
PY
"${SWIFTC:-swiftc}" -parse-as-library -swift-version 5 \
  AppleApp/Sources/UI/LiquidMotion/DockDirectionTracker.swift \
  "$check_dir/coordinator.swift" -o "$check_dir/check"
"$check_dir/check"
