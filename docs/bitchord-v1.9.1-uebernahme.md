# BitChord v1.9.1 → BBT-Bit: Übernahme und Konfliktentscheidungen

Stand: 2026-11-07. Ausgangsbasis für BBT-Bit: `main` bei `c2cf0a961f6a5d8a6a21308745d9dd187e11bbc7`.
Arbeitsbranch: `feature/bitchord-v1-9-1-port-20261106`. **Keine Änderung oder Merge nach `main` ohne ausdrückliche Freigabe.**

## Umfang und Quellen

- Original: [kushagrasinghx/BitChord](https://github.com/kushagrasinghx/BitChord/compare/v1.9...v1.9.1) – 17 Commits, 94 geänderte Dateien. `v1.9.1...main`: ein Merge-Commit, keine zusätzlichen Dateiänderungen.
- Ziel: BBT-Bit mit SwiftUI, Kotlin Multiplatform und Rust-Audio-Engine; RED Morph [eigenes Repository](https://github.com/Redurbabat/RED-Morph) und [eigener BBT-Bit-Branch](https://github.com/Redurbabat/BBT-Bit/tree/feature/red-morph-player-search-navigation) sind separate Referenzen.
- „Alles übernehmen“ bedeutet funktionale Parität der **Änderungen** – nicht blindes Kopieren von Android-/Compose-/TV-Code. Daten, Wiedergabe, native Navigation und Plattformgrenzen bleiben erhalten.
- Bei bereits vorhandener Funktion **zuerst Nutzerentscheidung** zur Variante einholen. Kein Ersatz der bestehenden Implementierung durch eine zweite parallele Implementierung.

## Übernahmematrix

| Ursprung | Ziel / Status | Offene Prüfung |
| --- | --- | --- |
| Home: `hideRecents` | **IMPLEMENTIERT (Code, ohne Build)**: persistierter Schalter in BBT-Bit, Hide nur für die Home-Recents-Shelf. Verlauf und Queue bleiben unangetastet. | Xcode-Compile, Laufzeit, Regressionsprüfung, deutsche Lokalisierung visuell |
| Home: `hideHomeVideos` | **IMPLEMENTIERT (Code, nicht gebaut)** | Entscheidung A: Home zeigt abspielbare Musikvideos standardmäßig mit 16:9-Vorschauen. Persistenter Ausblenden-Schalter; Video-Kennzeichnung von Kotlin-Parser bis Swift-Queue. Explore/Bibliothek behalten ihre Filter. |
| Home: `hideTopPicks` | AUSSTEHEND | Im aktuellen Home ist keine eigene Top-Picks-Leiste nachgewiesen; keine funktionslose Einstellung hinzufügen |
| Home: `hideHomeMoods` | AUSSTEHEND | Aktuell Mood/Genre in Explore vorhanden; Home-Shelf-Existenz prüfen |
| `squareVideoThumbnails` | AUSSTEHEND | Video-Identifikation und Artwork-Sizing in SwiftUI sauber definieren |
| Prefer Music Only / Video→Audio | **FREIGEGEBEN, TEILWEISE PORTIERT** | Nutzerentscheidung: Originalverhalten. Der native Resolver wartet jetzt maximal 15 Sekunden, startet den Original-YouTube-Fallback nur nach Miss/Timeout/Identitätsfehler und scheitert nicht mehr an unnötiger Videoauflösung bei verifizierter Audioquelle. Die echte Audio-Song-ID einschließlich Queue-/Now-Playing-Metadaten und Konvertierung des nächsten Songs sind **noch nicht portiert**. |
| Autoplay / Empfehlungen / Recents | **ENTSCHIEDEN B / CODE TEILPORTIERT** | v1.9.1-Verhalten für 10er-Tail, Audio-/Video-Radios, gemeinsame Party-Einstellung, Lieferantenwahl, Aufnahme-Deduplikation, Retry/Watchdog und Server-Queue portiert. Nicht vollständig abgenommen: Modul-Track-Seed und Echtgerät/CI fehlen. |
| Crossfade, Automix-Vorschau | **ENTSCHIEDEN B – RUST-TEILPORTIERUNG** | Original-BitChord v1.9.1 als Ziel: bestehender Rust-Parallelmixer mit Equal-Power, Beatmatching und Filterkurven bleibt einzige Audio-Engine. Original-Headroom-Trim `1/√(gainIn+gainOut)` plus sampleweise geglätteter gemeinsamer Bus-Pegel und 2 neue Rust-Regressionen ergänzt; ursprünglicher `CrossfadeController`-Diff ist überwiegend vorauseilende Mix-Preview mit Waveform-Retry. Noch offen: tatsächlicher Mid-Fade-Metadaten-Handoff, native Mix-Popup-Vorschau mit Wellenformen, Tests/Build/Abnahme. |
| SourceResolver, Song-Matching, StreamLengthProbe | AUSSTEHEND – priorisiert | Gemeinsamer Kotlin-Resolver, Streamdauer, Titel/Künstler/Album-Matching und realistische Tests; `NO_PLAYABLE_STREAM` getrennt nachweisen |
| AddonAuth / Addon-Qualitätswahl | AUSSTEHEND – Sicherheitsreview | Keine unverschlüsselten Tokens, keine Bypass-Implementierung; iOS Keychain und Add-on-Protokoll prüfen |
| Bit-perfect Pause/Resume | **ENTSCHIEDEN B – MACOS-RUST-TEILPORTIERT** | Originalregel nach 30 s Pause: exklusiver DAC wird auf macOS via CoreAudio-Hog-Mode freigegeben; cpal-Stream/PCM-Ring bleiben für exakten Frame-Fortschritt erhalten. Wiederaufnahme prüft AudioDeviceID + physisches Integerformat und reacquiriert Exklusivität; bei geänderter Route sichere Neuinitialisierung, kein falscher Wiedergabeerfolg. iOS lässt diesen exklusiven Integerpfad nicht zu und bleibt beim AVAudioSession/RemoteIO-Float-Ausgang. Rust-Tests hinzugefügt, Build/Hardware noch NICHT GETESTET. |
| Player-Themes, Player-Chrome, Lyrics, Cover | **ÜBERSCHNEIDUNG mit RED Morph** | Bestehende native Navigation, Material-/Animationstoken und Mini-/Vollplayer-Übergänge schützen; Freigabe der Designvariante |
| Vollflächige Album-/Playlist-Detailcover | AUSSTEHEND | Vorhandenes Full-Screen-Cover für Player ist nicht dieselbe Einstellung |
| Glass Performance / Rendering | **TEILWEISE DOPPELT** | `reduce_dynamic_blur` und PerformanceTuner bereits vorhanden; geeignete Verbesserungen ohne duplizierten Modus |
| Sprachressourcen / App-Symbole | AUSSTEHEND | Nur relevante SwiftUI-Strings und rechtlich nutzbare Assets; Deutsch als Standardsprache |
| Diwali-Festtagsansicht | AUSSTEHEND / PRODUKTENTSCHEIDUNG | Saisonale Android-Spezialansicht nicht ungefragt als dauerhafte iOS-Startansicht aktivieren |
| Android-TV-Gradle-/Build-Fixes | NICHT DIREKT ANWENDBAR | Kein Android-TV-Ziel in der aktuellen Apple-App |
| Upstream-Tests | AUSSTEHEND | Testideen portieren: Add-ons, Song-Matching, Streamlänge, Home-Filter, Pause/Fortsetzen |

## Implementiert in diesem Branch

- `shared/src/commonMain/kotlin/com/music/bitchord/data/settings/AppSettings.kt`: `hideRecents` StateFlow und Setter auf der bestehenden `PlatformSettings`-Persistenz.
- `AppleApp/Sources/UI/Settings/SettingsView.swift` und `SettingsView+Appearance.swift`: Schalter für „Hide Recently Played“.
- `AppleApp/Sources/UI/Library/HomeView.swift`: Filtern der angezeigten Recents-Shelf; Skeleton ebenfalls ausgeblendet. Server-/lokaler Verlauf und Queue bleiben unverändert.
- `AppleApp/Resources/Localization/Localizable.xcstrings`: deutsche Übersetzung der neuen Beschriftung und Beschreibung.

## Freigabe und Portierungsschritt 2: Prefer Music Only

Entscheidung des Maintainers vom 06.11.2026: **Das Verhalten von Original-BitChord v1.9.1 übernehmen und nativ an BBT-Bit anpassen.**

Bereits umgesetzt:

- `PlaybackController+SourceResolution.swift`: bevorzugten Audiokandidaten prüfen, ohne gleichzeitig auf den ursprünglichen YouTube-Stream zu warten; 15-Sekunden-Grenze entsprechend `MusicOnlyPlayback.ANSWER_TIMEOUT_MS`; keine Videoauflösung bei erfolgreich verifizierter Ersatzquelle.
- Bei fehlendem, verspätetem, nicht verifiziertem oder nicht gepuffertem Audiokandidaten wird der Originalstream als Audio-Rückfall versucht. Bei Abbruch entfällt der Rückfall.
- `AppSettings.kt`: irreführende Aussage entfernt, dass das Video immer zuerst startet.
- `scripts/source-priority-verify/check.swift`: drei zusätzliche Race-Fälle (Audio gewinnt ohne Fallback; Miss; Timeout).
- Die native Quellauflösung deaktiviert `Prefer Music Only` bei `PartyStore.shared.inParty`, analog zur upstream-Regel. Ein Parteibeitritt während des Lookups verhindert das Anwenden einer privaten Musikversion.

**Nicht als vollständige Originalparität ausgeben:** Upstream ersetzt die Video-Queue-Zeile mit der eigenen YouTube-Music-Audio-Song-ID (Titel, Artwork, Quelle), behält den Queue-Platz bei und bereitet auch den nächsten Titel um. Der derzeitige BBT-Bit-Resolver bevorzugt einen verifizierten Audio-Stream, aktualisiert aber die Video-Queue-Zeile nicht auf diese Audio-Song-ID. Dafür sind ein separater, getesteter Catalogue-Audio-Version-Resolver sowie atomare Queue-/Handoff-Anpassungen nötig. Keine spekulative Übernahme ohne Nachweis auf echtem Playback-Pfad.

## Portierungsschritt 3: Home-Musikvideos (Nutzerentscheidung A)

- Original-BitChord v1.9.1 zeigt Musikvideos im Home-Feed, `hide_home_videos` ist standardmäßig `false`. Der Maintainer hat Variante A bestätigt.
- `InnertubeParser.parseHome(..., includeVideos = true)` gilt nur für Home (auch Supplements und Continuations). Explore und Bibliothek nutzen weiterhin die bestehende Video-Filterung.
- `ShelfItem.isVideo` (Kotlin) wird als JSON transportiert und in `ShelfCard.isVideo` (Swift) gelesen. Home-Karten, Recents und Kontextmenüs übergeben die Kennzeichnung an `QueueEntry.youtube(..., isVideo:)`; andere Aufrufstellen bleiben durch einen Defaultparameter kompatibel.
- In `HomeView` filtert `hide_home_videos` nur sichtbare Karten, anschließend leere Shelves. Originalfeed, Hörverlauf und Queue-Daten werden nicht gelöscht.
- SwiftUI verwendet für abspielbare Videokarten standardmäßig Vorschaubilder im Format 16:9. Die gesonderte BitChord-Option `square_video_thumbnails` ist noch offen und wird nicht ohne weiteren Abgleich hinzugefügt.
- Neue Einstellung und deutsche Übersetzungen unter „Darstellung“, KMP-StateFlow sowie Backup-Export und -Import ergänzt. Der bereits vorhandene Schlüssel `hide_recents` wurde ebenfalls dem Backup hinzugefügt.
- Sechs Kotlin-Regressionstests wurden hinzugefügt, sind jedoch **NICHT AUSGEFÜHRT**. Der Test prüft inklusive Fortsetzung, reiner Video-Shelf, gemischter Shelf, Explore-Standardverhalten, nicht abspielbarer Compilation und JSON-Roundtrip.

## Portierungsschritt 4: AutoPlay und Musikempfehlungen – Nutzerentscheidung B

Am 07.11.2026 wurde **B: Verhalten von Original-BitChord v1.9.1 übernehmen** gewählt. Audioausgabe bleibt nativ auf dem vorhandenen Rust-Pfad; keine zweite Queue-Engine und keine Änderungen auf `main`.

**Implementierter Code (ohne erfolgreichen App-Build):**

- `PlaybackQueuePolicy.autoplayTarget = 10`. Der Player ergänzt den Tail nach Titelwechsel und nach dem Entfernen automatischer Titel; beim Ausschalten entfallen noch nicht gehörte AutoPlay-Einträge. Die ursprüngliche Radio-Reihenfolge ersetzt die frühere Taste-Sortierung beim Append, nicht die separat zuschaltbare Automix-Planung.
- `AutoPlayBridge` und `InnertubeParser.parseWatchQueue` transportieren offizielle Song-/Video-Paarungen. Der Queue-Builder nutzt für Video-Radios bei mindestens drei Videos deren Video-Versionen; sonst eine gemischte Antwort. Katalogsongs werden für Audio-Radio bevorzugt. Titel/Künstler-Deduplikation und Seed-Künstlergrenze bleiben aktiv.
- `QueueBuilderBridge` speichert gespielte und **tatsächlich in Queue übernommene** empfohlene Aufnahmen nur innerhalb der aktiven Sitzung, falls `dont_repeat_suggestions` aktiviert ist. Audio-/Video-Doppelungen werden auf Aufnahmeebene erkannt. Ein gescheiterter Party-Append darf nicht als erfolgreich vorgeschlagen gelten.
- `PartyAutoplayRules.kt` berechnet Party-AutoPlay und Lieferantenwahl wie im Original: gemeinsamer Server-Schalter; verbundener Host, andernfalls kleinstes verbundenes Mitglied; bei Host-only **keine** Übergabe an andere. Swift-UI liest den effektiven statt des lokalen Schalters; nur berechtigte Mitglieder dürfen ihn umstellen.
- Die Party-Queue wird vom gewählten Gerät über `PartyCoordinator.queueAdd` aktualisiert. Ein schwebender Batch wird bis zum Echo (max. sechs Sekunden) vor Duplikatversuchen geschützt; keine direkte lokale Party-Queue-Manipulation.
- Leere Radio-Antworten erhalten einen einmaligen kurzen Retry und danach einen auf das Queue-Ende beschränkten 15-Sekunden-Watchdog, mit Rückgriff auf vorherige Queue-Titel. Im pausierten Zustand ruht der Watchdog.
- Kotlin-Tests für Party-Lieferantenwahl, 3-Video-Schwelle, Session-Verlauf und Audio-/Video-Paarung sowie zusätzliche Swift-Queue-Policy-Checks wurden **hinzugefügt, nicht ausgeführt**.

**Noch offen für Originalparität und Abnahme:** Ein Modul-Track ohne YouTube-ID muss wie upstream durch geprüfte Song-Suche auf einen YouTube-Seed aufgelöst werden; realer Party-Server-Echo-/Rejoin-Test, Stream-/Decoder-/Echtgerät-Audio, vollständige Swift-/Kotlin-Kompilierung und fehlgeschlagene CI-Jobs. Dieser Code ist **kein nachgewiesener funktionierender Player**. Die Tests sind erst als bestanden zu bezeichnen, wenn sie tatsächlich ausgeführt wurden.

## Portierungsschritt 5: Automix / Crossfade – Nutzerentscheidung B

**Freigabe 07.11.2026:** Der Ablauf von BitChord v1.9.1 soll in BBT-Bit mit SwiftUI und der **einzigen** vorhandenen Rust-Audio-Engine umgesetzt werden. `main`, RED Morph und die Branches anderer Agenten bleiben unangetastet.

### Code im Feature-Branch (nicht gebaut)

- Der Mixer nutzt bereits **zwei simultane Rust-Voices** mit getrennten Decodern, `sin/cos`-Equal-Power-Fades, geplanten Cue-Punkten, DSP-Filtern, Tempoanpassung und True-Peak-Protector. Kein Android-ExoPlayer-Code wurde in Swift/Rust kopiert.
- Neu: BitChords **Blend-Headroom** `1 / sqrt(incomingGain + outgoingGain)` wird auf den gemeinsam gemischten Stereo-Bus **vor** EQ und True-Peak-Protector angewendet, nur während eines echten Zwei-Titel-Übergangs. Source-Swaps derselben Aufnahme, bei denen lineare Gewinne zusammen 1 ergeben, werden nicht unnötig gedämpft; DJ-Notches werden nicht hochverstärkt.
- Die Gain-Änderung interpoliert von Audioblock zu Audioblock **pro Stereo-Frame**, ohne zusätzliche Decodierung, Netzwerk-/Dateizugriff oder Speicherallokation im Renderpfad. `MixerState.mix_headroom` speichert den letzten Pegel. Alle bestehenden Mixer-Test-Fixtures wurden um den neuen Zustand ergänzt.
- Zwei neue Rust-Regressionen in `native-core/src/mixer/tests/blends.rs` prüfen den Originalwert bei halbem Crossfade (ca. −1,5 dB Headroom), Source-Swap-Bypass, ausbleibende Verstärkung von Dips sowie gleitende Puffergrenzen.
- Der Original-Diff von v1.9 auf v1.9.1 in `CrossfadeController.kt` betrifft vor allem **Vorschau des nächsten Mixes**, getrennt nachladbare Wellenformen, Loading-Zustände und Retry-Abstand. BBT-Bits `AutomixWeave` zeigt bereits eine native Vorschau des analysierten Übergangs; eine vollständige Original-Waveform-Preview ist **nicht portiert**.

### Nicht gleichwertig / offene Arbeiten

- BBT-Bits Rust-Mixer meldet seinen Track-/Metadaten-Handoff derzeit **am Fade-Start**, das Original wechselt die MediaSession **im Übergang** (`HANDOFF_AT`). Die Änderung betrifft Queue-Index, Zeitfortschritt, Pause/Seek/Skip und Swift-Callbacks und wurde **nicht ohne vorherige Regressionstests** risikoreich umgebaut.
- Original-Mix-Popup mit prognostizierten Fadern, separaten Wellenform-Ladevorgängen und Backoff bei fehlerhafter Waveform fehlt in der nativen SwiftUI-Ansicht noch.
- Native Kompilierung, die Rust-Tests, Apple-Build, iPhone-Simulator, hörbares Crossfade-Audio, Headroom unter echten laut gemasterten Songs, Party-/Repeat-/Seek/Skip und signierte IPA sind **NICHT GETESTET**. Ohne diese Nachweise **kein Merge**.

## Portierungsschritt 6: Bit-perfect Pause/Fortsetzen – Nutzerentscheidung B

**Freigabe 07.11.2026:** Das Originalverhalten aus BitChord v1.9.1 möglichst vollständig in der bestehenden Rust-/CoreAudio-Implementierung abbilden, ohne Android-USB-/AAudio-Treiber oder zweite Audioausgabe.

### Original v1.9.1

`BitPerfectAudioSink.kt` gibt direkte/exklusive Ausgaben nach `IDLE_RELEASE_MS = 30_000` frei. Der noch nicht vom Gerät abgespielte Teil wird durch `RecentBytes` und einen erneuten Transportstart erhalten. Stream-Frames und Played-Frames bleiben auf derselben Timeline; ein inkompatibler DAC oder geändertes Wire-Format führt zu einem expliziten Wiederanlauf-Fehler. Android-Mixer-Ausgabe wird *nicht* im Idle getrennt.

### Native Umsetzung im BBT-Bit-Branch

- **macOS (Rust + CoreAudio):** Ausschließlich ein tatsächlich aktiver exklusiver Integer-PCM-Ausgang (16/24 Bit) wird nach 30 Sekunden Pause/Stop freigegeben. `cpal::Stream.pause()` und `release_output_exclusive()` geben die Gerätebelegung ab, behalten jedoch den bisherigen Output-Callback samt `rtrb`-Consumer und nicht gehörten PCM-Frames. Kein künstliches `RecentBytes`-Duplikat und kein Decoder-Neustart beim erfolgreichen Resume.
- Beim Fortsetzen wird der verzögerte Idle-Check mittels Generation ungültig gemacht. Vor `stream.play()` müssen **identische CoreAudio-Geräte-ID**, exakter Integer-PCM-Takt/Kanalzahl/Wortbreite und zurückgewonnener exklusiver Zugriff gelten. Bei Ausfall bleibt die Wiedergabe **pausiert** und eine neue Routeninitialisierung wird angefordert; bei nicht mehr verfügbarer Exklusivität wird auf gewöhnliches PCM zurückgefallen, ohne Bit-perfect-Erfolg zu behaupten.
- Ein gleichzeitiger Route-Rebuild ist durch denselben `rebuild_lock` serialisiert. Ein während des Idle-Rebuilds neu angelegter exklusiver Ausgabestream bleibt ebenfalls pausiert; die interne `SetBitPerfect`-Entscheidung verwendet seine geplante Integer-Wortbreite, obwohl am freigegebenen DAC noch keine Ausgabe aktiv ist.
- **iOS/iPadOS:** BBT-Bits bestehender RemoteIO-/AVAudioSession-Floatpfad bleibt unverändert. CoreAudio erlaubt auf dieser Plattform keinen gleichwertigen appgesteuerten USB-Hog-Mode-Integertransport; „bit-perfect aktiv“ wird dort nicht vorgetäuscht. Die allgemeine iOS-Pause-/Routenwiederherstellung bleibt separat zu prüfen.
- Neue Rust-Regressionen: `only_paused_exclusive_integer_pcm_may_release_its_device` und `paused_bitperfect_callback_keeps_exact_unplayed_stereo_frames_in_its_ring`. Kein Hardware-Simulator darf einen realen USB-DAC-Nachweis ersetzen.

**Noch nicht nachgewiesen:** Kompilierung auf macOS, tatsächliche Hardwarefreigabe nach 30 s, Stream-Reacquire auf physischem USB-DAC, Quell-/Sampleratewechsel, Seek während Suspend, Gerätewechsel, Samplegenauigkeit durch CoreAudio-Hardwarepuffer, CoreAudio-Fehlerbehandlung, iPhone-Routen und wirklich hörbares Audio. Alle diese Prüfungen **NICHT GETESTET**. Verändert eine andere App den DAC während der Pause, kann der alte PCM-Ring nicht formatblind übernommen werden; neuer Ausgabe- und Decoderpfad muss geprüft werden. Kein Merge ohne Abnahme.

## Tests / Nachweise

- Original-Diff: GitHub-API-Vergleich erfolgreich (17 Commits, 94 Dateien).
- BBT-Bit-Branch-Diff: GitHub-Vergleich bestätigt ausschließlich die genannten Dateien.
- JSON-Syntax der geänderten String-Catalog-Datei: geprüft.
- Isolierter Swift-Actor-Test: **BESTANDEN** (4 Race-Szenarien mit einer manuell nachgebildeten Kopie von `PlaybackSourceRace` unter Linux). Dies prüft das Ablaufmodell, **nicht** die tatsächliche geänderte Repository-Datei, die App oder eine Apple-Zielplattform.
- Der im Repository ergänzte `scripts/source-priority-verify/check.swift` wurde **NICHT AUSGEFÜHRT** (macOS-/Xcode-Testumgebung nicht verfügbar).
- Swift-Syntaxprüfung der geänderten App-Dateien: **NICHT GETESTET**.
- Kotlin-Kompilierung: **NICHT GETESTET**.
- Apple-Xcode-Build: **NICHT GETESTET**.
- Simulator- und echter iPhone-/iPad-/Mac-Test: **NICHT GETESTET**.
- Hörbare Wiedergabe, Queue, Crossfade, Add-on-Integration: **NICHT GETESTET**.
- Signierte IPA: **NICHT GETESTET**.

### Automatische GitHub-Prüfungen nach Draft-PR #50

- Workflow „BBT-Bit iPhone Simulator UI Tests (GitHub)“: **FEHLGESCHLAGEN** (Job „Build BBT-Bit and tap 15 design previews on iPhone Simulator“).
- Workflow „BBT-Bit PR regression checks“: **FEHLGESCHLAGEN** (Jobs „repository-checks“ und „network-regressions“).
- Die GitHub-Job-Logs waren nicht abrufbar (404 / `BlobNotFound`); Job-Step-Zusammenfassungen wurden leer zurückgegeben. **Ursache daher noch nicht nachgewiesen**. Es wäre falsch, diese Fehlschläge dem neuen Home-Schalter zuzuschreiben, ebenso falsch wäre ein Bestehen zu behaupten.
- Auch die CI liefert bislang **keinen bestätigten erfolgreichen Simulator- oder Regressionstest** für diesen Branch.

## Entscheidungspunkte vor Eingriffen in bereits vorhandene Funktionen

1. Prefer Music Only / Musikvideo-Konvertierung: **ENTSCHIEDEN – Originalverhalten, nativ portieren**. Vollständige Queue-ID-Umstellung und Next-Track-Konvertierung offen.
2. Autoplay und Empfehlungen: **ENTSCHIEDEN – Variante B, BitChord v1.9.1 maßgebend**. Native Swift/Kotlin-Portierung auf diesem Branch, Build-/Geräteabnahme und Modultitel-Seeds offen.
3. Automix/Crossfade: **ENTSCHIEDEN – Variante B.** BitChord v1.9.1 soll maßgeblich sein, jedoch nativ in der bestehenden Rust-Audio-Engine. Headroom-Trim portiert. Mid-Fade-Metadaten-Handoff und Mix-Popup-Preview noch offen; kein zweiter Audio-Player.
4. Player-Themes / RED Morph: native RED-Morph-Oberfläche belassen und neue Optionen ergänzen oder das Originaldesign übernehmen?
5. Glass-Performance: bestehende Reduce-Blur-/Performance-Modi ergänzen oder Originalschalter separat anbieten?

**Bei verbleibenden Doppelungen keine parallelen Playback-, Player- oder Automix-Pfade ohne Entscheidung implementieren.**
