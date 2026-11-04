#!/usr/bin/env python3
"""Turn an Xcode simulator test result into a clear JSON + Markdown report."""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

if len(sys.argv) != 5:
    sys.exit("Usage: python3 ci-ios-simulator-report.py <results-dir> <exit-code> <xcode-version> <simulator>")

folder = Path(sys.argv[1])
exit_code = int(sys.argv[2])
xcode = sys.argv[3]
simulator = sys.argv[4]
summary_file = folder / "xcresult-summary.json"
try:
    summary = json.loads(summary_file.read_text()) if summary_file.exists() else None
except (OSError, ValueError):
    summary = None

screenshot_files = sorted(
    p for p in (folder / "screenshots").rglob("*")
    if p.is_file() and p.suffix.lower() in (".png", ".jpg", ".jpeg", ".heic")
)
status = "passed" if exit_code == 0 and summary else "failed-or-incomplete"
report = {
    "schemaVersion": 1,
    "kind": "GitHub-Actions-iPhone-Simulator-XCUITest",
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "xcodeVersion": xcode,
    "simulator": simulator,
    "xcodebuildExitCode": exit_code,
    "status": status,
    "screenshotCount": len(screenshot_files),
    "screenshots": [str(p.relative_to(folder)) for p in screenshot_files],
    "testSummary": summary,
    "scope": (
        "This runs existing UI tests against 15 synthetic Liquid Motion design "
        "previews in a real iOS Simulator. It does NOT test an installed IPA "
        "on a physical iPhone, nor actual streaming, live song transitions, "
        "downloads, parties, or Handoff."
    ),
    "limitations": (
        "A successful archive/IPA output requires the separate Release build. "
        "An unsigned IPA is not directly installable on a normal device."
    ),
}
(folder / "BBT-Bit-Simulator-Testbericht.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n"
)

title = "PASSED" if status == "passed" else "FAILED / INCOMPLETE"
markdown = [
    "# BBT-Bit iPhone Simulator UI Test",
    "",
    f"**Status:** {title}",
    f"**Xcode:** {xcode}",
    f"**Simulator:** {simulator}",
    f"**xcodebuild exit code:** {exit_code}",
    f"**Screenshot attachment files:** {len(screenshot_files)}",
    "",
    "Runs 15 **sample-data design preview** checks, not full live playback.",
    "No real iPhone and no signed IPA were used.",
    "",
    "Download the artifact from the Actions run for JSON, logs and screenshots.",
]
(folder / "BBT-Bit-Simulator-Testbericht.md").write_text("\n".join(markdown) + "\n")
print("\n".join(markdown))
