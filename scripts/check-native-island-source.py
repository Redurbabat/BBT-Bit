#!/usr/bin/env python3
"""Tokenfreie Invarianten: native Dynamic-Island-Musik statt doppelter Live Activity.

Diese reine Quellprüfung testet keine iOS-Medienpriorität und keine Audioausgabe.
Ausführen: python3 scripts/check-native-island-source.py
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


native = read("AppleApp/Sources/PlaybackSession/NowPlayingController.swift")
legacy = read("AppleApp/Sources/PlaybackSession/NowPlayingActivityController.swift")
widget = read("AppleApp/Sources/Widget/BitChordWidget.swift")
app = read("AppleApp/project.yml")
root = read("AppleApp/Sources/UI/RootView.swift")
pill = read("AppleApp/Sources/UI/PlaybackPill.swift")
stage = read("AppleApp/Sources/UI/LiquidMotion/LogoGlassBloom.swift")

sources = (
    "AppleApp/Sources/PlaybackSession/PlaybackController+EngineEvents.swift",
    "AppleApp/Sources/PlaybackSession/PlaybackController+Loading.swift",
    "AppleApp/Sources/PlaybackSession/PlaybackController+LoadResults.swift",
    "AppleApp/Sources/PlaybackSession/PlaybackController+Queue.swift",
    "AppleApp/Sources/PlaybackSession/PlaybackController+AutomixState.swift",
)

calls = []
for path in sources:
    contents = read(path)
    # An update(position:) is not a song-metadata update; exclude it.
    for match in re.finditer(r"(?:self\.)?nowPlaying\.(?:update|prepareForPlayback)\(\s*id:", contents):
        args = contents[match.start():match.start() + 330]
        calls.append((path, "albumName:" in args))

checks = {
    "iOS 27: native NowPlaying nur mit SDK-Verfügbarkeit": (
        "#if canImport(NowPlaying)" in native
        and "if #available(iOS 27, *)" in native
        and "MediaSession<ModernNowPlaying>" in native
        and "requestToBecomeApplicationPrimary()" in native
        and "requestToBecomeSystemPrimary()" in native
    ),
    "iOS 18-26: native MediaPlayer-Metadaten und Fernsteuerung": (
        "MPNowPlayingInfoCenter.default().nowPlayingInfo = info" in native
        and "MPRemoteCommandCenter.shared()" in native
        and "MPNowPlayingInfoPropertyPlaybackRate" in native
        and "MPMediaItemPropertyAlbumTitle: albumName" in native
    ),
    "Albumtitel im neuen nativen MusicContent": (
        "albumName: albumName, type: .audio" in native
        and "self.albumName = albumName" in native
        and 'albumName: "Fixture Album"' in native
    ),
    "Alle acht Metadaten-Übergaben enthalten Albumname": (
        len(calls) == 8 and all(present for _, present in calls)
    ),
    "Keine zweite konkurrierende Musik-Live-Activity": (
        "Activity<NowPlayingActivityAttributes>.activities" in legacy
        and ".end(nil, dismissalPolicy: .immediate)" in legacy
        and "Activity.request(" not in legacy
        and "ActivityConfiguration(" not in widget
        and "NSSupportsLiveActivities" not in app
    ),
    "RED Morph: Mini-Player bleibt native Zoom-Quelle": (
        ".tabViewBottomAccessory" in root
        and "dockScroll.keepExpanded ? .never : .onScrollDown" in root
        and "matchedTransitionSource(id: NowPlayingZoom.sourceID" in pill
        and ".navigationTransition(.zoom(sourceID: NowPlayingZoom.sourceID" in root
    ),
    "Logo-Bloom ist App-Animation und nicht Hardware-Island": (
        "struct LogoGlassBloomIsland: View" in stage
        and "private var logoBloomShell" in root
    ),
    "Hintergrundaudio erlaubt": (
        "UIBackgroundModes:" in app and "- audio" in app
    ),
}

for label, passed in checks.items():
    print(f'{"OK" if passed else "FEHLER"}: {label}')

if not all(checks.values()):
    raise SystemExit("Native-Island-Quellinvarianten unvollständig.")

print(
    f"{len(checks)} statische Invarianten erfüllt. "
    "Apple-SDK-Typecheck, Dynamic Island am iPhone, Audio: NICHT GETESTET."
)
