#!/usr/bin/env bash
# Physical iPhone UI automation via Xcode. Requires signing and a trusted device.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: BBT_APPLE_TEAM_ID=<team-id> $0 <iPhone-UDID>" >&2
  echo "Discover phones: xcrun xctrace list devices" >&2
  exit 2
fi
DEVICE_ID="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for tool in xcodegen xcodebuild xcrun python3 zip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing: $tool" >&2; exit 2; }
done
for path in AppleApp/Frameworks/RedBitShared.xcframework AppleApp/Frameworks/NativeCoreFFI.xcframework AppleApp/Generated/NativeCore.swift; do
  if [[ ! -e "$ROOT/$path" ]]; then
    echo "Missing $path; first compile shared frameworks:" >&2
    echo "CONFIG=release ./scripts/build-shared-framework.sh" >&2
    echo "./scripts/build-native-core.sh" >&2
    exit 2
  fi
done
cd "$ROOT"
xcodegen generate --spec AppleApp/project.yml
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
results_dir="$ROOT/build/ios/iphone-ui-tests/$stamp"
mkdir -p "$results_dir/screenshots"
bundle="$results_dir/BBT-Bit-UI.xcresult"
team_flags=()
if [[ -n "${BBT_APPLE_TEAM_ID:-}" ]]; then
  team_flags+=("DEVELOPMENT_TEAM=$BBT_APPLE_TEAM_ID")
fi

set +e
xcodebuild \
  -project AppleApp/RedBit.xcodeproj \
  -scheme RedBit \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -parallel-testing-enabled NO \
  -resultBundlePath "$bundle" \
  test \
  "${team_flags[@]}" 2>&1 | tee "$results_dir/xcodebuild.log"
exit_code="${PIPESTATUS[0]}"
set -e

if [[ -d "$bundle" ]]; then
  xcrun xcresulttool get test-results summary --path "$bundle" --compact \
    > "$results_dir/xcresult-summary.json" 2> "$results_dir/summary-errors.log" || true
  xcrun xcresulttool get test-results tests --path "$bundle" --compact \
    > "$results_dir/xcresult-tests.json" 2> "$results_dir/test-errors.log" || true
  xcrun xcresulttool export attachments --path "$bundle" \
    --output-path "$results_dir/screenshots" \
    > "$results_dir/attachments.log" 2>&1 || true
fi
python3 - "$results_dir" "$exit_code" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
folder = Path(sys.argv[1])
code = int(sys.argv[2])
p = folder / "xcresult-summary.json"
try:
    summary = json.loads(p.read_text()) if p.exists() else None
except (OSError, ValueError):
    summary = None
report = {
    "schemaVersion": 1,
    "testType": "physical-iPhone-XCUITest-LiquidMotion-preview",
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "xcodebuildExitCode": code,
    "status": "passed" if code == 0 and summary else "failed-or-incomplete",
    "limitation": "Exercises 15 design preview screens and representative controls, NOT full streaming, actual Automix, network, downloads, party or Handoff functionality.",
    "xcresultSummary": summary,
    "attachmentCount": len(list((folder / "screenshots").rglob("*"))),
}
(folder / "BBT-Bit-iPhone-Testbericht.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
print("Report:", folder / "BBT-Bit-iPhone-Testbericht.json")
PY
archive="$results_dir/BBT-Bit-iPhone-Tests.zip"
(
  cd "$results_dir"
  zip -qry "$archive" BBT-Bit-iPhone-Testbericht.json screenshots xcodebuild.log \
    xcresult-summary.json xcresult-tests.json 2>/dev/null ||
  zip -qry "$archive" BBT-Bit-iPhone-Testbericht.json screenshots xcodebuild.log
)
echo "Upload this test ZIP: $archive"
exit "$exit_code"
