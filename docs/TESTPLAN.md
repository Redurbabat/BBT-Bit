# Testplan

Die [zwölf kreativen Interaktionen](RED_BIT_KREATIVE_INTERAKTIONEN.md) ergänzen die bestehende Matrix. Für Sternroute, echte Lichtmarker, Karten-Grenzen und den Zehn-Sekunden-Schlusszoom: `swiftc AppleApp/Sources/UI/NowPlaying/ArcPlaybackGeometry.swift AppleApp/Sources/UI/NowPlaying/ConstellationGeometry.swift AppleApp/Sources/UI/LiquidMotion/MusicMotionGeometry.swift scripts/test-video-reference-geometry.swift -o /tmp/red-bit-geometry && /tmp/red-bit-geometry`. Die native UI-Regression `testCreativeCollectionsAndTimedConstellationFinale` prüft Verlauf, automatischen Kartenwechsel, 0/50/100 Prozent und Zurückspulen mit offengelegten Prüfdaten. Rust prüft `beat_snapshot_is_read_only_finite_and_rejects_changed_audio`. Echte Rhythmusqualität, VoiceOver und hörbare Musik benötigen weiterhin Geräteabnahme.

Die [RED-Bit-Integration vom 8. November](RED_BIT_INTEGRATION.md) ergänzt konkrete Prüfungen für langsame Scrollbewegung, Dock-Zustand über mehrere Berührungen, Logo-Ursprung und Tastatur-Pill. Swift-Verhaltenstest: `swiftc AppleApp/Sources/UI/LiquidMotion/DockDirectionTracker.swift scripts/test-dock-direction-tracker.swift -o /tmp/red-bit-scroll-test && /tmp/red-bit-scroll-test`. Dieser reine Foundation-Test ersetzt weder SwiftUI-Typecheck noch Geräteanimation oder Audio.

## Prüfmatrix

| Bereich | Befehl oder Nachweis | Aussage |
| --- | --- | --- |
| Repo | `python -m pip install PyYAML==6.0.3`, dann `python scripts/check-repository.py`. Mit `--base <SHA>` zusätzlich Fremdcode-Diff prüfen. `python scripts/repository-verify/check.py` führt Gegenproben aus. | Struktur und interne Links der Einstiegsdokumente und Skills, XcodeGen-Identität, Build-Grenzen und Abhängigkeitsänderungen. |
| iOS-Build-Cache | `python scripts/native-cache-verify/check.py` mit Bash, Git und SHA-256-Werkzeug. | Führt das echte Cache-Skript mit künstlichen Frameworks aus. Änderungen an Extractor-Quellen, dessen Gradle-Konfiguration und `shared` müssen neu bauen. Eine reine Swift-Änderung darf den Kotlin-Cache behalten. |
| Geheimnisse | GitHub-Job `repository-checks` scannt neu hinzugekommene Commits mit Gitleaks. | Musterbasierte Prüfung. Daten und Artefakte zusätzlich vor dem Teilen prüfen. |
| Swift | `bash scripts/check-network-errors.sh`, `bash scripts/check-signin-device.sh` sowie betroffene `scripts/check-*.sh`. | Je nach Skript isolierter Swift-Build mit Verhaltenstest oder Schnittstellentest mit Framework. `swiftc -frontend -parse` prüft Syntax. |
| Kotlin | Auf Apple Silicon mit JDK 21 `./gradlew :shared:macosArm64Test`. | `shared/src/commonTest` und Apple-Testquellen. Für Resolver-/HTTP-Änderungen Kandidatenwahl, Fallback, Timeout, Cancellation, Session und Header mit kontrollierten Antworten abdecken. |
| Rust | Mit Rust, CMake und Xcode-Toolchain `cargo test --locked --manifest-path native-core/Cargo.toml`. | Decoder, Puffer, Mixer, Pegel, EQ, Seek und Recovery gezielt prüfen. Tests mit optionalen Modell-/Audiodateien separat ausweisen. |
| Swift ↔ Kotlin/Rust | [Build-Einstiege](ARCHITEKTUR.md#abhängigkeitsgrenzen), danach Simulator-Build und passende `check-source-bridge.sh`, `check-engine.sh` oder `check-playback.sh` auf macOS. | Generierte Frameworks, Plattform-Slices, FFI-Aufrufe und Callbacks. Die Skripte können zusätzliche Build-Voraussetzungen haben. |
| Simulator | [GitHub-Simulatorlauf](github-iphone-simulator-tests.md) oder derselbe Xcode-Aufruf lokal mit einem iPhone-Simulator als Destination. XCResult und Screenshots sichern. | Xcode kompiliert App und Widget. Der bestehende UI-Test öffnet Designvorschauen. Weitere Interaktionen benötigen einen passenden Testfall. |
| UI manuell | Navigation und Rückkehr, Lade-/Fehlerzustände, Dynamic Type, VoiceOver, Reduce Motion, Reduce Transparency, Hell/Dunkel, Safe Areas und Gesten. | Gerätegröße, OS, Eingabemethode und betroffenen Nutzerweg vermerken. |
| Release | `python scripts/release-verify/check.py` und [Artefaktprüfung](RELEASE.md). | Fixture prüft gepaarte Metadaten und Checksummen. Für ein Release die echten Artefakte und das Update prüfen. |
| SideStore-Testsystem | `python scripts/ios-test-verify/check.py`, danach erfolgreicher Lauf von `ios-sidestore-test.yml` und [Installation/Update am iPhone](IPHONE_TESTSYSTEM.md). | Fixtures prüfen Konfiguration und Paketfehler. Die echte IPA wird auf Gerätearchitektur, Revision, Frameworks und Identität geprüft. Signierung, Installation, Datenbestand und Audio haben eigene Abnahmen. |

## BitChord-v1.9.1-Portierung: Home-Musikvideos

- **Kotlin-Parser:** `shared/src/commonTest/kotlin/com/music/bitchord/data/innertube/HomeVideoParserTest.kt` mit `./gradlew :shared:macosArm64Test` ausführen. Erwartet: auf Home werden Video-/Audio-Karten erhalten, im bisherigen Explore-Standard nicht; Video-Shelves bleiben bedienbar, Compilations ohne Watch-Endpunkt werden nicht als Videos angeboten, Continuation-Politik bleibt konsistent und `ShelfItem.isVideo` übersteht JSON.
- **Native UI:** Home mit einer gemischten Shelf, einer reinen Videoshelf und „Recents“ öffnen. Schalter „Musikvideos auf der Startseite ausblenden“ ein- und ausschalten: nur die Darstellung wechselt, Playlists/Songs sowie Reihenfolge und Suchresultate bleiben erhalten. Video-Cover 16:9 und Song-Cover quadratisch.
- **Queue und Wiedergabe:** Video-Karte direkt sowie über das Kontextmenü starten, `QueueEntry.isVideo` kontrollieren. Einmal mit `Prefer Music Only` aus und einmal ein prüfen. Bei aktiver Party darf die Konvertierung nicht die gemeinsame Song-ID überschreiben. Einen Folgetitel, Pause/Fortsetzen und Rückfall auf Original-Audio bei fehlender Katalogaufnahme prüfen.
- **Accessibility:** VoiceOver-Toggle und Kartenbeschriftungen, Dynamic Type, iPhone-Safe-Areas, iPad-Split-View, macOS-Klick und Tastatur; zusätzlich Reduce Motion.
- **Echter Audio-Nachweis:** Zeitfortschritt, tatsächliche hörbare Ausgabe und Stream-/Decoderdiagnose dokumentieren. UI-/Parser-Tests allein sind kein Audio-Nachweis.

Bis zur Durchführung sind alle neuen Tests und Geräteprüfungen **NICHT GETESTET**.

## BitChord-v1.9.1-Portierung: AutoPlay/Empfehlungen (B)

- **Kotlin:** `./gradlew :shared:macosArm64Test` auf Apple Silicon mit JDK 21; mindestens `QueueBuilderBridgeTest`, `PartyAutoplayRulesTest`, `AutoplayWatchQueueTest`. 10er-Tail, Video-/Audio-Paarung und Session-Deduplikation gegen echte `next`-Antworten validieren; Fixtures allein ersetzen kein Netzwerk.
- **Swift-Queue:** `bash scripts/check-queue.sh`. Original-Reihenfolge, manuelle Queue-Priorität, AutoPlay aus/an, Repeat-All, Löschung vorausliegender Titel, 2s/15s-Leerantwort-Watchdog und Trackwechsel/Cancellation überprüfen.
- **Listen Together:** Zwei bis fünf reale Clients; Host, Host-Verlust, Host-only, nichtberechtigter Teilnehmer und fehlendes Server-Echo testen. AutoPlay-Titel dürfen **nur einmal** in der Server-Queue landen; bei Echo-Ausfall kein gespielter/angebotener Erfolg vortäuschen.
- **Wiedergabe:** Song-Radio, Video-Radio (mindestens drei Videos), Video-Radio mit zu wenigen Videos, nicht spielbare Quelle und Auflösungsfallback inklusive tatsächlich hörbarer Audioausgabe und fortschreitender Zeit auf echtem iPhone.
- **Ungetestete Funktion:** Modul-Song ohne direkte YouTube-ID muss erst über `TrackMatcher` auf einen YouTube-Seed abgebildet werden; derzeit separate Abnahmeaufgabe.

**Status 07.11.2026:** Neue Tests als Quelltext hinzugefügt; **Kompilierung, Unit-Tests, iPhone-Simulator, Echtgerät und hörbares Audio NICHT GETESTET**. CI-Fehlschläge dürfen nicht als Bestehen gewertet werden.

## BitChord-v1.9.1-Portierung: Automix/Crossfade (B)

- **Rust/Mathematik:** `cargo test --locked --manifest-path native-core/Cargo.toml`. In `mixer/tests/blends.rs` die neuen Tests für originalen Headroom `1/sqrt(gainIn+gainOut)`, Block-Gain-Rampe, Swap/Notch sowie die vorhandenen Equal-Power-/Handoff-/Pegel-Tests ausführen.
- **Rust/Audio-Qualität:** `bash scripts/check-automix.sh` sowie `bash scripts/check-engine.sh`; absichtlich hochpegelige und korrelierte Audio-Files, echte Decoder-/Filter-/Sample-Rate-Wechsel, Unterbrechung und Error Recovery. Nur echte hörbare Wiedergabe belegt Klang.
- **Native UI/Metadaten:** Original wechselt die MediaSession im Blend (`HANDOFF_AT`), der aktuelle Rust-Mixer meldet das Ereignis noch ab Blend-Start. Timebar, Cover, Queue-Index, Now Playing, Lyrics, Favoriten, Scrobble und Lock Screen gegen hörbare Übergabe messen; ohne Regression kein ungetesteter Timing-Umbau.
- **Mix-Preview:** Vor dem eigentlichen Fade die identische Planung als Vorschau rendern. Wellenformen der beiden Quellen unabhängig im Hintergrund nachladen, fehlgeschlagene Decodes mindestens fünf Sekunden begrenzen, Laden/Fehler in SwiftUI nicht als erfolgreiche Analyse anzeigen. Reduce Motion/VoiceOver beachten.
- **Echtgerät:** iPhone über Lautsprecher, Kopfhörer und Bluetooth: zwei hörbare Quellen überlappen wirklich; keine Pause, kein Knacken, kein unerwünschtes Clipping; Ausgabewechsel und Sleep Timer. Original-Musikplayback hat Vorrang vor Vorschau.

**Status 07.11.2026:** Der Headroom-Diff und die Regressionen sind committed. Die neue Rust-Implementierung ist **NICHT KOMPILIERT**, Tests **NICHT AUSGEFÜHRT**, tatsächliche Audioqualität **NICHT GETESTET**.

## BitChord-v1.9.1-Portierung: Bit-perfect Pause/Resume (B)

- **Rust-Unit:** `cargo test --locked --manifest-path native-core/Cargo.toml` – neue Tests in `native-core/src/output.rs` prüfen Idle-Bedingungen (genau 30 s, nur pausierter 16-/24-Bit-Exklusivpfad) und dass eine pausierte Render-Callback-Passage `rtrb`-Frames **nicht** verbraucht.
- **macOS-Hardware:** USB-DAC mit exklusivem Integer-PCM (16 und 24 Bit) anschließen. Vor Pause Format/AudioDeviceID protokollieren; nach 29 s darf die Gerätebelegung nicht freigegeben sein, nach mindestens 30 s schon. Ring-/Playhead-Zustand sichern; beim Fortsetzen kein erneutes Intro/kein hörbarer Verlust.
- **Fehlerszenarien:** Pause + Seek, Pause + Stop, Pause + anderes USB-Gerät, gleicher Gerätename mit anderer Device-ID, CoreAudio-Formatwechsel, DAC bleibt von anderer App belegt, fehlgeschlagene Stream-`play()`-Operation. Keine unerlaubte Original-PCM-Ausgabe auf anderem Format. Der angeforderte PCM-Rebuild darf Bit-perfect nicht weiter als aktiv anzeigen.
- **iPhone/iPad:** Das System gibt nur RemoteIO/AVAudioSession-Floatstream frei; Bit-perfect darf nicht als echter direkter Integer-DAC gemeldet werden. Prüfe Pause/Fortsetzen, Route, Wiedergabezeit und hörbare Ausgabe separat, insbesondere Bluetooth/USB-C/Unterbrechung.
- **Regression:** `bash scripts/check-engine.sh` und `bash scripts/check-audio-quality.sh` auf macOS, Signierung und tatsächliche Wiedergabe. Stream- und Callback-Tests sind keine physische Audioabnahme.

**Status 07.11.2026:** Quelltext geändert und Rust-Regressionen angelegt. **Kompilierung, Unit-Tests, echter Mac-DAC, iPhone-Simulator, echtes iPhone, hörbares Audio und IPA NICHT GETESTET.**

## Automix-Modelle: Download-404-Fix für die IPA

- `python3 scripts/verify-automix-model-sources.py`: Quellprüfung der drei öffentlichen, festen Release-URLs, SHA-256 und Größen sowie der Entwickler-Fetch-Konstanten. Wird von Codemagic vor Debug/Release-IPA und in PR-CI aufgerufen.
- `python3 scripts/verify-automix-model-sources.py --online`: öffentliche GitHub-Release-Metadaten für alle drei Assets überprüfen. Die Prüfung lädt keine Modelldateien herunter.
- Auf macOS: `MODELS_LIVE=1 bash scripts/check-models.sh` für **tatsächliche** Downloads und echte Integritätsprüfung. Fixture-/Manifestprüfungen nicht mit realem Assetdownload verwechseln.
- Auf echtem iPhone mit neuem Branch-Build: Automix Models öffnen, **Beat + Downbeat**, **Accelerated Beat (Core ML)** und **Vocal + Clash** installieren. Kein HTTP 404, SHA-256 und Größen stimmen; Core ML wird kompiliert und benötigt das Basismodell. App neu starten und installierte Modelle offline verwenden.
- Die drei Modellgewichte sind **nicht als 65 MB Bundle-Daten** in der IPA: die Modelle werden beim Anwender heruntergeladen und persistiert. Tempo-/DSP-Fallback ohne Modelle prüfen; hörbare Musikausgabe separat nachweisen.

**Status: Modell-URLs und Release-Metadaten geprüft; neue IPA, Live-Download auf iPhone, Core-ML-Inferenz und Audiowiedergabe NICHT GETESTET.**
## Apple Liquid Glass: Music Island und Mini-Player

1. Auf iPhone iOS 26+ einen Titel mit stark gelb/goldenem, danach einen mit violettem Cover abspielen. Beide Male müssen Mini-Player und Music Island **neutrale systemeigene Glasflächen** zeigen; Text und Icons passen sich Hell/Dunkel automatisch an. Der Vollbildplayer darf weiterhin Cover-Farben nutzen.
2. Tab-Leiste scrollend minimieren, Inline-Pill sowie ausgeklappte Leiste vergleichen. Die native `TabViewBottomAccessory`-Hülle darf keinen zweiten Hintergrund, eine Doppelkontur oder einen separaten Schlagschatten enthalten. Tastatur offen/zu und Suche kontrollieren.
3. Die Music Island vom Logo öffnen, expandieren, einklappen und schließen. Play/Pause, Next, Previous, Lyrics, Queue, Wisch- und Schließgesten funktionieren unverändert. Die appinterne Island nicht mit der Hardware-Dynamic-Island verwechseln.
4. iPad im Split-View und macOS mit eingeengtem Fenster testen; dort eine einzelne `.glassEffect`-Kapsel prüfen. Auf älteren OS-Versionen Material-Fallback; mit Reduce Transparency beziehungsweise `reduce_dynamic_blur` kontrastreicher, opaker Hintergrund. VoiceOver, große Schrift, 44-pt-Touch-Ziele, Reduce Motion und laufende Playback-Animationen abnehmen.

**Status:** Implementiert als SwiftUI-Quellcode auf Feature-Branch. Swift-Kompilierung, Simulator-Screenshot, echtes iPhone und hörbare Wiedergabe **NICHT GETESTET**.

## BBT-Bit Testzentrale – native Live-Diagnose

Die Funktion unter **Einstellungen → BBT-Bit Testzentrale** darf beim Hören passiv mitlaufen; sie startet, pausiert, überspringt oder ersetzt keine Musik und verändert keine Queue, Kontodaten, Downloads oder Favoriten.

1. Auf echtem iPhone die aktuelle Test-IPA installieren und zwei tatsächlich spielbare Songs anstellen; die Testzentrale starten, ihre Ansicht verlassen und die App verwenden. Bis zu 30 Minuten lang sollen Messpunkte entstehen, während der App-Prozess läuft. Eine iOS-Prozesssuspendierung begrenzt Hintergrundaufnahmen.
2. Automatische Messpunkte prüfen: gültiger Queue-Index, Controller-Zeitfortschritt, Decoder-/Native-Output-Zustand, AVAudioSession, Netzwerkstatus, Buffering und nur das **Vorhandensein** eines Playback-Fehlers. Weder ausgegebene Streamnamen noch Rohlogs mit Nutzerdaten dürfen in den Livetestbericht gelangen.
3. Für **alle drei KI-Modelle** `Alle drei SHA-256-Dateien prüfen` antippen. Download-Status, erneute echte SHA-256-/Größenprüfung, Rust-Modell geladen und bei einem **neuen** echten Automix-Paar erfolgreich verwendetes ONNX/Core-ML/Open-Unmix müssen getrennt dargestellt werden. Tests mit BALANCED, PERFORMANCE und EFFICIENT; letzteres deaktiviert das Vocal-Modell und den Core-ML-Beschleuniger.
4. Die **14 Handtests** zu hörbarer Musik, Pause/Resume, Next/Previous, Shuffle/Repeat, Crossfade-Klang, Suche, Home/Bibliothek, Playlists/Favoriten, Offline-Musik, Video/Lyrics, Hintergrund/Lockscreen, Bluetooth/USB, Liquid Glass/VoiceOver und Listen Together jeweils auf `Bestanden` oder `Fehler` setzen **erst nach tatsächlicher Durchführung**. `Offen` darf niemals automatisch als grün zählen.
5. `Lokalen Testbericht speichern` und `Testbericht teilen` nach Abschluss auf dem Gerät auslösen. Prüfe, dass JSON nur technische Statuswerte, Uhrzeiten, Model-IDs und ausdrücklich markierte Ergebnisse enthält; **keine** Songtitel, Medien-IDs, Stream-URLs, lokale Pfade, Zugangsdaten oder rohe Diagnoselogs. Teilen ist nur mit ausdrücklicher Interaktion möglich.
6. Zusätzlich externe Tests: `cargo test --locked --manifest-path native-core/Cargo.toml`, Swift-/Xcode-Build, iPhone-Simulator-XCUITest, GitHub Actions/Codemagic, erfolgreich signierte IPA und **wirklich hörbare** Ausgabe auf echtem iPhone. Ein gemeldeter Decoder oder ein Zeitfortschritt beweist keinen hörbaren Ton.

**Status 2026-11-07:** Quellimplementierung auf Draft-Branch. SwiftUI-Kompilierung, Rust-Unit-Test, UI-/iPhone-Simulator-Test, echtes iPhone, hörbare Audiowiedergabe und signierte IPA **NICHT GETESTET**.

## Deutschsprachige Einstellungen – Lokalisierungsregression (2026-11-07)

**Fehlerbild:** Auf einem deutschen iPhone erscheint die Überschrift „Einstellungen“ übersetzt, aber die neun Kategorien und fast alle Unterpunkte unter „Playback“ zeigen Englisch. Ursachen: `developmentLanguage = en` ist korrekt, doch dem `Localizable.xcstrings` fehlten viele `de`-Einträge und dynamische SwiftUI-Strings wurden als normale `String`-Werte statt `LocalizedStringKey` dargestellt.

**Umgesetzt:** `SettingsView` setzt die Locale aus `AppLanguage` (standardmäßig `de`), auch bei englischer Gerätesprache. `SettingsSection` zeigt die übersetzten Titel in Hauptseite, Suchergebnissen, Navigation und macOS-Sidebar. `SettingsLine` und `SettingsSubToggle` übersetzen dynamisch über `LocalizedStringKey`, ohne Such-/Routen-IDs zu verändern. Die Einstellungs-Suche berücksichtigt auch die lokalisierten Kategorien und Zeilentitel. Der String Catalog wurde um deutsche Kategorie-, Playback-, Automix-, Beschreibungs- und weitere Einstellungswerte ergänzt, ohne fremde Sprachen oder vorhandene Übersetzungen zu überschreiben.

- `python3 scripts/verify-settings-german.py`: Erwartete deutsche Kategorien, die auf Screenshots sichtbaren Wiedergabeoptionen, SwiftUI-Locale, dynamische Labels und lokalisierte Suche prüfen. In PR-Regressionsworkflow enthalten.
- **Manueller Test auf iPhone:** `App Language = German` und alternativ `Device Language` bei Gerät Deutsch. „Playback“ muss „Wiedergabe“, „Sound & Quality“ muss „Klang & Qualität“, „Prefer Music Only“ muss „Musikversion bevorzugen“ heißen. Suche nach „Wiedergabe“ und „Musikversion“, Navigation / Detailtitel und Untertitel prüfen.
- **Sprachwechsel:** In der App `App Language = English` wählen und prüfen, dass Englisch weiterhin verfügbar ist; dann zurück zu Deutsch. Französische/spanische Bestandsübersetzungen dürfen nicht verschwinden. Dark Mode, Dynamic Type und VoiceOver kontrollieren.
- Eine bereits installierte ältere IPA enthält diese Änderungen **nicht**. Der Link zur Testzentrale wird in der nächsten IPA direkt oben unter „Wiedergabe“ und weiterhin unter „Erweiterte Optionen“ angezeigt.

**Status:** Quellcode/Katalog korrigiert. Echter Apple-SwiftUI-Build, Simulator, iPhone-IPA und vollständige UI-Lokalisierungsabnahme **NICHT GETESTET**. Einige noch nicht übersetzte weitere Untermenüs sind separat zu prüfen.

## Apple-Xcode-Agent-Skills: Offline-Prüfung

Für den lokalen Skill-Importer stehen synthetische Unit-Tests ohne Xcode oder Build-Tokens bereit:

```bash
python3 scripts/apple-skills-verify/check.py
```

Sie prüfen: vollständige Kopie nach Codex/Claude inklusive Referenzen, Dry-Run ohne Schreibzugriff, Schutz vor Überschreiben fremder Skills, explizites Update und Zurückweisung von Symlinks. **Prüfbefehl im aktuellen Chat nicht ausgeführt.** Ein Test mit tatsächlichen Apple-Skills benötigt Xcode 27+ auf einem Mac: `python3 scripts/install-apple-xcode-skills.py --from-xcode`, danach `python3 scripts/check-repository.py` und `git status --short`. Keine Apple-Skill-Dateien oder privaten Daten committen. [Installationsanleitung](APPLE_XCODE_SKILLS.md).

## Originale Apple-API: Bottom Accessory und Such-Tastatur

Nach dem [Apple-API-Abgleich](apple-native-ui-adoption.md) muss `PlaybackPillMount` die neue API **nur mit Xcode 26.2+** über `#if compiler(>=6.2.3)` verwenden; zur Laufzeit erst ab iOS 26.1. Da Codemagic aktuell **Xcode 26.0** nutzt, muss der vorhandene Fallback auch für ältere SDKs erhalten bleiben und ein kompaktes Keyboard-Pill über `safeAreaInset` anbieten. Überprüfe die Quellbedingungen mit:

```bash
python3 scripts/check-red-morph-source.py
```

**iPhone-Abnahme:** (1) Mit Song in „Jetzt hören“ scrollen: Tab-Leiste und Mini-Player gemeinsam hinein-/herausgleiten lassen. (2) Suche und Tastatur öffnen: genau **ein** Player über Tastatur, keine leere Bottom-Accessory-Leiste. (3) Tastatur schließen: native Leiste mit Player wieder sichtbar und Zoom zum Vollplayer funktioniert. (4) iOS 26.0 und 26.1+ **sowie Xcode 26.0 und Xcode 26.2+** getrennt testen; im alten SDK-Fallback insbesondere Duplikate/Überdeckung prüfen. (5) Reduce Motion, VoiceOver, Dynamic Type und tatsächlich hörbare Wiedergabe überprüfen.

**Status:** Codeänderung auf dem Branch, GitHub-Quellvergleich möglich. Der Python-Befehl ist **NICHT AUSGEFÜHRT**; Swift-Kompilierung, Simulator und iPhone **NICHT GETESTET**.

## RED Morph ohne Build-Tokens

Auf `feature/red-morph-player-search-navigation` prüft `python3 scripts/check-red-morph-source.py` den Quellaufbau ohne Apple-SDK oder CI-Build-Tokens. Dazu gehören die wiederhergestellte **native iPhone-Suche** und die native `TabView`-Minimierung mit `DockScrollCoordinator` und `.onScrollDown`. Diese Prüfung ersetzt **keine** Swift-Kompilierung und **keinen** Gerätetest.

**Regressionstest für die Mini-Player-Animation (iPhone mit iOS 26+):**

1. In „Jetzt hören“ bei laufender Musik nach **unten durch die Liste scrollen**. Die Tab-Leiste muss sich systemnativ minimieren; der Mini-Player wechselt vom separaten Bottom Accessory **oberhalb der großen Tab-Leiste** in den nativen **Inline-Modus der kompakten Tab-Leiste** (Referenzvideo vom 06.11.2026). Cover, Titel und Wiedergabeschaltfläche bleiben erreichbar. Kein zweiter, feststehender Player.
2. Innerhalb derselben Geste die Scrollrichtung nach oben umkehren. Die Tab-Leiste und der Mini-Player müssen wieder gemeinsam aufklappen. Wiederholt schnell hin- und herwechseln; keine doppelte Mini-Player-Leiste und kein Sprung über den Home-Indikator.
3. Mini-Player antippen und den Vollplayer aufziehen; danach herunterziehen. Die Zoom- bzw. Rückkehranimation darf nicht durch die Scroll-Minimierung unterbrochen werden.
4. Zur nativen Suche wechseln, Tastatur ein- und ausblenden und danach erneut in „Jetzt hören“ scrollen. Es darf kein doppelter Mini-Player oberhalb der Tastatur oder der Tab-Leiste erscheinen.
5. Dasselbe mit „Bewegung reduzieren“ und „Transparenz reduzieren“ sowie VoiceOver prüfen. Musik muss beim Scrollen tatsächlich weiterlaufen.

**Prüfstatus (06.11.2026):** Quelländerung implementiert. Swift-Compile, Simulator, iPhone-Echtgerät, 3D-Zoom und hörbare Wiedergabe: **NICHT GETESTET**. Laut Projektinhaber sind die Build-Tokens ausgeschöpft; keine zusätzlichen CI-Läufe starten.

## Apple Dynamic Island / RED Morph

**Systemoberfläche, nicht eigenes SwiftUI-Overlay.** Die Apple-Dynamic-Island nutzt dieselben Now-Playing-Metadaten und Transportbefehle wie Sperrbildschirm und Kontrollzentrum. Vor dem Xcode-Build kann das neue Standardbibliothek-Skript prüfen, dass iOS-18–26- und iOS-27-Pfade, Albumtitel, Legacy-Live-Activity-Bereinigung, alle acht Metadatenübergaben und der RED-Morph-Zoom vorhanden sind:

```bash
python3 scripts/check-native-island-source.py
```

**Regression P-015 (Album-Optional-Typ):** `QueueEntry.albumName` ist `String?`. Alle vier Signaturen in `NowPlayingController`/`ModernNowPlaying` müssen `albumName: String?` annehmen. Der MediaPlayer-Metadateneintrag darf nur einen nichtleeren String enthalten; das moderne `MusicContent` erhält einen normalisierten String. Die Quellprüfung kontrolliert diese Typen, **aber nur ein echter Xcode-Swift-Typecheck belegt Kompilierbarkeit**. Zusätzlich aus einer Playlist und dem obersten Suchergebnis jeweils einen Song abspielen, `Add to Playlist` getrennt betätigen und kontrollieren, dass das Hinzufügen keine Wiedergabe auslöst; lokale sowie YouTube-Titel ohne Albumnamen müssen funktionieren.

Der Befehl ist im CI-PR-Workflow eingetragen, wurde hier aber **NICHT AUSGEFÜHRT**. Statische Quellprüfung beweist keine Sichtbarkeit der Insel. Auf einem echten Dynamic-Island-iPhone müssen Songtitel, Interpret, Albumcover, Pause/Play, Skip, Hintergrund, Unterbrechungen und Apple-Systempriorität **mit tatsächlich hörbarer Musik** geprüft werden. Die Einstellung „Play Alongside Other Apps“ ausdrücklich in beiden Zuständen testen, **nicht** automatisch verändern. Alle Details in [Dynamic Island × RED Morph](native-dynamic-island-red-morph.md).

**Status:** Apple-SDK-Kompilierung, Simulator, Hardware-Island, signierte IPA und Audiowiedergabe: **NICHT GETESTET**; keine zusätzlichen kostenpflichtigen CI-Läufe.

## Echtes iPhone

Für den Fehler mit regionaler Gerätesprache zuerst mit `de-CH` oder `de-DE` prüfen. Die API-Sprache muss `de` werden, die Inhaltsregion muss erhalten bleiben. Auf macOS kann `VERIFY_APPLE_LANGUAGE=de-CH VIDEO_IDS=ZjBZ8MUnB0E STRICT_PLAYBACK=1 bash scripts/check-playback.sh` den nativen Resolver und einen Medienabruf prüfen. Das Skript setzt die Sprache nur im Prüfprozess. Es belegt noch keine hörbare iPhone-Wiedergabe.

1. Gerät, OS, Version, Build, Commit und Signierweg dokumentieren. Für die signierte Geräteautomation steht [run-iphone-ui-tests.sh](../scripts/run-iphone-ui-tests.sh) zur Verfügung. Einen echten Song suchen und starten. Hörbare Ausgabe und fortschreitende Zeit prüfen. Pausieren, fortsetzen, springen und einen Folgetitel aus der Queue starten.
2. Hintergrund und Sperrbildschirm prüfen. Über Lautsprecher und Bluetooth abspielen. Route bei laufender Musik wechseln und nach einer Unterbrechung erneut fortsetzen.
3. Einen reproduzierbaren Netz-/Streamfehler prüfen. Erwartete Meldung, Recovery und tatsächliche Audioausgabe getrennt erfassen. [Diagnoseablauf](playback-failure-iphone-diagnostics.md)
4. Mini- und Vollplayer, Glass Bloom, Cover Morph, Gesten und Rückkehr prüfen. Reale App-Zustände nach den [Datenregeln](DATENREGELN.md) aufnehmen. Designvorschauen und synthetische Fixtures separat benennen. [Geräte-Selbsttests](iphone-device-self-tests.md)

## Status im Bericht

| Status | Voraussetzung |
| --- | --- |
| `NICHT GETESTET` | Die Prüfung fehlt. Grund und nächster Nachweis sind benannt. |
| `SYNTAX GEPRÜFT` | Parser lief erfolgreich. |
| `BESTANDEN` | Der konkrete lokale oder CI-Prüfbefehl lief erfolgreich. |
| `SIMULATOR BESTANDEN` | Der genannte Test lief auf einem benannten Simulator und hat Belege. |
| `ECHTGERÄT BESTANDEN` | Die genannte Interaktion lief auf dem physischen Gerät mit dem dokumentierten Build. |
| `FEHLGESCHLAGEN` | Der Befehl oder die beobachtete Interaktion ist mit Fehlerbeleg erfasst. |

GitHub Actions liefert getrennte Job- bzw. Schrittresultate. Pflichtprüfungen bleiben bei Fehlern sichtbar. Ein optionaler, übersprungener oder ausgefilterter Lauf braucht einen eigenen Vermerk im Review.

| SideStore-Testsystem | `python scripts/ios-test-verify/check.py`, danach erfolgreicher Lauf von `ios-sidestore-test.yml` und [Installation/Update am iPhone](IPHONE_TESTSYSTEM.md). | Fixtures prüfen Konfiguration und Paketfehler. Die echte IPA wird auf Gerätearchitektur, Revision, Frameworks und Identität geprüft. Signierung, Installation, Datenbestand und Audio haben eigene Abnahmen. |

## Apple-Xcode-Agent-Skills: Offline-Prüfung

Für den lokalen Skill-Importer stehen synthetische Unit-Tests ohne Xcode oder Build-Tokens bereit:

```bash
python3 scripts/apple-skills-verify/check.py
```

Sie prüfen: vollständige Kopie nach Codex/Claude inklusive Referenzen, Dry-Run ohne Schreibzugriff, Schutz vor Überschreiben fremder Skills, explizites Update und Zurückweisung von Symlinks. **Prüfbefehl im aktuellen Chat nicht ausgeführt.** Ein Test mit tatsächlichen Apple-Skills benötigt Xcode 27+ auf einem Mac: `python3 scripts/install-apple-xcode-skills.py --from-xcode`, danach `python3 scripts/check-repository.py` und `git status --short`. Keine Apple-Skill-Dateien oder privaten Daten committen. [Installationsanleitung](APPLE_XCODE_SKILLS.md).



## Originale Apple-API: Bottom Accessory und Such-Tastatur

Nach dem [Apple-API-Abgleich](apple-native-ui-adoption.md) muss `PlaybackPillMount` die neue API **nur mit Xcode 26.2+** über `#if compiler(>=6.2.3)` verwenden; zur Laufzeit erst ab iOS 26.1. Da Codemagic aktuell **Xcode 26.0** nutzt, muss der vorhandene Fallback auch für ältere SDKs erhalten bleiben und ein kompaktes Keyboard-Pill über `safeAreaInset` anbieten. Überprüfe die Quellbedingungen mit:

```bash
python3 scripts/check-red-morph-source.py
```

**iPhone-Abnahme:** (1) Mit Song in „Jetzt hören“ scrollen: Tab-Leiste und Mini-Player gemeinsam hinein-/herausgleiten lassen. (2) Suche und Tastatur öffnen: genau **ein** Player über Tastatur, keine leere Bottom-Accessory-Leiste. (3) Tastatur schließen: native Leiste mit Player wieder sichtbar und Zoom zum Vollplayer funktioniert. (4) iOS 26.0 und 26.1+ **sowie Xcode 26.0 und Xcode 26.2+** getrennt testen; im alten SDK-Fallback insbesondere Duplikate/Überdeckung prüfen. (5) Reduce Motion, VoiceOver, Dynamic Type und tatsächlich hörbare Wiedergabe überprüfen.

**Status:** Codeänderung auf dem Branch, GitHub-Quellvergleich möglich. Der Python-Befehl ist **NICHT AUSGEFÜHRT**; Swift-Kompilierung, Simulator und iPhone **NICHT GETESTET**.



## RED Morph ohne Build-Tokens

Auf `feature/red-morph-player-search-navigation` prüft `python3 scripts/check-red-morph-source.py` den Quellaufbau ohne Apple-SDK oder CI-Build-Tokens. Dazu gehören die wiederhergestellte **native iPhone-Suche** und die native `TabView`-Minimierung mit `DockScrollCoordinator` und `.onScrollDown`. Diese Prüfung ersetzt **keine** Swift-Kompilierung und **keinen** Gerätetest.

**Regressionstest für die Mini-Player-Animation (iPhone mit iOS 26+):**

1. In „Jetzt hören“ bei laufender Musik nach **unten durch die Liste scrollen**. Die Tab-Leiste muss sich systemnativ minimieren; der Mini-Player wechselt vom separaten Bottom Accessory **oberhalb der großen Tab-Leiste** in den nativen **Inline-Modus der kompakten Tab-Leiste** (Referenzvideo vom 06.11.2026). Cover, Titel und Wiedergabeschaltfläche bleiben erreichbar. Kein zweiter, feststehender Player.
2. Innerhalb derselben Geste die Scrollrichtung nach oben umkehren. Die Tab-Leiste und der Mini-Player müssen wieder gemeinsam aufklappen. Wiederholt schnell hin- und herwechseln; keine doppelte Mini-Player-Leiste und kein Sprung über den Home-Indikator.
3. Mini-Player antippen und den Vollplayer aufziehen; danach herunterziehen. Die Zoom- bzw. Rückkehranimation darf nicht durch die Scroll-Minimierung unterbrochen werden.
4. Zur nativen Suche wechseln, Tastatur ein- und ausblenden und danach erneut in „Jetzt hören“ scrollen. Es darf kein doppelter Mini-Player oberhalb der Tastatur oder der Tab-Leiste erscheinen.
5. Dasselbe mit „Bewegung reduzieren“ und „Transparenz reduzieren“ sowie VoiceOver prüfen. Musik muss beim Scrollen tatsächlich weiterlaufen.

**Prüfstatus (06.11.2026):** Quelländerung implementiert. Swift-Compile, Simulator, iPhone-Echtgerät, 3D-Zoom und hörbare Wiedergabe: **NICHT GETESTET**. Laut Projektinhaber sind die Build-Tokens ausgeschöpft; keine zusätzlichen CI-Läufe starten.



## Apple Dynamic Island / RED Morph

**Systemoberfläche, nicht eigenes SwiftUI-Overlay.** Die Apple-Dynamic-Island nutzt dieselben Now-Playing-Metadaten und Transportbefehle wie Sperrbildschirm und Kontrollzentrum. Vor dem Xcode-Build kann das neue Standardbibliothek-Skript prüfen, dass iOS-18–26- und iOS-27-Pfade, Albumtitel, Legacy-Live-Activity-Bereinigung, alle acht Metadatenübergaben und der RED-Morph-Zoom vorhanden sind:

```bash
python3 scripts/check-native-island-source.py
```

**Regression P-015 (Album-Optional-Typ):** `QueueEntry.albumName` ist `String?`. Alle vier Signaturen in `NowPlayingController`/`ModernNowPlaying` müssen `albumName: String?` annehmen. Der MediaPlayer-Metadateneintrag darf nur einen nichtleeren String enthalten; das moderne `MusicContent` erhält einen normalisierten String. Die Quellprüfung kontrolliert diese Typen, **aber nur ein echter Xcode-Swift-Typecheck belegt Kompilierbarkeit**. Zusätzlich aus einer Playlist und dem obersten Suchergebnis jeweils einen Song abspielen, `Add to Playlist` getrennt betätigen und kontrollieren, dass das Hinzufügen keine Wiedergabe auslöst; lokale sowie YouTube-Titel ohne Albumnamen müssen funktionieren.

Der Befehl ist im CI-PR-Workflow eingetragen, wurde hier aber **NICHT AUSGEFÜHRT**. Statische Quellprüfung beweist keine Sichtbarkeit der Insel. Auf einem echten Dynamic-Island-iPhone müssen Songtitel, Interpret, Albumcover, Pause/Play, Skip, Hintergrund, Unterbrechungen und Apple-Systempriorität **mit tatsächlich hörbarer Musik** geprüft werden. Die Einstellung „Play Alongside Other Apps“ ausdrücklich in beiden Zuständen testen, **nicht** automatisch verändern. Alle Details in [Dynamic Island × RED Morph](native-dynamic-island-red-morph.md).

**Status:** Apple-SDK-Kompilierung, Simulator, Hardware-Island, signierte IPA und Audiowiedergabe: **NICHT GETESTET**; keine zusätzlichen kostenpflichtigen CI-Läufe.

