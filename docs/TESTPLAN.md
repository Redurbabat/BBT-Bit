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

**Regression P-008 (Album-Optional-Typ):** `QueueEntry.albumName` ist `String?`. Alle vier Signaturen in `NowPlayingController`/`ModernNowPlaying` müssen `albumName: String?` annehmen. Der MediaPlayer-Metadateneintrag darf nur einen nichtleeren String enthalten; das moderne `MusicContent` erhält einen normalisierten String. Die Quellprüfung kontrolliert diese Typen, **aber nur ein echter Xcode-Swift-Typecheck belegt Kompilierbarkeit**. Zusätzlich aus einer Playlist und dem obersten Suchergebnis jeweils einen Song abspielen, `Add to Playlist` getrennt betätigen und kontrollieren, dass das Hinzufügen keine Wiedergabe auslöst; lokale sowie YouTube-Titel ohne Albumnamen müssen funktionieren.

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
