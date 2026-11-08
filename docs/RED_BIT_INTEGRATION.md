# RED Bit · Integration und Motion-Prüfung vom 8. November 2026

Arbeitsbranch: `codex/red-bit-integration-motion-20261108`. Ausgangspunkt: `main` bei `b571aab`. Der Merge nach `main` benötigt die ausdrückliche Freigabe des Maintainers.

## Übernommene PRs

| PR | Inhalt | Einordnung |
| --- | --- | --- |
| [#54](https://github.com/Redurbabat/RED-Bit/pull/54) | Creative Lab, Tastatur-Handoff, Fortschrittsbegrenzung, VoiceOver | Basierend auf dem inzwischen integrierten PR #50 |
| [#57](https://github.com/Redurbabat/RED-Bit/pull/57) | Regulärer Such-Tastatur-Test | Baut auf #54 auf |
| [#58](https://github.com/Redurbabat/RED-Bit/pull/58) | Ein eindeutiger, erreichbarer Mini-Player vor/nach der Tastatur | Baut auf #57 auf; eingebundener Kopf `9851d5b` |

Die drei Köpfe sind durch Merge-Commit `7baa81f` im Integrationsbranch enthalten. Git meldete keine Textkonflikte. Die früheren PRs #49, #50 und #51 waren schon über #56 in `main`; ihre Konfliktlösungen, neuen Künstler-/Lyrics-Funktionen, Downloadkorrektur und das SideStore-Testsystem bleiben erhalten. Fremde Branches werden nicht überschrieben.

## Befunde und Änderungen

- **Dock:** `beganDragging()` setzte `keepExpanded` bei jeder neuen Berührung auf `false`. Ein schon aufgeklapptes Dock konnte so vor der ersten bestätigten Bewegung erneut minimieren. Der Zustand bleibt jetzt bis zu einer wirklich erkannten Gegenrichtung erhalten. Die native Tab-Leiste, Suchrolle, Inline-Montage und Zoom-Quelle bleiben bestehen.
- **Langsame Gesten:** Der alte Tracker aktualisierte seinen Ausgangspunkt und verwarf danach jedes Bilddelta unter 0,75 pt. Langsames Scrollen konnte dadurch dauerhaft unerkannt bleiben. Gemessen wird jetzt der Gesamtweg ab dem Wendepunkt mit 13 pt Hysterese; ungültige Werte werden ignoriert. Regressionen decken kleine Schritte, Zittern und Umkehr nach ungültigen Werten ab.
- **Obere Insel:** Scroll-Reveal verwendet direkt den kompakten Zustand, statt zunächst einen nach 180 ms abbrechbaren Spark zu zeigen. Abwärtsscrollen schließt auch die erweiterte Insel. Titelwechsel erhalten manuell erweiterte Controls. Der Ursprung wird am echten Toolbar-Logo gemessen und während einer Präsentation festgehalten. Die zweite Skalierung um einen hartcodierten Punkt entfällt. Reduzierte Bewegung überspringt den Spark.
- **Mini-Player:** Die Tastatur-Pill war außerhalb des nativen Bottom Accessory montiert, ließ ihre eigene Fläche aber trotzdem weg. Nur `PlaybackAccessory` setzt nun `usesSystemChrome: true`; Tastatur-/Inset-Varianten zeichnen selbst genau eine Systemglas- oder opake Fläche. Öffnen, Play/Pause und Next erhalten mindestens 44 pt hohe Treffflächen. Der Fortschrittsschutz aus #54 bleibt erhalten.
- **Sprache:** Die neuen deutschen Leerzustände aus #54 verwenden wieder lokalisierbare Schlüssel. Deutsche Katalogeinträge ergänzen diese Schlüssel und bestehende Accessibility-Texte, ohne gespeicherte Sprachwahl oder Musiktitel zu überschreiben.
- **Logo:** Eigener Signalband-Entwurf: ein geöffnetes R als zusammenhängende Bandform. [Vorschau](../artwork/red-bit/signal-brand-preview.png), [Quelle und Rendering](../artwork/red-bit/README.md). App-Icon, Icon-Composer-Ebene, Onboarding und Toolbar verwenden denselben Marker. Bundle-IDs, URL-Schema und Datenpfade bleiben unverändert.

## Prüfstand

| Prüfung | Ergebnis |
| --- | --- |
| `git diff --check` | BESTANDEN |
| `python scripts/check-repository.py --base origin/main` | BESTANDEN |
| `python scripts/check-red-morph-source.py` | 8 Quellinvarianten BESTANDEN; alte, durch #54 überholte Tastatur-Erwartung berichtigt |
| `python scripts/check-native-island-source.py` | 8 Quellinvarianten BESTANDEN |
| `python scripts/verify-settings-german.py` | BESTANDEN |
| `python scripts/repository-verify/check.py` | 7 Gegenproben BESTANDEN |
| `python scripts/release-verify/check.py` | BESTANDEN |
| `python scripts/ios-test-verify/check.py` | 8 Fixtures BESTANDEN |
| `python scripts/render-red-bit-brand.py` | BESTANDEN; große Form sowie kleine Marker auf hellem/dunklem Grund visuell geprüft; Legacy-Icon 1024 × 1024 RGB ohne Alpha |
| Neue Swift-Verhaltenstests / vollständiger App-Build | Cloud-Prüfung ausstehend; unter Windows kein Apple-SDK |
| Simulator, neue Logo-/Island-Screenshots aus der App | NICHT GETESTET bis zum abgeschlossenen Cloud-Lauf |
| Echtes iPhone, signierte IPA, Audio, App-Update | NICHT GETESTET |

Die ersten Fixture-Aufrufe scheiterten an den Sandbox-Rechten des Windows-Temp-Verzeichnisses. Mit `TEMP`/`TMP` im ignorierten Workspace-Verzeichnis `build/test-tmp` liefen die Prüfungen erfolgreich; dafür wurden keine Produktdateien geändert.

Der vorangegangene [CI-Lauf von #58](https://github.com/Redurbabat/RED-Bit/actions/runs/42486459967) kompilierte Kotlin, Rust-Framework und Swift-App, scheiterte aber bei einem alten Automix-Testlabel und vor dem Suchfeld. Außerdem scheiterten `direct-drop` und Rust `a_planned_transition_overlaps_rather_than_waits_for_the_end` (313 bestanden, 1 fehlgeschlagen, 1 ignoriert). Dieser Lauf prüfte **nicht** die Integration auf dem neueren `main`, das die Automix-Test- und Downloadkorrekturen aus #56 enthält. Die Rust-Ursache ist damit nicht als behoben nachgewiesen. Keine grünen UI-/Audio-Erfolge aus diesem roten Lauf ableiten.

## Geräteabnahme

1. Neuer Build mit protokollierter SHA: hell/dunkel, große Schrift, reduzierte Bewegung und Transparenz.
2. Home, Explore und Bibliothek: langsam und schnell nach unten scrollen, innerhalb derselben Berührung nach oben umkehren, danach eine neue Aufwärtsgeste beginnen. Keine vorzeitige Dock-Minimierung, kein Inselblitz, kein zweiter Player.
3. Mit echtem Titel die obere Insel vom Logo öffnen/erweitern, Titel wechseln, nach unten scrollen, wieder öffnen, Play/Pause/Skip und Lyrics/Queue testen. Auf dem iPhone 13 Pro Max ist dies die appinterne Insel, keine Hardware-Dynamic-Island.
4. Native Suche öffnen, Tastatur öffnen/schließen und wiederholen. Genau eine erreichbare Pill oberhalb der Tastatur, eigene lesbare Fläche, keine verdeckten Treffer. Nach dem Schließen müssen native Dock-Montage und Vollplayer-Zoom wieder funktionieren.
5. iPad-Split-View und macOS getrennt prüfen. Anschließend auf echtem iPhone hörbare Wiedergabe, Zeitfortschritt, Hintergrund, Queue und Ausgabewechsel abnehmen. Ein visueller Test belegt kein Audio.
