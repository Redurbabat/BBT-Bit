# Claude-Auftrag: YouTube-Musik spielt auf iPhone nicht (4. November 2026)

> **Arbeitsbranch:** `claude/fix-youtube-playback-20261104`  
> **Basis:** `main` zum Zeitpunkt der Branch-Erstellung.  
> **NICHT nach `main` mergen.** Keine Änderungen an Codex- oder anderen Agentenbranches.

## 1. Nachgewiesener Gerätefehler

Der Nutzer hat den echten iPhone-Screenshot aus **Einstellungen → Playback → Musik-Diagnose** und zwei Diagnoseberichte vorgelegt.

Gerät: iOS 26.6.1, BBT-Bit/BitChord **1.0.4 (Build 13)**.

Screenshot (Titel **Training Season**, Dua Lipa):
- Status **Pausiert**, Position **0.0 s**, Dauer **Unbekannt / 0**
- Quelle **YouTube / Online-Stream**, Internet **Verbunden**
- sichtbarer Fehler **Couldn't play “Training Season” — Couldn't open a stream for that track.**
- iPhone-Audiositzung in dieser pausierten Ansicht **Inaktiv**.

Detaillierte Berichte (mehrere Songs/Downloads):
- `NO_PLAYABLE_STREAM`, `client_attempts=32`, `transport=progressive-only`
- vereinzelte `NETWORK`-Kategorien, ebenfalls 32 Clientversuche
- Audiogerät `Default Device`, 48000 Hz / 2 Kanäle, `started=true`
- Engine-Codec leer, `bufferedFrames=0`, `outputPeak=0`, Status `paused`
- in älteren Protokollen `audio session activation succeeded`
- viele parallele fehlgeschlagene Downloadversuche.

**Gesichert:** Der primäre sichtbare Fehler ist vor dem Decoding: Der Resolver liefert keinen abspielbaren Stream.  
**Nicht gesichert:** Welche konkrete YouTube-Clientantwort, Schutzanforderung, Direktstream-/Segmentformat-, Netzwerk- oder Implementierungsbedingung den Ausfall auslöst. Nicht einfach Lautstärke, AudioSession oder Glass-Bloom als Ursache nennen.

**Hinweis zur Privatsphäre:** Screenshots und originale Geräteberichte wurden dem Assistenten im Chat gegeben, nicht dem GitHub-Repo. Keine persönlichen Berichte, signierten URLs, Cookies, Tokens, privaten Nutzerdaten oder Log-Rohdaten committen.

## 2. Relevante reale Codepfade

- `shared/src/commonMain/kotlin/com/music/bitchord/data/innertube/UpstreamPlaybackExtractor.kt`
  - `extractStream()` setzt **`allowHls=false`, `allowSabr=false`, `allowBoundedRange=true`**.
  - `extract()` prüft `stream.sabrBootstrap == null` und liefert derzeit progressive URL.
  - `SharedExtractionRefreshGate` begrenzt bereits wiederholte Resets.
- `shared/src/commonMain/kotlin/com/music/bitchord/data/innertube/StreamResolver.kt`
  - Resolver, Sitzungs-/Botcheck-Verhalten, URL-/Rangfolge, Validierung.
- `shared/src/commonMain/kotlin/com/music/bitchord/data/innertube/PlayerBridge.kt`
  - Übergabe von `StreamResolveException` inklusive Grund und Clientversuchszahl.
- `vendor/innertubex/src/commonMain/kotlin/com/metrolist/innertubex/extraction/`
  - tatsächliche Clientprofile, `InnerTubeExtractor`, Diagnosen, Streamfähigkeiten.
- `AppleApp/Sources/PlaybackSession/PlaybackController+SourceResolution.swift`
  - `resolveYouTube`, Stream-Downloadpfad, Retrying und erste verfügbare Audio-Bytes.
- `AppleApp/Sources/PlaybackSession/PlaybackController+LoadResults.swift`
  - `loadDidFail`, `lastError`, Bereinigung der AudioSession nach Ladefehler.
- `native-core/`
  - prüfen, welche Audioformate, Datenquellen und Decoder die echte native Engine unterstützt.
- `AppleApp/Sources/UI/DiagnosticReportsView.swift`
  - echte Geräte-Diagnoseanzeige; kein Feature-Fake.

## 3. Auszuführende Untersuchung

1. Lies `AGENTS.md`, `CLAUDE.md`, `docs/ARCHITEKTUR.md`, `docs/TESTPLAN.md`, `PROBLEME.md` und die passenden Skills.
2. Trace von `PlayerBridge.resolveRequest` über den Extractor bis zur ersten an die Engine gelieferten Audiobyte. Vergleiche erfolgreiches und scheiterndes Verhalten anhand reproduzierbarer **redaktierter** Diagnosen.
3. Ermittle, was die **32 Clientversuche** tatsächlich getan haben: welche Clients, ob Server Playability/Format/URLs lieferte, ob alle durch die progressive-only-Beschränkung ausscheiden. Keine Tokens, Cookies oder signierte URLs loggen.
4. Prüfe die aktuell unterstützten Audio-Transports und die echte Apple-Engine. **Nicht bloß `allowSabr=true` oder `allowHls=true` setzen** – nur mit vollständiger, getesteter und zulässiger Abspielstrecke. Keine DRM-/Zugriffskontrollen umgehen.
5. Behandle `NETWORK` separat von `NO_PLAYABLE_STREAM`. Abbruch und Cancellation nicht als erwartbare erfolgreiche Netzwerkantwort interpretieren.
6. Prüfe die parallelen Download-/Prefetch-Retrys: bei dauerhaftem `NO_PLAYABLE_STREAM` deduplizieren / begrenzt pausieren, damit Gerät und Netzwerk nicht mit aussichtslosen Abrufen überlastet werden. Kein Datenverlust und keine Änderungen an bereits gespeicherter Musik.
7. Implementiere nur einen **nachweisbar technisch plausiblen** Fix, der eine echte kompatible Audioquelle lädt. Wenn die aktuelle Quelle keine zulässige kompatible Audioquelle bereitstellt, korrekte Nutzerfehlermeldung und nachvollziehbares Verhalten statt simuliertem Erfolg.

## 4. Pflichtprüfungen und Akzeptanz

- Regressionstest für den beobachteten Fehlermodus: mehrfache No-Stream-Antworten und begrenzte Wiederholungen, Cancellation, Account-/Session-Wechsel.
- Kotlin-Tests, Swift/iOS-Simulator-Build, Rust-Tests nach betroffenen Dateien.
- Test mit **echten Mediendaten** aus einer rechtmäßig zugänglichen Quelle: Streamauflösung ergibt verwendbare Quelle, erste Audio-Bytes treffen im Decoder ein, `bufferedFrames > 0`, Position steigt, tatsächlicher Ton.
- Regression: lokale Dateien, Offline-Wiedergabe und bereits heruntergeladene Songs dürfen nicht kaputtgehen.
- Kein Test mit UI-Vorschaudaten als Beweis für echte Wiedergabe.
- Auf echtem iPhone: **Training Season** plus mindestens zwei weitere Titel, Audioausgabe, Bluetooth/anderes Ausgabegerät und Wiederaufnahme prüfen. Wenn nicht verfügbar: explizit `ECHTGERÄT NICHT GETESTET` melden.
- Keine falschen Erfolgsmeldungen; unbestätigte Ursachen und fehlende Prüfungen dokumentieren.
- `PROBLEME.md`, `AUFGABEN.md` und zutreffende Tests aktualisieren. Versions-/Buildnummer nur nach tatsächlicher Freigabe.

## 5. Git und Zusammenarbeit

- **Nur** `claude/fix-youtube-playback-20261104` auschecken, committen und pushen.
- Branch vor jedem Commit überprüfen. `main`, `codex/longterm-architecture-20261104` und andere Review-/Feature-Branches **nicht** beschreiben.
- Kein Merge, kein Force-Push, kein Hard Reset, kein automatisches Deployment.
- Bei Abschluss Draft-PR gegen einen separaten Review-Branch oder Prüfhinweise liefern; **kein Merge nach main**, bis der Nutzer ausdrücklich freigibt.
- In der Zusammenfassung konkrete Fehlerursache (oder offener Rest), Codeänderungen, Testbefehle, Ergebnisse und fehlende iPhone-Nachweise angeben.

**Erstes Ziel:** Herausfinden, warum alle 32 Clientversuche für direkte Streams scheitern, und eine echte, durch Tests belegte Wiedergabe ermöglichen, ohne den produktiven Branch anzufassen.

## Analyse und Prüfstand des Reparaturbranches

### Befund

- Der bisherige Zähler `client_attempts=32` ist die Länge einer auf 32 Einträge gekürzten Diagnoseliste. Darin stehen auch durch die Auswahl übersprungene Profile und wiederverwendete Antworten. Die Zahl belegt weder 32 HTTP-Anfragen noch die Antworten, die „Training Season“ auf dem iPhone erhielt.
- Der Client-Director konnte im Watch-Konfigurationspfad beim ersten allgemein abspielbaren Player-Response aufhören. Ein HLS-Manifest reichte dafür. Die Prüfung auf progressive Audioformate, erlaubten Medienhost und gegebenenfalls Länge für begrenzte Byte-Ranges kam erst danach. Der erneute Durchlauf schloss auch den allgemeinen Clientnamen aus und konnte damit ein anderes Profil desselben Clients übergehen.
- Kotlin übergibt die ausgewählte URL und Header an Swift. `StreamDownloadBridge` validiert die erste Byte-Range und stellt sie als wachsende Datei bereit. Swift übergibt den Pfad an die Rust-Engine, die den Container untersucht und eine Audiospur decodiert. Der bisherige Gerätebefund endet vor der URL-Übergabe. Die Rust-Quelle akzeptiert Dateien und progressive HTTP-Quellen.

### Änderung

- Die Suche im progressiven Apple-Audiopfad geht weiter, bis die Format- und URL-Prüfung einen Kandidaten liefert. HLS-only-Antworten werden erkannt, SABR-Profile werden in diesem Pfad übersprungen. Die vorhandenen Host-, Playability- und DRM-Prüfungen gelten weiter.
- `player_requests` zählt neue Player-Aufrufe im Anfragebudget. Der Bericht enthält eine begrenzte Liste redigierter Profil- und Ergebniswerte. Netzfehler bleiben von einer vollständigen Suche ohne passenden Stream unterscheidbar.
- Downloadauflösung und spekulativer URL-Prefetch teilen sich einen Hintergrundplatz. Eine direkt gestartete Wiedergabe braucht diesen Platz nicht. Abbruch und Kontowechsel beenden veraltete Resolverarbeit. Bei fehlendem Stream endet der automatische Downloadversuch, der manuelle Retry bleibt verfügbar. Swift erneuert die Sitzung erst nach einer Folge tatsächlicher Medien-Refusals.

### Nachweise

- Vor dem Fix (`e7525bf`) schlugen beide Kotlin-Regressionen im isolierten JVM-Lauf mit `No playable stream found for this track` fehl. In den kontrollierten Antworten lieferte das erste Profil nur HLS oder eine URL auf einem unerlaubten Host. Ein zweites Profil desselben Clients lieferte ein progressives Audioformat. Der [native Gegenlauf vor dem Fix](https://github.com/Redurbabat/BBT-Bit/actions/runs/41879520101) ist separat.
- Mit Fix waren alle sieben Kotlin-JVM-Fixtures erfolgreich. Der Filter lautete `jvmTest --tests '*InnerTubeExtractorTest.progressiveAudio*' --tests '*InnerTubeExtractorTest.hlsManifest*' --tests '*InnerTubeExtractorTest.automaticFallbackReachesSabrAfterDirectClientsFail'`. Der isolierte Lauf verwendete die echten Extractor-Quellen und Ktor MockEngine. Plattformfunktionen für Apple und JavaScript waren Testadapter.
- Der Prüfweg nutzt den bestehenden Simulator-Workflow. `:innertubex:macosArm64Test` und `:shared:macosArm64Test` prüfen Extraktion, Netzfehler, Abbruch und Kontowechsel. Swift-Prüfungen prüfen Fehlermeldung, Download-Retry und vorhandene Offline-Dateien. `cargo test --locked` prüft unter anderem Decoder und Puffer.
- **ECHTGERÄT NICHT GETESTET.** Für BBT-002 den signierten Reparaturbuild auf dem iPhone verwenden. Der Nachweis braucht eine aufgelöste YouTube-Quelle, erste Audio-Bytes, einen positiven Audiopuffer, hörbare Ausgabe und steigende Position. Vorschau und Fixtures werden separat gewertet.
