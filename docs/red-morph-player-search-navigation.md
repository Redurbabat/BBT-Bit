# RED Morph – Player, Suche und Navigation

**Arbeitsbranch:** `feature/red-morph-player-search-navigation`  
**Review:** [Draft-PR #49](https://github.com/Redurbabat/BBT-Bit/pull/49)  
**Ziel:** Eine zusammenhängende, ruhige Such- und Wiedergabeoberfläche; keine Änderung der Audio- oder Datenarchitektur.

## Ausgangslage

Die iPhone-Aufnahmen vom 06.11.2026 zeigen drei verbesserungswürdige Zustände:

- Der erweiterte Infinity-Dock-Bereich vergrößerte die Höhe des Player-Decks. Artwork, Songinformationen und Seek-Regler verschoben sich.
- Der Mini-Player wurde beim Einblenden der Tastatur als Overlay über die Suchergebnisse gelegt.
- Zwischen dem hervorgehobenen Suchergebnis und den normalen Songreihen war ein großer Abschnittsabstand sichtbar.

Weitere Beobachtungen: doppelte Zugänge zu Queue und Lyrics, deaktivierter „Lyrics off“-Platzhalter und konkurrierende Glasflächen.

## Implementierter Zwischenschritt

- `NowPlayingView+Stage.swift`: keine zusätzliche Dock-Reihe im Player-Deck; der Lyrics-Streifen erscheint nur bei ladenden oder vorhandenen Lyrics.
- `NowPlayingView+Transport.swift`: die sechs bisherigen Werkzeugaktionen sind über das vorhandene Mehr-Menü erreichbar. Equalizer, Pipeline, Audioausgabe und Automix rufen die bisherigen Zustände/Aktionen auf. Die vorhandenen direkten Lyrics- und Queue-Zugänge bleiben erhalten.
- `RootView.swift`: während Tastatureingabe ein kompakter Mini-Player in einer `safeAreaInset` statt in einem überdeckenden `overlay`. Der Bottom Accessory wird auf unterstützten iOS-Versionen im Tastaturzustand ausgeblendet. Die iPhone-Tab-Leiste minimiert beim Scrollen nicht mehr automatisch (`tabBarMinimizeBehavior(.never)`); Navigation und Wiedergabe bleiben zwei stabile Ebenen.
- `SearchView.swift`: `listSectionSpacing(.compact)` und die Entfernung der eigenen Top-Result-Section reduzieren den Abstand zwischen Top-Ergebnis und Ergebnisteilen.
- `TopResultSection.swift`: geringere untere Randabstände, ruhigeres Material und separat erreichbare Aktionen. Die zuvor auf der gesamten Karte liegende Tap-Geste wurde durch explizite Wiedergabeknöpfe auf Artwork und Titel ersetzt, sodass Playlist- und Menüinteraktionen nicht zugleich Wiedergabe auslösen sollen.
- `InfinityDock.swift`: kompakte Werkzeugmenü-Komponente als vorhandene Designvorschau, **nicht mehr im Now-Playing-Deck montiert**.
- `AutomixWeave.swift`: statt der zweiten farbigen Vollbreiten-Leiste ein 44-pt-Status für das tatsächliche Übergangsfenster. Details öffnen eine native Ansicht. Der Status liegt jetzt mittig in der Zeitzeile mit fester Mindesthöhe; das Erscheinen eines Übergangsfensters erzeugt keine zusätzliche Zeile.
- `LiquidPhotoWayfinderView.swift`, `LiquidMotionDesignPhotosView.swift` und `docs/live-iphone-screenshots.md`: Aufnahmehinweise auf den neuen Werkzeugzugang umgestellt. Die gespeicherte Feature-Kennung `dock` bleibt stabil.

- `NowPlayingView.swift`, `NowPlayingView+Stage.swift` und `PlaybackPill.swift`: Pane-Übergänge, Lyrics-Auto-Hide und Mini-Player-Pull respektieren `accessibilityReduceMotion`; die Gesten und direkten Buttons bleiben erreichbar.

Dies ist eine **Quellcodeänderung**, kein bestätigter iPhone-Funktionstest.

## RED-Morph-Designregeln

1. **Funktion vor Motion.** Wiedergabezustände bleiben Eigentum der bestehenden `PlaybackController`-/PlaybackSession-Instanz.
2. **Optical Glass als Material.** Adaptive Kontraste, ruhige Kanten, keine Neon-Glows. `Reduce Transparency` respektieren.
3. **Kontinuität.** Mini-Player und Vollplayer verwenden denselben Artwork-Kontext. Werkzeuge verändern nicht die Transportposition.
4. **Unterbrechbarkeit.** Aktionen und Zurück-Navigation dürfen nicht durch Morph-Animationen blockiert werden.
5. **Nur eine primäre Funktion je Ebene.** Songtitel und Transport im Player; erweiterte Audio-Werkzeuge im Mehr-Menü; Queue und Lyrics direkt erreichbar.

## Plattformkonzept und tatsächlicher Stand

| Plattform | Beabsichtigtes Verhalten | Implementierungsstand dieses Branches |
| --- | --- | --- |
| iPhone | Native Suche; keyboard-safe kompaktes Pill; aufgeräumter Vollplayer, festes Transport-Deck | SwiftUI-Quellcode geändert; Gerätetest offen |
| iPad | Quelle und Suche in adaptiver Toolbar, Player-Inhalte neben Sidebar, keine doppelte Dock-Reihe | Gemeinsamer Stage-Code geändert; iPad-Test offen |
| macOS | Tastatur-/Pointer-Zugang, Toolbar und Inspector statt aufgeblasener iPhone-Ansicht | Gemeinsames Mehr-Menü geändert; Mac-Test offen |
| Windows | Eigenständige Desktop-Navigation, Fokuszustände und Player-/Inspector-Aufteilung nach RED Morph | **Nur Designkonzept**. BBT-Bit hat in diesem Branch kein Windows-UI-Target |

## Abnahmematrix

| Testfall | Erwartetes Ergebnis | Stand |
| --- | --- | --- |
| iPhone: Suche fokussieren und Tastatur öffnen | Mini-Player kompakt oberhalb Tastatur; Ergebnisliste nicht verdeckt | NICHT GETESTET |
| iPhone: Tastatur schließen | Ein nativer Mini-Player; keine doppelte Wiedergabeleiste | NICHT GETESTET |
| Suche: Filter wechseln, scrollen, Top-Ergebnis abspielen | Keine große Leerfläche; Suche und Wiedergabe bleiben funktionsfähig | NICHT GETESTET |
| Player: Mehr-Menü öffnen und schließen | Artwork, Seek und Transport behalten Position | NICHT GETESTET |
| Player: EQ, Pipeline, Output, Automix | Alle bisherigen Aktionen funktionieren; Automix spiegelt Zustand korrekt | NICHT GETESTET |
| Automix: geplantes und aktives Fenster öffnen | Ein kompakter Status, echte Fortschrittsdaten und separates Detail-Sheet; kein Verschieben des Transport-Decks | NICHT GETESTET |
| Player: Lyrics/Queue öffnen und schließen | Pane-Wechsel bleibt erreichbar, Musik läuft weiter | NICHT GETESTET |
| VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency | Bedienelemente erreichbar; Texte lesbar; keine blockierten Übergänge | NICHT GETESTET |
| iPad Split View, macOS-Fenstergrößen | Adaptive Anordnung und Tastatursteuerung | NICHT GETESTET |
| Physisches iPhone: YouTube, Pause, Seek, Ausgabe | Tatsächlich hörbare Wiedergabe ohne Regression | NICHT GETESTET |

## Ergänzende Prüfmaßnahmen

- Die frühe Swift-Parser-Schleife in `.github/workflows/ios-simulator-tests.yml` umfasst jetzt zusätzlich `SearchView.swift`, `TopResultSection.swift`, `NowPlayingView+Stage.swift` und `NowPlayingView+Transport.swift`. Dies ersetzt weder Typechecking noch Simulator-Build.
- Die Automix-Statusfläche wurde für weiße Schrift auf einen dunklen Untergrund gestellt; das Sheet nutzt auf iOS Detents und auf macOS eine feste Mindestgröße.

## CI-Stand

GitHub Actions melden weiterhin Fehlschläge. Bei der Abfrage der Läufe zum Commit `abaadb5970898686c8ba0a5c44346cbb9bede84b` wurden die drei Workflows „Validate Codemagic iOS IPA configuration“, „BBT-Bit iPhone Simulator UI Tests“ und „BBT-Bit PR regression checks“ nach nur **2–3 Sekunden** als `failure` abgeschlossen. Der REST-Endpunkt `/actions/runs/{id}/jobs` lieferte **leere Schrittlisten** für die betroffenen Jobs, darunter auch `ubuntu-latest`.

**Befund:** Keine erfolgreiche Syntax-, Build-, Unit- oder Simulatorprüfung wurde dadurch nachgewiesen. Es gibt aus diesen Jobs auch **keinen nachgewiesenen Swift-Kompilierfehler**; die Jobs scheinen vor ihren regulären Schritten beendet worden zu sein. Die eigentliche Ursache (z. B. Runner-Zuweisung, Kontingent, Plattform oder Konfiguration) ist **nicht verifiziert**. Die Job-Log-API meldete weiterhin `BlobNotFound`, und es wurden keine Simulator-Artefakte zurückgeliefert.

Eine Quellprüfung bestätigte im GitHub-Branch die erwarteten Aufrufstellen und Änderungen. Sie ist kein Ersatz für das SDK-Typechecking oder Gerätetests.

## Zusätzliche Umsetzung und Review (06.11.2026)

- **iPhone/iPad/macOS:** Die Player-Anordnungen berücksichtigen bei Pane-Wechseln `accessibilityReduceMotion`. Der kompakte Querformat-Player zeigt den Lyrics-Streifen nur bei vorhandenen oder ladenden Songtexten; ein deaktivierter Platzhalter nimmt keinen Raum ein.
- **Player-Aktionsleiste:** Auch der Wechsel zwischen Ausgabe- und Queue-Werkzeugen verwendet bei `Reduce Motion` keine Skalierungsanimation. Die Player-Mehr-Schaltfläche und das Top-Result-Menü haben eine mindestens 44 × 44 pt große Interaktionsfläche.
- **Tastatur und Mini-Player:** Das iPhone-Safe-Area-Inset nutzt die vorhandene Mini-Player-Darstellung ohne zusätzliche Glasbeschichtung. Die tatsächliche Tastaturhöhe und die Navigation müssen noch auf dem Simulator bestätigt werden.
- **Lokalisierung:** Neu eingeführte UI-Bezeichner für Suche, Player-Werkzeuge und Automix verwenden englische Ausgangsschlüssel mit deutschen Übersetzungen in `Localizable.xcstrings`. Vorhandene Übersetzungen anderer Sprachen bleiben unverändert; für neue Schlüssel sind diese Sprachen noch nicht übersetzt.
- **XCUITest:** Der iPhone-Clear-Button trägt nun selbst die sprachunabhängige Kennung `bbt.search.clear` (zuvor versehentlich nur am macOS-Feld gesetzt). Der Test prüft zusätzlich die erneute Fokussierung nach dem Löschen. Der Test ist im Repository vorhanden, wurde aber noch nicht auf einem Simulator ausgeführt.
- **Geltungsbereich:** Kein Eingriff in Streaming, Rust-Audio-Engine, Persistenz, Konten oder Nutzerdaten. Es gibt weiterhin keinen Nachweis eines erfolgreichen Apple-SDK-Typechecks, einer signierten IPA oder hörbarer Wiedergabe.

**CI-Kontingent:** Der Projektinhaber hat bestätigt, dass aktuell keine Build-Tokens verfügbar sind. Daher werden keine zusätzlichen GitHub-Actions- oder Codemagic-Läufe manuell ausgelöst. Die Ursache der fehlenden Runner-Zuweisung ist mit dem ausgeschöpften Kontingent vereinbar, wurde aber nicht durch eine Abrechnungs-API separat bestätigt. Sobald Kapazität verfügbar ist, müssen die normalen Workflows und der echte iPhone-Test nachgeholt werden.

## Grenzen und nächste Schritte

- Suche-/Tastaturverhalten im Simulator messen und Safe-Area-Inset gegebenenfalls an die reale iOS-26/27-Keyboard-Animation anpassen.
- Player-Hierarchie auf kompakten iPhones und großen Schriftgrößen überprüfen.
- Accessibility und deutsche String-Catalog-Einträge für alle tatsächlich neuen UI-Texte validieren.
- CI-Fehler anhand verfügbarer Job-Protokolle oder lokalem Xcode-Run eingrenzen.
- RED-Morph-Optical-Glass-Motion erst nach stabilen Layout- und Funktionsnachweisen weiter ausbauen.

Keine Änderung an `main`, kein Merge und keine Änderung an Kotlin, Rust, Decoder oder Nutzerdaten.
