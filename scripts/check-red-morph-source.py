#!/usr/bin/env python3
"""Statische RED-Morph-Quellinvarianten; ersetzt weder Swift-Typecheck noch UI-Tests.

Ohne Xcode, Account, Netzwerk, Build-Tokens oder Medienzugriff ausführbar:
    python3 scripts/check-red-morph-source.py
"""
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


search = source("AppleApp/Sources/UI/SearchView.swift")
root = source("AppleApp/Sources/UI/RootView.swift")
browse = source("AppleApp/Sources/UI/BrowseNavigation.swift")
pill = source("AppleApp/Sources/UI/PlaybackPill.swift")
home = source("AppleApp/Sources/UI/Library/HomeView.swift")
explore = source("AppleApp/Sources/UI/Library/ExploreView.swift")
dock = source("AppleApp/Sources/UI/LiquidMotion/DockScrollDirection.swift")
top = source("AppleApp/Sources/UI/TopResultSection.swift")
stage = source("AppleApp/Sources/UI/NowPlaying/NowPlayingView+Stage.swift")
transport = source("AppleApp/Sources/UI/NowPlaying/NowPlayingView+Transport.swift")
layouts = source("AppleApp/Sources/UI/NowPlaying/NowPlayingView+Layouts.swift")
catalog = json.loads(source("AppleApp/Resources/Localization/Localizable.xcstrings"))

localization_keys = (
    "Search artists, songs and lyrics",
    "Clear search",
    "Music tools",
    "Audio tools",
    "Automix transition planned",
    "Top result",
    "Add to Playlist",
    "Not Playing",
    "Music you start appears here",
    "Opens Now Playing",
)

checks = {
    "Native iPhone-Suche wieder integriert": (
        "private struct CompactPhoneSearchDrawer: ViewModifier" in search
        and "phoneSearchField" not in search
        and ".modifier(CompactPhoneSearchDrawer(" in search
        and "isSearchPresented = true" in search
        and "if horizontalSizeClass != .regular, term.isEmpty {" in search
        and 'role: .search' in root
    ),
    "Top-Ergebnis hat getrennte Aktionen": (
        ".onTapGesture(perform: play)" not in top
        and "ViewThatFits(in: .horizontal)" in top
        and ".fixedSize(horizontal: false, vertical: true)" in top
        and ".labelStyle(.titleAndIcon)" in top
    ),
    "Kein ausklappbares Dock im Player": "InfinityDock(" not in stage,
    "Automix innerhalb der Zeitzeile": (
        "HStack(spacing: 8)" in transport
        and "AutomixWeave(" in transport
        and ".frame(minHeight: 44)" in transport
    ),
    "Tastatur-Inset ohne doppelte Glasfläche": (
        ".safeAreaInset(edge: .bottom, spacing: 0)" in root
        and "PlaybackPill(inline: true)\n                    .frame(maxWidth: 440)" in root
        and "#if compiler(>=6.2.3)" in root
        and "if #available(iOS 26.1, *)" in root
        and "content.tabViewBottomAccessory(isEnabled: !keyboardUp)" in root
        and "if !keyboardUp {\n                    PlaybackAccessory()" in root
        and "if !keyboardUp {\n                PlaybackAccessory()" in root
        and "var usesSystemChrome = false" in pill
        and "usesSystemChrome: usesSystemChrome" in pill
        and "horizontalSizeClass == .compact, usesSystemChrome" in pill
    ),
    "Native Tab-Leiste und Mini-Player minimieren beim Scrollen": (
        "private struct PlaybackAccessory: View" in root
        and ".tabViewBottomAccessory" in root
        and "@State private var dockScroll = DockScrollCoordinator.shared" in root
        and ".modifier(KeyboardPlaybackChrome())" in browse
        and "content.tabBarMinimizeBehavior(.onScrollDown)" in root
        and "content.tabBarMinimizeBehavior(.never)" not in root
        and ".modifier(DockScrollDirectionObserver())" in home
        and ".modifier(DockScrollDirectionObserver())" in explore
        and "keepExpanded = newDirection == .towardTop" not in dock
        and "inline: placement == .inline, usesSystemChrome: true" in root
        and ".modifier(NowPlayingZoomSource())" in pill
        and "matchedTransitionSource(id: NowPlayingZoom.sourceID" in pill
        and ".navigationTransition(.zoom(sourceID: NowPlayingZoom.sourceID" in root
    ),
    "Reduce Motion im Player-Layout": (
        "reduceMotion ? nil : .easeInOut" in layouts
    ),
    "Deutsche UI-Übersetzungen vorhanden": all(
        catalog["strings"].get(key, {})
        .get("localizations", {})
        .get("de", {})
        .get("stringUnit", {})
        .get("value")
        for key in localization_keys
    ),
}

for label, passed in checks.items():
    print(f'{"OK" if passed else "FEHLER"}: {label}')

failed = [label for label, passed in checks.items() if not passed]
if failed:
    raise SystemExit(
        f"{len(failed)} statische RED-Morph-Quellprüfung(en) fehlgeschlagen."
    )

print(
    f"{len(checks)} Quellinvarianten erfüllt. "
    "Swift-Kompilierung, Simulator, signierte IPA und Audio: NICHT GETESTET."
)
