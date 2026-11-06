# Originale Apple-SwiftUI-Bausteine für BBT-Bit und RED Morph

**Stand: 06.11.2026 | Branch:** `feature/red-morph-player-search-navigation` · [Draft-PR #49](https://github.com/Redurbabat/BBT-Bit/pull/49)

## Umfang und Abgrenzung

Diese Prüfung übernimmt **Apples offiziell dokumentierte API-Muster**, nicht den Quellcode der Apple-Music-App oder ein fremdes App-Beispielprojekt. Bereits funktionierende native BBT-Bit-Komponenten bleiben erhalten. Ohne Apple-SDK und echtes iPhone ist das Ergebnis eine **Quellcodeänderung mit offener Geräteabnahme**, kein fertiger optischer Klon.

| Originale Apple-Technik | Umsetzung in BBT-Bit / RED Morph | Status |
| --- | --- | --- |
| `Tab(role: .search)`, `.searchable` und `.navigationBarDrawer(displayMode: .always)` | [RootView](../AppleApp/Sources/UI/RootView.swift), [SearchView](../AppleApp/Sources/UI/SearchView.swift); integrierte iPhone-Suche nach voriger Regression wiederhergestellt | Bereits im Original; beibehalten |
| `.tabBarMinimizeBehavior(.onScrollDown)`, `.tabViewBottomAccessory` | [RootView](../AppleApp/Sources/UI/RootView.swift), [DockScrollDirection](../AppleApp/Sources/UI/LiquidMotion/DockScrollDirection.swift); ein einziger Mini-Player wechselt beim Abwärtsscrollen in den Inline-Modus, bei Aufwärtsbewegung zurück | Bereits im Original; beibehalten |
| `@Environment(\.tabViewBottomAccessoryPlacement)` | [PlaybackAccessory in RootView](../AppleApp/Sources/UI/RootView.swift) und [PlaybackPill](../AppleApp/Sources/UI/PlaybackPill.swift) nutzen das systemeigene `.inline`/ausgeklappte Layout | Bereits im Original; beibehalten |
| **`.tabViewBottomAccessory(isEnabled: !keyboardUp)`** | Bei verfügbarer iOS-Version (konservativ ab iOS 26.1) schaltet der Systemmodifier den nativen Accessory während des Such-Tastaturzustands ausdrücklich ab; das vorhandene `safeAreaInset` zeigt dann genau ein kompaktes Playback-Pill. iOS 26.0 behält den kompatiblen bisherigen Pfad | **Neu geändert**; iPhone-Test ausstehend |
| `matchedTransitionSource` mit `navigationTransition(.zoom(...))` | [PlaybackPill](../AppleApp/Sources/UI/PlaybackPill.swift) als Quelle; [RootView](../AppleApp/Sources/UI/RootView.swift) präsentiert Vollplayer | Bereits im Original; beibehalten |
| `ViewThatFits(in: .horizontal)` | [TopResultSection](../AppleApp/Sources/UI/TopResultSection.swift) ordnet Play / Playlist-Button bei Platzmangel vertikal an, mit 44-pt-Tapzielen | Schon auf RED-Morph-Branch umgesetzt |
| `.sheet`, `.presentationDetents` | [AutomixWeave](../AppleApp/Sources/UI/LiquidMotion/AutomixWeave.swift): kompakte Anzeige, native Detailansicht ohne Verschiebung der Transportelemente | Schon auf RED-Morph-Branch umgesetzt |
| `accessibilityReduceMotion` | [PlaybackPill](../AppleApp/Sources/UI/PlaybackPill.swift), [SearchView](../AppleApp/Sources/UI/SearchView.swift) und Player-Layouts reduzieren eigene Animationen, Bedienaktionen bleiben | Schon auf RED-Morph-Branch umgesetzt |
| `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`, ab iOS 27 `MediaSession` | [NowPlayingController](../AppleApp/Sources/PlaybackSession/NowPlayingController.swift) veröffentlicht echte Audiometadaten und Systemtransport; Albumnamen-Weitergabe auf diesem Branch ergänzt | Native Originalanbindung vorhanden; ergänzt |
| Liquid Glass / Landmarks-Designprinzipien | Bestehende Material-/Glass-Komponenten, Apple-System-Tab-Bar und Safe Areas zuerst verwenden; App-spezifisches Branding bleibt. **Keine** Übernahme des vollständigen Landmarks-Projekts, der Apple-Music-Oberfläche oder eigener System-Island-Nachbauten | Prinzipien geprüft, kein App-Code kopiert |

## Warum nur eine neue API-Anpassung?

Die vorherige GitHub-Gegenüberstellung von `main` und RED Morph hat gezeigt: **Suchrolle, Bottom-Accessory-Morph, Scrollrichtungsbeobachtung, native Zoomquelle und die Medienintegration waren schon vorhanden**. Ein Neubau würde diese Ausgangsfunktionen gefährden. Die konkrete Lücke bei der Tastatur war das bisherige bedingte Rendern des Accessory-Inhalts bei weiterhin bestehendem Systemcontainer. Apples `isEnabled:`-API bildet die Absicht explizit ab.

**Rückfallregel:** Auf iOS 26.0 bleibt `.tabViewBottomAccessory { PlaybackAccessory() }` bestehen. Unter der Tastatur steht das Pill über dem bestehenden `safeAreaInset`; eine Überlappung der unteren Leiste ist auf iOS 26.0 geräteabhängig zu überprüfen. Keine neue dynamische Tab-Bar und kein globales `.tabBarMinimizeBehavior(.never)`.

## Offizielle Apple-Quellen (API-Referenzen)

- [Apple: tabViewBottomAccessory(isEnabled:content:)](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory%28isenabled%3Acontent%3A%29)
- [Apple: TabViewBottomAccessoryPlacement](https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement)
- [Apple: TabBarMinimizeBehavior](https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior)
- [Apple: TabRole.search](https://developer.apple.com/documentation/swiftui/tabrole/search)
- [Apple: Search](https://developer.apple.com/documentation/swiftui/search)
- [Apple: ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)
- [Apple: matchedTransitionSource](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource%28id%3Ain%3Aconfiguration%3A%29)
- [Apple: Publishing media sessions](https://developer.apple.com/documentation/nowplaying/publishing-media-sessions)
- [Apple: Landmarks – Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Apple WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)

## Geräteabnahme für diesen Commit

1. Echtes iPhone mit **iOS 26.1 oder höher**: Song spielen, Mini-Player oberhalb großer Tab-Leiste, nach unten scrollen → native minimierte Tab-Leiste mit Inline-Pill; sofort nach oben umkehren → ausgeklappter Zustand. Zoom zum Vollplayer und zurück.
2. Search-Tab öffnen, Feld fokussieren → bei Tastatur **genau ein** Player über der Tastatur, **kein** zweiter in der Tab-Leiste und kein leeres System-Accessory-Band. Tastatur schließen → nativer Bottom Accessory erscheint wieder.
3. Auf **iOS 26.0** (Fallback) den gleichen Tastaturtest; überprüfen, ob sich System-Pill unter der Tastatur versteckt oder kurz überlappt. Bei sichtbarer Duplikation ist der Fallback gesondert zu korrigieren.
4. iPhone mit kleiner Höhe, Dynamic Type, VoiceOver, Reduce Motion und Reduce Transparency; Suche bleibt integriert. Zusätzlich iPad/macOS und älteres iOS (18–25) als Regressionstest.
5. Nativer Now-Playing-/Dynamic-Island-Transport und *hörbare* Musik bei Pause, Resume, Seek und Skip; Offline- und Streaming-Quellen getrennt verifizieren.

**Prüfstatus:** Die konkrete neue Modifier-Anbindung und die aktualisierten Quellinvarianten sind auf dem Branch geschrieben. Swift-Compile, XCUITest, echter iPhone-Animations-/Audio-/Dynamic-Island-Test und signierte IPA: **NICHT GETESTET**. Kein kostenpflichtiger CI-Lauf gestartet. [RED-Morph-Testplan](TESTPLAN.md) · [Systeminsel](native-dynamic-island-red-morph.md).

**Grundsatz:** Bestehende BBT-Bit-Funktionen, Audiozustand und Nutzerdaten erhalten. Kein Commit auf `main`, kein Merge ohne Nutzerfreigabe.
