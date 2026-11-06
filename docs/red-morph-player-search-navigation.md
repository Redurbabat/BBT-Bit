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
- `RootView.swift`: während Tastatureingabe ein kompakter Mini-Player in einer `safeAreaInset` statt in einem überdeckenden `overlay`. Der Bottom Accessory wird auf unterstützten iOS-Versionen im Tastaturzustand ausgeblendet.
- `SearchView.swift`: `listSectionSpacing(.compact)` reduziert den Systemabstand zwischen Top-Ergebnis und Ergebnisteilen.
- `TopResultSection.swift`: geringere untere Randabstände, ruhigeres Material und separat erreichbare Aktionen.
- `InfinityDock.swift`: kompakte Werkzeugmenü-Komponente als vorhandene Designvorschau, **nicht mehr im Now-Playing-Deck montiert**.
- `AutomixWeave.swift`: statt der zweiten farbigen Vollbreiten-Leiste ein 44-pt-Status für das tatsächliche Übergangsfenster. Details öffnen eine native Ansicht. Der kompakte Status beansprucht weiterhin eine eigene Zeile unterhalb des Seek-Reglers; ein vollständig höhenneutrales Layout ist noch nicht erreicht.
- `LiquidPhotoWayfinderView.swift`, `LiquidMotionDesignPhotosView.swift` und `docs/live-iphone-screenshots.md`: Aufnahmehinweise auf den neuen Werkzeugzugang umgestellt. Die gespeicherte Feature-Kennung `dock` bleibt stabil.

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

Für Commit `469cf3b629e474a23348cdd59789b35a8ea5fd90` meldeten GitHub Actions die Workflows „Validate Codemagic iOS IPA configuration“, „BBT-Bit iPhone Simulator UI Tests“ und „BBT-Bit PR regression checks“ als **fehlgeschlagen**. Die Job-Protokolle waren über die verbundene API nicht abrufbar (`BlobNotFound`). Die Ursache ist **nicht diagnostiziert**. Weder ein funktionierender Build noch ein bestandener iPhone-Test wird behauptet.

## Grenzen und nächste Schritte

- Suche-/Tastaturverhalten im Simulator messen und Safe-Area-Inset gegebenenfalls an die reale iOS-26/27-Keyboard-Animation anpassen.
- Player-Hierarchie auf kompakten iPhones und großen Schriftgrößen überprüfen.
- Accessibility und deutsche String-Catalog-Einträge für alle tatsächlich neuen UI-Texte validieren.
- CI-Fehler anhand verfügbarer Job-Protokolle oder lokalem Xcode-Run eingrenzen.
- RED-Morph-Optical-Glass-Motion erst nach stabilen Layout- und Funktionsnachweisen weiter ausbauen.

Keine Änderung an `main`, kein Merge und keine Änderung an Kotlin, Rust, Decoder oder Nutzerdaten.
