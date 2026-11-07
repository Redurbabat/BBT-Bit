# Testplan

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
