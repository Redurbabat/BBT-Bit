#!/usr/bin/env python3
"""Protect German settings strings and dynamic SwiftUI localization.

Offline CI guard only. A real Xcode build and on-device language switch are
required for UI acceptance.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "AppleApp/Resources/Localization/Localizable.xcstrings"
SETTINGS = ROOT / "AppleApp/Sources/UI/Settings/SettingsView.swift"
ROWS = ROOT / "AppleApp/Sources/UI/Settings/SettingsRows.swift"
PLAYBACK = ROOT / "AppleApp/Sources/UI/Settings/SettingsView+Playback.swift"

MAIN = (
    "Settings", "Sources", "Sound & Quality", "Playback",
    "Downloads & Storage", "Appearance", "Account & Integrations",
    "Advanced Options", "Your Data & Backup", "About & Updates",
    "Search settings", "%lld enabled",
)
PLAYBACK_KEYS = (
    "Crossfade", "Automix [Beta]", "Phrase Length", "Smart Sequencing",
    "Mix on Skip", "Show Music Videos", "Play Music Videos over Cellular",
    "Trim Leading and Trailing Silence", "Skip Non-Music Segments",
    "Diagnostic Reports", "Skip Silence", "Playback Speed",
    "Play Alongside Other Apps", "Show Stats for Nerds",
    "Stop Converting Video Songs to Audio", "Prefer Music Only",
    "Automix Models", "Inactive while Automix controls transition timing",
    "Blends transitions automatically from each track’s timing.",
    "Order upcoming tracks for smooth transitions. Takes priority over Shuffle; manually queued tracks keep their order.",
    "Starts a music-video result on its catalogue audio release instead of the video's own upload",
)


def main() -> int:
    errors = []
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    if catalog.get("sourceLanguage") != "en":
        errors.append("Do not alter the existing English source language")
    for key in (*MAIN, *PLAYBACK_KEYS):
        result = catalog.get("strings", {}).get(key, {}).get("localizations", {}).get("de", {}).get("stringUnit", {})
        if not result.get("value") or result.get("state") != "translated":
            errors.append(f"Missing German localization: {key}")
    settings = SETTINGS.read_text(encoding="utf-8")
    rows = ROWS.read_text(encoding="utf-8")
    playback = PLAYBACK.read_text(encoding="utf-8")
    required = {
        "explicit app locale": ".environment(\\.locale, AppLanguage.locale(for: language))" in settings,
        "main/root titles": "Label(LocalizedStringKey(section.title)" in settings,
        "macOS sidebar titles": settings.count("Label(LocalizedStringKey(section.title)") >= 2,
        "detail page title": "navigationTitle(LocalizedStringKey(section.title))" in settings,
        "localized settings search": "AppLanguage.localized(title)" in settings,
        "row headline": "Text(LocalizedStringKey(title))" in rows,
        "row description": "Text(LocalizedStringKey(subtitle))" in rows,
        "localized performance text": "automixWorkerSubtitle" in playback,
    }
    errors.extend(f"Missing dynamic UI localization: {key}" for key, ok in required.items() if not ok)
    if errors:
        print("FAIL German settings localization:", file=sys.stderr)
        print("\n".join(f"- {problem}" for problem in errors), file=sys.stderr)
        return 1
    print(f"PASS {len(MAIN) + len(PLAYBACK_KEYS)} pinned German translations, dynamic labels and search")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
