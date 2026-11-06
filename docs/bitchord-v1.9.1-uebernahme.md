# BitChord v1.9.1 → BBT-Bit: Übernahme und Konfliktentscheidungen

Stand: 2026-11-06. Ausgangsbasis für BBT-Bit: `main` bei `c2cf0a961f6a5d8a6a21308745d9dd187e11bbc7`.
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
| Home: `hideHomeVideos` | AUSSTEHEND | `ShelfCard` hat keine verlässliche Video-Klassifizierung; nachweislich ohne Fehlfilterung portieren |
| Home: `hideTopPicks` | AUSSTEHEND | Im aktuellen Home ist keine eigene Top-Picks-Leiste nachgewiesen; keine funktionslose Einstellung hinzufügen |
| Home: `hideHomeMoods` | AUSSTEHEND | Aktuell Mood/Genre in Explore vorhanden; Home-Shelf-Existenz prüfen |
| `squareVideoThumbnails` | AUSSTEHEND | Video-Identifikation und Artwork-Sizing in SwiftUI sauber definieren |
| Prefer Music Only / Video→Audio | **DOPPELT** | Bereits vorhandene native Quellauflösung gegenüber upstream `MusicOnlyPlayback.kt`; Nutzerentscheidung erforderlich |
| Autoplay / Empfehlungen / Recents | **TEILWEISE DOPPELT** | Bestehende Queue-, Home- und History-Implementierung erhalten; Änderungen in `Autoplay.kt` selektiv prüfen |
| Crossfade, Automix-Vorschau | **DOPPELT/TEILWEISE** | Rust-Mixer und native Automix-Details mit neuem Originalverhalten vergleichen; Nutzerentscheidung zu UI-Variante |
| SourceResolver, Song-Matching, StreamLengthProbe | AUSSTEHEND – priorisiert | Gemeinsamer Kotlin-Resolver, Streamdauer, Titel/Künstler/Album-Matching und realistische Tests; `NO_PLAYABLE_STREAM` getrennt nachweisen |
| AddonAuth / Addon-Qualitätswahl | AUSSTEHEND – Sicherheitsreview | Keine unverschlüsselten Tokens, keine Bypass-Implementierung; iOS Keychain und Add-on-Protokoll prüfen |
| Bit-perfect Pause/Resume | PLATTFORMANPASSUNG | Android-AudioSink/USB-Code nicht übernehmen; relevante Fehlerszenarien für Rust/Apple-Audio testen |
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

## Tests / Nachweise

- Original-Diff: GitHub-API-Vergleich erfolgreich (17 Commits, 94 Dateien).
- BBT-Bit-Branch-Diff: GitHub-Vergleich bestätigt ausschließlich die genannten Dateien.
- JSON-Syntax der geänderten String-Catalog-Datei: geprüft.
- Swift-Syntaxprüfung: **NICHT GETESTET**.
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

1. Prefer Music Only / Musikvideo-Konvertierung: BBT-Bit-Implementierung beibehalten und upstream-Fixes ergänzen oder Originalverhalten ersetzen?
2. Autoplay und Empfehlungen: bestehende native Queue als führend belassen oder Originalverhalten maßgebend machen?
3. Automix/Crossfade: Rust-Engine behalten und Verbesserungen portieren oder die Übergangslogik stärker ändern?
4. Player-Themes / RED Morph: native RED-Morph-Oberfläche belassen und neue Optionen ergänzen oder das Originaldesign übernehmen?
5. Glass-Performance: bestehende Reduce-Blur-/Performance-Modi ergänzen oder Originalschalter separat anbieten?

**Bis zur Entscheidung keine doppelten Playback-, Player- oder Automix-Pfade implementieren.**
