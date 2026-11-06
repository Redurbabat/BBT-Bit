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

## RED Morph ohne Build-Tokens

Der Design-Branch `feature/red-morph-player-search-navigation` verwendet vor einem Apple-Build folgenden **zusätzlichen statischen** Prüfschritt:

```bash
python3 scripts/check-red-morph-source.py
```

Dieser Befehl prüft elf Quellinvarianten: oberes iPhone-Suchfeld, persistenter Suchquellen-Picker, Accessibility-IDs, getrennte Top-Ergebnis-Aktionen, keine Infinity-Dock-Reihe im Live-Player, Automix in der Zeitzeile, Tastatur-Safe-Area, native Tab-Leiste, Reduce Motion, XCUITest-Startweg und deutsche UI-Texte. Er benötigt weder Xcode noch Build-Tokens. Ein grünes Ergebnis belegt **keine** Swift-Kompilierung und **keinen** funktionierenden Musikplayer.

Der UI-Test `AppleApp/UITests/RedMorphSearchUITests.swift` startet über `--bbt-ui-test-search` die echte Suchansicht. Er verifiziert Textfeldposition und Tastaturfreiraum, die sprachunabhängige Löschaktion sowie einen XCTest-Screenshot. Vor Freigabe zusätzlich in der normalen App **mit Mini-Player und Tab-Leiste** navigieren, die Tastatur öffnen/schließen, Top-Result/Playlist getrennt antippen und Player-Panes mit Reduce Motion, VoiceOver und großer Schrift prüfen.

**CI-Limit (06.11.2026):** Laut Projektinhaber sind derzeit keine Build-Tokens verfügbar. Keine manuelle Wiederholung der kostenpflichtigen Jobs. Lokale Xcode- und Echtgerätetests bleiben `NICHT GETESTET`, solange keine Apple-Hardware bzw. Runner mit erfolgreichem Resultat zur Verfügung steht.

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
