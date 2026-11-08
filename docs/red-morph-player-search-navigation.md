# RED Morph – Player, Suche und Navigation

**Arbeitsbranch:** `feature/red-morph-player-search-navigation`  
**Review:** [Draft-PR #49](https://github.com/Redurbabat/BBT-Bit/pull/49)  
**Ziel:** Eine zusammenhängende, ruhige Such- und Wiedergabeoberfläche; keine Änderung der Audio- oder Datenarchitektur.

## Verbindliche Referenzanimation und Fehlerchronik (06.11.2026)

Die vom Nutzer geteilte iPhone-Aufnahme und das anschließend bereitgestellte Referenzvideo legen den gewünschten **nativen** Ablauf fest. Das Referenzvideo ist eine Gesprächsreferenz und wird **nicht** ins öffentliche Repository übernommen:

1. **Ausgeklappt:** Der Mini-Player liegt als ein einziges `tabViewBottomAccessory` **oberhalb** der normalen Tab-Leiste; Cover, Wiedergabe und Songinformationen bleiben bedienbar.
2. **Abwärtsscrollen:** Die System-Tab-Leiste minimiert; derselbe Mini-Player gleitet in die **Inline-Position der kompakten Tab-Leiste** (`tabViewBottomAccessoryPlacement == .inline`). Kein feststehender zweiter Player, keine konkurrierende Custom-Leiste.
3. **Aufwärtsscrollen / Richtungsumkehr:** Die Leiste expandiert wieder und das Pill steht darüber. Die `DockScrollCoordinator`-Logik erhält schnelle Richtungswechsel.
4. **Mini-Player → Vollplayer → zurück:** `matchedTransitionSource` und `navigationTransition(.zoom(...))` erhalten den zusammenhängenden Artwork-/Player-Übergang. Such-Tastatur, Safe Area, Reduce Motion und laufende Audiowiedergabe dürfen nicht beeinträchtigt werden.

**Was schiefging:** Zuerst wurde die zuvor integrierte iPhone-Suche durch ein separates Feld ersetzt. Danach wurde zur Ruhigstellung der unteren Navigation `content.tabBarMinimizeBehavior(.never)` dauerhaft gesetzt. Das trennte die Suche optisch ab und beseitigte die vom Nutzer erwartete Scroll-Animation. Beide Änderungen wurden nach konkretem Nutzerfeedback auf diesem Feature-Branch **im Quellcode zurückgenommen**; nicht auf `main` gemergt. Siehe [Entscheidungen E-014/E-015](../ENTSCHEIDUNGEN.md) und [Probleme P-011/P-012](../PROBLEME.md).

**Status:** Die Soll-Implementierung ist im Quellcode wieder angeschlossen, aber auf einem neuen iPhone-Build **NICHT GETESTET**. Ein Screenshot des alten installierten Builds beweist nicht, dass die Korrektur bereits auf dem Gerät ist. Keine CI-Neustarts bei ausgeschöpftem Build-Kontingent.

## Ausgangslage

Die iPhone-Aufnahmen vom 06.11.2026 zeigen drei verbesserungswürdige Zustände:

- Der erweiterte Infinity-Dock-Bereich vergrößerte die Höhe des Player-Decks. Artwork, Songinformationen und Seek-Regler verschoben sich.
- Der Mini-Player wurde beim Einblenden der Tastatur als Overlay über die Suchergebnisse gelegt.
- Zwischen dem hervorgehobenen Suchergebnis und den normalen Songreihen war ein großer Abschnittsabstand sichtbar.

Weitere Beobachtungen: doppelte Zugänge zu Queue und Lyrics, deaktivierter „Lyrics off“-Platzhalter und konkurrierende Glasflächen.

## Aktueller Implementierungsstand (Quellcode; nicht auf dem Gerät freigegeben)

- `NowPlayingView+Stage.swift`: keine zusätzliche Dock-Reihe im Player-Deck; der Lyrics-Streifen erscheint auf dem iPhone nur im Hauptplayer bei ladenden oder vorhandenen Lyrics, nicht mehr über der Queue.
- `NowPlayingView+Transport.swift`: die sechs bisherigen Werkzeugaktionen sind über das vorhandene Mehr-Menü erreichbar. Equalizer, Pipeline, Audioausgabe und Automix rufen die bisherigen Zustände/Aktionen auf. Die vorhandenen direkten Lyrics- und Queue-Zugänge bleiben erhalten.
- `RootView.swift`: während Tastatureingabe ein kompakter Mini-Player in einer `safeAreaInset` statt in einem überdeckenden `overlay`; auf unterstützten iOS-Versionen wird der native Bottom Accessory im Tastaturzustand ausgeblendet. **Beim normalen Scrollen minimiert die native Tab-Leiste weiterhin automatisch**: `tabBarMinimizeBehavior(dockScroll.keepExpanded ? .never : .onScrollDown)`. Das Playback-Pill wechselt über den System-Bottom-Accessory-Placement in die Inline-Darstellung.
- `SearchView.swift`: `listSectionSpacing(.compact)` und die Entfernung der eigenen Top-Result-Section reduzieren den Abstand zwischen Top-Ergebnis und Ergebnisteilen. Nach Nutzerfeedback wurde **die ursprüngliche native iPhone-Suche** mit `CompactPhoneSearchDrawer`, `.searchable(... .navigationBarDrawer(displayMode: .always))`, `isSearchPresented` und `role: .search` wiederhergestellt; der Quellen-Picker erscheint bei leerem Suchbegriff wie zuvor. Die iPad-Toolbar-Suche bleibt erhalten.
- `TopResultSection.swift`: geringere untere Randabstände, ruhigeres Material und separat erreichbare Aktionen. Die zuvor auf der gesamten Karte liegende Tap-Geste wurde durch explizite Wiedergabeknöpfe auf Artwork und Titel ersetzt, sodass Playlist- und Menüinteraktionen nicht zugleich Wiedergabe auslösen sollen. Die Aktionsknöpfe wechseln per `ViewThatFits` bei geringem Platz auf eine vertikale Anordnung und bleiben mindestens 44 pt hoch.
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
6. **Native Scroll-Kopplung ist eine Pflichtfunktion.** Tab-Bar und Mini-Player wechseln beim Abwärtsscrollen gemeinsam in den Inline-Zustand und beim Hochscrollen zurück. Keine dauerhafte `.never`-Minimierung, keine zweite Dock-Leiste und keine abgetrennte iPhone-Suche. Der Mini-Player bleibt die Zoom-Quelle zum Vollplayer.

## Plattformkonzept und tatsächlicher Stand

| Plattform | Beabsichtigtes Verhalten | Implementierungsstand dieses Branches |
| --- | --- | --- |
| iPhone | Wiederhergestellte native Suche; systemgekoppeltes Scroll-Pill mit Inline-Modus; keyboard-safe Pill; Vollplayer-Zoom; festes Transport-Deck | SwiftUI-Quellcode geändert; Scroll-Animation und Gerätetest offen |
| iPad | Quelle und Suche in adaptiver Toolbar, Player-Inhalte neben Sidebar, keine doppelte Dock-Reihe | Gemeinsamer Stage-Code geändert; iPad-Test offen |
| macOS | Tastatur-/Pointer-Zugang, Toolbar und Inspector statt aufgeblasener iPhone-Ansicht | Gemeinsames Mehr-Menü geändert; Mac-Test offen |
| Windows | Eigenständige Desktop-Navigation, Fokuszustände und Player-/Inspector-Aufteilung nach RED Morph | **Nur Designkonzept**. BBT-Bit hat in diesem Branch kein Windows-UI-Target |

## Abnahmematrix

| Testfall | Erwartetes Ergebnis | Stand |
| --- | --- | --- |
| iPhone: Suche fokussieren und Tastatur öffnen | Mini-Player kompakt oberhalb Tastatur; Ergebnisliste nicht verdeckt | NICHT GETESTET |
| iPhone: Tastatur schließen | Ein nativer Mini-Player; keine doppelte Wiedergabeleiste | NICHT GETESTET |
| iPhone: „Jetzt hören“/„Entdecken“ nach unten scrollen | Tab-Bar wird kompakt; dasselbe Pill wechselt **inline** in die native Leiste, keine feste zweite Pill-Reihe | NICHT GETESTET |
| iPhone: innerhalb derselben Geste nach oben umkehren | Native Tab-Bar klappt mit Mini-Player wieder auf, ohne Sprung oder Duplikat | NICHT GETESTET |
| iPhone: Mini-Player öffnen und Vollplayer schließen | Zusammenhängender Zoom vom Pill zum Vollplayer und zurück; keine Wiedergabeunterbrechung | NICHT GETESTET |
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
- **XCUITest:** Der zwischenzeitliche Test für die inzwischen verworfene separate iPhone-Suchleiste wurde entfernt. Die aktuelle native Suche und die Scroll-/Zoom-Animation benötigen neue gerätebasierte Regressionstests; **NICHT GETESTET**.
- **Geltungsbereich:** Kein Eingriff in Streaming, Rust-Audio-Engine, Persistenz, Konten oder Nutzerdaten. Es gibt weiterhin keinen Nachweis eines erfolgreichen Apple-SDK-Typechecks, einer signierten IPA oder hörbarer Wiedergabe.

**CI-Kontingent:** Der Projektinhaber hat bestätigt, dass aktuell keine Build-Tokens verfügbar sind. Daher werden keine zusätzlichen GitHub-Actions- oder Codemagic-Läufe manuell ausgelöst. Die Ursache der fehlenden Runner-Zuweisung ist mit dem ausgeschöpften Kontingent vereinbar, wurde aber nicht durch eine Abrechnungs-API separat bestätigt. Sobald Kapazität verfügbar ist, müssen die normalen Workflows und der echte iPhone-Test nachgeholt werden.

## Tokenfreie Quellprüfungen (06.11.2026)

- `python3 scripts/check-red-morph-source.py` (Standardbibliothek, keine Apple-SDKs und keine Netzwerkverbindung) prüft aktuell **acht Quellinvarianten**, einschließlich integrierter nativer Suche, Scroll-Observer, `DockScrollCoordinator`, `.onScrollDown`, `tabViewBottomAccessoryPlacement`/Inline und Zoom-Quelle/-Ziel. Die acht entsprechenden Bedingungen wurden anhand der GitHub-Quellen manuell gegengeprüft: **8/8 strukturelle Bedingungen vorhanden**. Das ist **kein ausgeführter Python-Prozess auf einem Checkout** und kein Swift-Typecheck.
- Der normale Workflow `.github/workflows/pr-regressions.yml` führt dieses Skript nach der Repository-Verifikation aus, sobald GitHub Actions wieder Runner bereitstellt. Laufzeit und Erfolg dieser CI-Stufe: **NICHT GETESTET**.
- Der temporäre `RedMorphSearchUITests.swift` für die entfernte eigene iPhone-Suchleiste wurde gelöscht. **Kein automatisierter UI-Test für den wiederhergestellten nativen Scroll-/Suchweg erfolgreich ausgeführt**; neue Geräte-/Simulatortests aus `docs/TESTPLAN.md` erforderlich.
- Neu eingeführte UI-Schlüssel für Suche, Werkzeuge und Automix liegen mit deutscher Übersetzung in `Localizable.xcstrings`; die JSON-Datei wurde nach dem Bearbeiten erfolgreich geparst. Übersetzungen für andere Sprachen sind nicht vollständig.

**Freigabegrenze:** Ohne Xcode-Build, echten Simulator und hörbaren Gerätetest ist RED Morph eine implementierte, statisch geprüfte UI-Änderung, **kein freigegebenes App-Release**.

## Rücknahme der getrennten iPhone-Suche (Nutzerfeedback, 06.11.2026)

Auf ausdrücklichen Wunsch wurde die separate Suchleiste im iPhone-Seiteninhalt zurückgenommen. Wiederhergestellt wurden der native `CompactPhoneSearchDrawer` mit `.searchable(... placement: .navigationBarDrawer(displayMode: .always))`, die native `role: .search` im iPhone-`TabView`, die Präsentations-/Fokus-State-Verknüpfung und der ursprüngliche Quellen-Picker-Zustand. Die iPad- und macOS-Suche sowie die unabhängig davon verbesserten Ergebnisabstände und Top-Result-Aktionen bleiben bestehen.

Der nur für das entfernte iPhone-Suchfeld entwickelte XCUITest wurde gelöscht; die statische Quellprüfung prüft nun die **wieder integrierte native Suche**. Ältere Abschnitte dieses Dokuments beschreiben den zwischenzeitlichen Stand und sind durch diese Rücknahme überholt. Die tatsächliche Darstellung ist weiterhin **NICHT GETESTET**.

## Wiederhergestellte Mini-Player-Scroll-Animation (Nutzerfeedback, 06.11.2026)

Die zwischenzeitlich eingeführte `content.tabBarMinimizeBehavior(.never)`-Einstellung unterband die gewohnte Animation beim Herunterscrollen auf dem iPhone: Die Tab-Leiste blieb offen und der Mini-Player wechselte nicht mehr in die kompakte native Bottom-Accessory-Position. Der Auslöser war die zuvor abgetrennte Suche, die inzwischen ebenfalls zurückgenommen wurde.

`PlaybackPillMount` verwendet wieder den vorhandenen `DockScrollCoordinator.shared` und `dockScroll.keepExpanded ? .never : .onScrollDown`. Damit wird beim Scrollen nach unten die **native** Tab-Bar-Mini-Player-Kopplung aktiviert und bei Scrollrichtungswechsel wieder aufgeklappt. Die neuere Keyboard-`safeAreaInset`-Absicherung und die Reduce-Motion-Umgebung bleiben erhalten. Keine zusätzliche Custom-Tab-Leiste, kein Eingriff in Streaming oder Player-Engine.

Die statische Quellprüfung kontrolliert diese Anbindung nun. Verifikation auf echter iPhone-Hardware, insbesondere schnelle Scrollumkehr, Such-Tastatur und Zoom zum Vollplayer: **NICHT GETESTET**. Siehe `docs/TESTPLAN.md`.

## Offizielle Apple-Skills als optionale Entwicklungsunterstützung

Das Projekt unterstützt ab diesem Branch einen **lokalen Vollimport** aller von Xcode 27+ exportierten Apple-Agent-Skills ([Anleitung](APPLE_XCODE_SKILLS.md)). SwiftUI Specialist, SwiftUI-Neuerungen, adaptive UIKit-/App-Größen, Gerätetests, Testmodernisierung und Sicherheitsprüfungen können ergänzend helfen. Die Inhalte wurden hier **nicht aus Xcode exportiert oder installiert**. Sie ersetzen keine BBT-Bit-Vorgabe: E-014 native Suche und E-015 gemeinsamer Mini-Player/Tab-Bar-Scroll-Morph aus dem Nutzer-Referenzvideo haben Vorrang. UI-/Audiotests bleiben **NICHT GETESTET**.

## Originale Apple Dynamic Island statt eigener Musik-Live-Activity (06.11.2026)

**Verbindliche RED-Morph-Vorgabe:** Die obere Hardware-Dynamic-Island wird durch Apples **native Now-Playing-Medienoberfläche** betrieben, nicht durch ein über den oberen Bildschirmrand gezeichnetes SwiftUI-Overlay oder eine parallele Music-Live-Activity. BBT-Bit unterstützt den Systemweg über `MediaPlayer` unter iOS 18–26 und über `NowPlaying.MediaSession` unter iOS 27+ (wenn das Framework im SDK verfügbar ist). Damit bleiben Sperrbildschirm, Kontrollzentrum, Systemtransport und Island dieselbe Wiedergabesitzung. Bei fremder Audio-App oder aktivem `mixWithOtherAudio` entscheidet iOS über die Systempriorität; die App erzwingt keine fremde Wiedergabesteuerung.

**Direkte Verbesserung:** `QueueEntry.albumName` wird nun an `NowPlayingController.prepareForPlayback`/`update` übertragen, über `MPMediaItemPropertyAlbumTitle` beziehungsweise `MusicContent(albumName:)` veröffentlicht und bei Songwechseln aktualisiert. Bestehende alte ActivityKit-Karten werden weiterhin lediglich bereinigt, nicht erneut erzeugt. Die **Logo Glass Bloom** bleibt ein getrenntes, zeitlich begrenztes App-internes RED-Morph-Element und **nicht** die Hardware-Island. Die native Mini-Player-/Tab-Bar-Scrollanimation unten bleibt bestehen.

[Technische Implementierung, Systemgrenzen und iPhone-Prüfmatrix](native-dynamic-island-red-morph.md). Statischer Test `python3 scripts/check-native-island-source.py` wird im PR-Workflow vorbereitet. **Dynamic Island auf echtem iPhone, SwiftUI-/NowPlaying-SDK-Kompilierung und hörbare Ausgabe: NICHT GETESTET.**

## Apple-Original-APIs systematisch übernommen (06.11.2026)

Der [Apple-Quellvergleich](apple-native-ui-adoption.md) dokumentiert alle für BBT-Bit relevanten, von Apple veröffentlichten Muster: integrierte Search-Tab-Rolle, native Tab-Bar-Minimierung, Bottom-Accessory-Placement, Zoom-Transition, `ViewThatFits`, Automix-Sheet, Reduce Motion und native Now-Playing-Systemanzeige. **Der Großteil war bereits im Original oder in unserem Feature-Branch implementiert** und bleibt unverändert.

**Neu im Quellcode:** In `RootView.PlaybackPillMount` wird **nur mit einem Xcode-26.2+-SDK** (`#if compiler(>=6.2.3)`) ab iOS 26.1 der native Modifier `tabViewBottomAccessory(isEnabled: !keyboardUp)` verwendet. Das bisherige Codemagic-Xcode-26.0-SDK kann den neuen Modifizierer nicht zuverlässig auflösen; deshalb bleibt der ältere Pfad erhalten. Das vorhandene Keyboard-`safeAreaInset` zeigt das kompakte Pill, während der native Accessory ausgeschaltet ist; ab Tastaturende wird er wieder eingeschaltet. iOS 26.0 sowie Builds mit Xcode 26.0/26.1 behalten den bisherigen Accessory-Aufruf als Fallback. Die `.onScrollDown`-Kopplung und die Zoom-Quelle werden **nicht verändert**.

Die neuen Quellinvarianten sind ergänzt. Ein echter Beleg gegen doppelte Pill-Darstellung, unterbrechungsfreien Scroll-Morph und für die Kompatibilität mit iOS 26.0/26.1 ist **NICHT GETESTET**.

## Grenzen und nächste Schritte

- Suche-/Tastaturverhalten im Simulator messen und Safe-Area-Inset gegebenenfalls an die reale iOS-26/27-Keyboard-Animation anpassen.
- Player-Hierarchie auf kompakten iPhones und großen Schriftgrößen überprüfen.
- Accessibility und deutsche String-Catalog-Einträge für alle tatsächlich neuen UI-Texte validieren.
- CI-Fehler anhand verfügbarer Job-Protokolle oder lokalem Xcode-Run eingrenzen.
- RED-Morph-Optical-Glass-Motion erst nach stabilen Layout- und Funktionsnachweisen weiter ausbauen.

Keine Änderung an `main`, kein Merge und keine Änderung an Kotlin, Rust, Decoder oder Nutzerdaten.
