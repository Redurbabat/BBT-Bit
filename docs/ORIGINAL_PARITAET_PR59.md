# Original-Funktionen auf PR #59

Auftrag vom 9. November 2026: die im Vergleich gefundenen Verbesserungen von RED Bit übernehmen. Basis ist `620f393`, ausschließlich Branch `codex/red-bit-integration-motion-20261108` / PR #59.

## Umsetzung und Grenzen

1. Addon-Autoplay: vorhandenen TrackMatcher und YouTube-Suche für einen zeitlich begrenzten Radio-Seed benutzen. Die laufende Aufnahme wird nicht ersetzt. Veraltete Antworten nach Titel-/Kontowechsel verwerfen.
2. Automix-Anzeige: den bestehenden Rust-Mixer beibehalten. Audio startet weiterhin am geplanten Mixpunkt; Metadaten/Queue/Now Playing wechseln einmalig beim stilabhängigen Übergabepunkt. Position, Seek, Skip, Repeat und Quellwechsel gemeinsam prüfen.
3. Mix-Vorschau: zwei gemessene Wellenformen aus begrenzten Decoder-Fenstern; Vorbereitung außerhalb des Audiopfads, getrennte Lade-/Fehlerzustände und begrenzter Retry für wachsende Dateien. Keine erfundenen Audioformen.
4. Offline-Playlists: optionaler regelmäßiger Abgleich bei aktiver App und Nachholen beim Aktivieren. WLAN-Regel, Konto und vollständige Seitenliste beachten. Nur ergänzen; gelöschte Downloads nicht zurückholen. Bestehende Indexdaten weiter lesen.
5. Updates: aktuelle Repository-Identität und Installationshinweise korrigieren. Private Release-API ohne Zugang nicht als funktionierend ausgeben; keine Geheimnisse in der App. Sparkle erst mit projektspezifischem verifiziertem Feed aktivieren. Keine Veröffentlichung oder Änderung an Signierschlüsseln.

## Nachweise

Lokal auf Linux mit Swift 6.2.1, Kotlin 2.4.10 / Coroutines 1.11.0 und Rust 1.99.1 ausgeführt:

| Prüfung | Ergebnis und Grenze |
| --- | --- |
| `bash scripts/check-original-parity.sh` (`SWIFTC` auf Linux gesetzt) | **BESTANDEN:** Seed-Zustand mit Titel-/Kontowechsel und Wiederholungspause; echte Drei-Band-Messung einschließlich Stille, Frequenzunterscheidung und ungültiger Samples; begrenzte Decoder-Fenster; Produktions-Vorschaudecoder mit kontrolliertem FFI-Adapter; Update-Identität; neun asynchrone Fälle mit den aus `DownloadStore` entnommenen Produktionsmethoden. Auf Linux ersetzt nur der Plattformadapter Apples Energiesparmodus. Netzwerk und Speicherablage sind kontrollierte Adapter. |
| `AutoplaySeedTest` über Kotlin-JVM / JUnit | **6 bestanden.** Produktionsmodelle, TrackMatcher und Seed-Funktion; nur die Serialisierungsannotation ist ein Adapter. Falscher Künstler wurde zunächst nicht abgewiesen; der neue Fall scheiterte und besteht nach der strengeren Künstlerprüfung. Kein JSON-/Ktor-/Kotlin-Native-Gesamtbuild. |
| `cargo test --locked --manifest-path native-core/Cargo.toml --lib mixer::tests:: -- --test-threads=2` | **76 bestanden, 1 fehlgeschlagen.** Neuer Midpoint-Fall scheiterte vor der Änderung am vorzeitigen Handoff. Vier neue Tests prüfen Midpoint/einmalige Übergabe, Basswechsel-Punkt, Seek davor und ausdrücklichen Skip-Mix. Vorhandene Seek-/Repeat-/Gapless-/Swap-Prüfungen bleiben erhalten. |
| `cargo test --locked --manifest-path native-core/Cargo.toml --lib -- --test-threads=2` | **323 bestanden, 1 fehlgeschlagen, 1 ignoriert.** Der einzige Fehler ist der bereits unter P-021 dokumentierte Linux-AAC-Regionentest, erneut exakt `113624 frames`. Die Gesamtreihe ist nicht grün. |
| `bash scripts/check-settings-audio.sh` | **BESTANDEN:** tatsächlicher ReleaseAsset-/Manifestfilter akzeptiert RED-Bit-Pakete und verwirft ursprüngliche RED Bit-Pakete; Version/Build und Paketmetadaten geprüft. |
| Livetest-, Repository-, Release-, Lokalisierungs- und RED-Morph-/Now-Playing-Quellprüfungen | **BESTANDEN.** Swift-Syntax aller geänderten/neuen Swift-Dateien und YAML separat geprüft. Quellprüfungen sind kein App-Build. |

Der Rust-FFI-Export bleibt unverändert. Die neue Kotlin-Bridge benötigt ein frisch gebautes Shared-Framework. **NICHT GETESTET:** kompletter Xcode-/Kotlin-Native-Build, SwiftUI-Typprüfung mit Apple-SDK, Simulator, signierte IPA/DMG, Installation, Datenübernahme und hörbare Wiedergabe. GitHub-Actions war zuletzt wegen des ausgeschöpften Budgets gesperrt; keine Budgetänderung und kein manueller Neustart.

## Konkretes Verhalten und Datenmigration

- Addon-Autoplay sucht höchstens acht Sekunden nach einem Audio-Titel mit passendem Künstler, Aufnahme und Länge. Einträge und Audioquellen werden nicht ersetzt. Ergebnisse bleiben auf Titel, Wiedergabegeneration und Konto begrenzt; ein erfolgloser Lookup erhält 15 Sekunden Pause.
- Automatische Mixe übergeben Metadaten in der Mitte oder am geplanten Basswechsel. Ausdrückliches Weiter mit Skip-Mix bleibt sofortig; ein Source-Swap meldet keinen Titelwechsel. Seek vor der Übergabe bleibt beim ausgehenden Titel, danach beim eingehenden. Der UI-Fortschritt verwendet die bestätigte Engine-Position; ein Pausezustand lässt die Mixanzeige nicht nach bloßer Wanduhr auslaufen.
- Die Mix-Details lesen bis zu 24 Sekunden je Deck, erst beim Öffnen. Drei Frequenzbänder stammen aus PCM; BPM/Tonart erscheinen nur aus vorhandenem Cache. Höchstens drei Abrufe im Abstand von zwei Sekunden, danach ein manueller Wiederholungsbutton. Nicht vorhandene Audiodaten bleiben leer. Keine zweite Wiedergabeengine und keine neuen Rust-Exports.
- Der Playlist-Schalter ist standardmäßig aus. Bei aktiver App wird nach zwölf Stunden geprüft, beim Öffnen nach sechs Stunden nachgeholt. WLAN-Regel, Konto, Energiesparmodus und mindestens 128 MiB freier Speicher werden respektiert. Teillisten und Continuation-Schleifen werden nicht übernommen. Nach Fehlern gilt eine kontobezogene Pause von 15 Minuten. Mehr als 50 neue Titel je Playlist benötigen den sichtbaren Ladebutton.
- Download-Indexversion 1 bleibt lesbar: die neuen Journal-/Zeitfelder sind optional. Bestehende Einträge ohne Journal erhalten beim ersten vollständigen Abgleich nur eine Ausgangsliste; dabei wird nichts nachgeladen. Neue vollständige Sammlungsdownloads legen das Journal sofort an. Gelöschte Titel bleiben bekannt; online entfernte Titel verlieren ihre Offline-Datei nicht. Fehlgeschlagene, nicht bewusst abgebrochene Aufträge können beim nächsten Abgleich erneut angefordert werden.
- Alle Updatepfade, Paketfilter, About-Links und Installationshinweise verwenden RED Bit. Öffentliche Modell-Downloads und ursprüngliche Lizenzhinweise bleiben erhalten. Eine private oder noch fehlende App-Veröffentlichung ist ein ausdrücklicher Status; die App erhält keinen GitHub-Zugangsschlüssel. Sparkle startet nur mit eigenem 32-Byte-Schlüssel und dem eigenen Feed. Es wurde nichts veröffentlicht.

## Apple-Abnahme

1. Addon-Titel ohne YouTube-ID abspielen; Radio-Tail, No Match, Künstler-/Versionsabweichung und Kontowechsel während des Lookups prüfen.
2. Mix vor/nach der Übergabe pausieren, suchen und überspringen; Repeat One/All sowie geplanten Basswechsel mit Systemplayer und echter hörbarer Ausgabe vergleichen.
3. Details vor/während des Mixes öffnen; beide gemessenen Ausschnitte, einseitig fehlende Daten, Retry und Schließen während des Decodierens prüfen.
4. Kleines iPhone, iPad und Mac mit großer Schrift, VoiceOver und Reduce Motion prüfen; Suche, native Dock-Minimierung und Zoom bleiben eigene Regressionen.
5. Playlist-Schalter, WLAN-/Kontowechsel, alte Indexdatei, Teilliste, bewusst gelöschter Titel, mehr als 50 Ergänzungen, Neustart und knappen Speicher prüfen.
6. Private Release-API, fehlende Veröffentlichung, eigenes Manifest und deaktivierten Mac-Updater prüfen. Anschließend erst installierbare Pakete nach dem Release-Ablauf erzeugen.

## Herkunft

Verhaltensreferenzen: GPLv3-Projekt [kushagrasinghx/BitChord](https://github.com/kushagrasinghx/BitChord/tree/acf219a7e4a7f52f026d4336d5c7ac5cf7bfafcc), insbesondere `Autoplay.kt`, `CrossfadeController.kt`, `MixViewPopup.kt`, `PlaylistSync.kt`. Direkte Apple-Basis: [Redurbabat/RED-Bit](https://github.com/Redurbabat/RED-Bit/tree/898d8ed746b1bfdeb26a4c2d24484844241ed990). Umsetzung in den vorhandenen Swift-/Kotlin-/Rust-Pfaden.
