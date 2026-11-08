# RED Bit · Integration und Motion-Prüfung vom 8. November 2026

Arbeitsbranch: `codex/red-bit-integration-motion-20261108`. Ausgangspunkt: `main` bei `b571aab`. Der Merge nach `main` benötigt die ausdrückliche Freigabe des Maintainers.

## Übernommene PRs

| PR | Inhalt | Einordnung |
| --- | --- | --- |
| [#54](https://github.com/Redurbabat/RED-Bit/pull/54) | Creative Lab, Tastatur-Handoff, Fortschrittsbegrenzung, VoiceOver | Basierend auf dem inzwischen integrierten PR #50 |
| [#57](https://github.com/Redurbabat/RED-Bit/pull/57) | Regulärer Such-Tastatur-Test | Baut auf #54 auf |
| [#58](https://github.com/Redurbabat/RED-Bit/pull/58) | Ein eindeutiger, erreichbarer Mini-Player vor/nach der Tastatur | Baut auf #57 auf; eingebundener Kopf `9851d5b` |

Die drei Köpfe sind durch Merge-Commit `7baa81f` im Integrationsbranch enthalten. Git meldete keine Textkonflikte. Die früheren PRs #49, #50 und #51 waren schon über #56 in `main`; ihre Konfliktlösungen, neuen Künstler-/Lyrics-Funktionen, Downloadkorrektur und das SideStore-Testsystem bleiben erhalten. Fremde Branches werden nicht überschrieben.

Die semantische Nachprüfung fand im Creative-Lab-PR denselben Automix-VoiceOver-Wert zweimal am selben Dock-Button. Eine Deklaration wurde entfernt; der gewünschte Zustandswert bleibt erhalten. Der Queue-Horizon-Hinweis aus #54 bleibt abhängig von tatsächlichem Fokus und Reduce Motion.

## Befunde und Änderungen

- **Dock:** Der Wechsel zwischen `.never` und `.onScrollDown` während einer Geste konnte die Platzierungen der Tab-Leiste und des Accessory entkoppeln. Nach dem neuen iPhone-Fotobeleg bleibt jetzt durchgehend Apples `.onScrollDown` aktiv. Die eigene Richtungsbeobachtung steuert nur die Logo-Insel. Native Tab-Leiste, Suchrolle, Inline-Montage und Zoom-Quelle bleiben bestehen.
- **Langsame Gesten:** Der alte Tracker aktualisierte seinen Ausgangspunkt und verwarf danach jedes Bilddelta unter 0,75 pt. Langsames Scrollen konnte dadurch dauerhaft unerkannt bleiben. Gemessen wird jetzt der Gesamtweg ab dem Wendepunkt mit 13 pt Hysterese; ungültige Werte werden ignoriert. Regressionen decken kleine Schritte, Zittern und Umkehr nach ungültigen Werten ab.
- **Obere Insel:** Scroll-Reveal verwendet direkt den kompakten Zustand, statt zunächst einen nach 180 ms abbrechbaren Spark zu zeigen. Abwärtsscrollen schließt auch die erweiterte Insel. Titelwechsel erhalten manuell erweiterte Controls. Der Ursprung wird am echten Toolbar-Logo gemessen und während einer Präsentation festgehalten. Die zweite Skalierung um einen hartcodierten Punkt entfällt. Reduzierte Bewegung überspringt den Spark.
- **Mini-Player:** Die Tastatur-Pill war außerhalb des nativen Bottom Accessory montiert, ließ ihre eigene Fläche aber trotzdem weg. Nur `PlaybackAccessory` setzt nun `usesSystemChrome: true`; Tastatur-/Inset-Varianten zeichnen selbst genau eine Systemglas- oder opake Fläche. Öffnen, Play/Pause und Next erhalten mindestens 44 pt hohe Treffflächen **innerhalb der Button-Labels**. Die #58-Hierarchie zeigte für den Weiter-Button lediglich das kleine Symbolrechteck trotz äußerem Rahmen. Der Fortschrittsschutz aus #54 bleibt erhalten.
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
| Neue Swift-Verhaltenstests und Swift-Syntax | [PR-Regressionen für 96de5ba](https://github.com/Redurbabat/RED-Bit/actions/runs/42490417322) BESTANDEN auf macOS |
| Vollständiger App-Build und 15 Designvorschauen | [Simulatorlauf für 96de5ba](https://github.com/Redurbabat/RED-Bit/actions/runs/42490417309): Xcode 26.6, iPhone 17 Pro / iOS 26.5: BESTANDEN; 15 Vorschau-Screenshots vorhanden. Name und neues Icon auch im Simulator-Home-Bildschirm sichtbar |
| Regulärer Such-/Tastaturweg | Im selben Lauf am darüberliegenden Automix-Erststartdialog gescheitert; Korrektur des Teststarts und zusätzlicher Vollplayer-Nachweis vorbereitet, erneuter Lauf erforderlich |
| Native Download-Recovery und Kotlin-Tests | Im selben Lauf BESTANDEN: Download-Recovery, gemeinsame Kotlin-Tests und Extractor-Regressionen |
| Rust-Tests | Im selben Lauf BESTANDEN: 314 bestanden, 0 fehlgeschlagen, 1 ignoriert; der zuvor rote Handoff-Test ist in diesem Lauf erfolgreich |
| Echte Logo-/Insel-Scrollanimationen, Bedienung unter Wiedergabelast | NICHT GETESTET; die 15 Designvorschauen ersetzen diesen Nutzerweg nicht |
| Echtes iPhone, signierte IPA, Audio, App-Update | NICHT GETESTET |

Die ersten Fixture-Aufrufe scheiterten an den Sandbox-Rechten des Windows-Temp-Verzeichnisses. Mit `TEMP`/`TMP` im ignorierten Workspace-Verzeichnis `build/test-tmp` liefen die Prüfungen erfolgreich; dafür wurden keine Produktdateien geändert.

Die erste Codemagic-Quellprüfung erwartete noch den parameterlosen Island-Aufruf und `controller.duration > 0` direkt im View-Text. Diese überholten Textbedingungen wurden auf den gemessenen Ursprung und den endlichen, geklammerten Fortschritt aktualisiert. Die echten Swift-Verhaltenstests liefen zuvor bereits erfolgreich.

Die exportierte UI-Hierarchie von #58 zeigt außerdem den Automix-Modell-Erststartdialog über der Home-Ansicht. Er blockierte den Such-Tab, obwohl dessen Accessibility-Element vorhanden war; XCTest berechnete deshalb einen nicht erreichbaren Treffpunkt. Der reguläre Suchtest setzt nun zusätzlich den **wirklich verwendeten** Defaults-Schlüssel `automix_models_prompt_dismissed_v2` für den bereits beantworteten Erststartdialog. Die Produktionssuche und der Dialog bleiben unverändert. Nach Tastaturschluss muss der echte Mini-Player außerdem den Vollplayer mit dem vorhandenen Transport-Button öffnen. Es werden weder Audiodaten noch Playerzustände vorgetäuscht.

Der vorangegangene [CI-Lauf von #58](https://github.com/Redurbabat/RED-Bit/actions/runs/42486459967) kompilierte Kotlin, Rust-Framework und Swift-App, scheiterte aber bei einem alten Automix-Testlabel und vor dem Suchfeld. Außerdem scheiterten `direct-drop` und Rust `a_planned_transition_overlaps_rather_than_waits_for_the_end` (313 bestanden, 1 fehlgeschlagen, 1 ignoriert). Dieser Lauf prüfte **nicht** die Integration auf dem neueren `main`, das die Automix-Test- und Downloadkorrekturen aus #56 enthält. Die Rust-Ursache ist damit nicht als behoben nachgewiesen. Keine grünen UI-/Audio-Erfolge aus diesem roten Lauf ableiten.

## Geräteabnahme

1. Neuer Build mit protokollierter SHA: hell/dunkel, große Schrift, reduzierte Bewegung und Transparenz.
2. Home, Explore und Bibliothek: langsam und schnell nach unten scrollen, innerhalb derselben Berührung nach oben umkehren, danach eine neue Aufwärtsgeste beginnen. Keine vorzeitige Dock-Minimierung, kein Inselblitz, kein zweiter Player.
3. Mit echtem Titel die obere Insel vom Logo öffnen/erweitern, Titel wechseln, nach unten scrollen, wieder öffnen, Play/Pause/Skip und Lyrics/Queue testen. Auf dem iPhone 13 Pro Max ist dies die appinterne Insel, keine Hardware-Dynamic-Island.
4. Native Suche öffnen, Tastatur öffnen/schließen und wiederholen. Genau eine erreichbare Pill oberhalb der Tastatur, eigene lesbare Fläche, keine verdeckten Treffer. Nach dem Schließen müssen native Dock-Montage und Vollplayer-Zoom wieder funktionieren.
5. iPad-Split-View und macOS getrennt prüfen. Anschließend auf echtem iPhone hörbare Wiedergabe, Zeitfortschritt, Hintergrund, Queue und Ausgabewechsel abnehmen. Ein visueller Test belegt kein Audio.

## Ergänzung nach iPhone-Fotos und Livetest vom 8. November

Die Tastatur-Pill wird innerhalb des Navigationsinhalts montiert, damit Suchfeld und Schließen-Knopf ihren nativen Safe-Area-Platz vorher erhalten. Die äußere Montage auf der TabView überlagerte diese Bedienelemente. Die neue XCUITest-Geometrie prüft deshalb auch das Suchfeld statt nur den Tastaturrand. Das Top-Ergebnis begrenzt seine Aktionszeile auf die intrinsische Texthöhe und behält sichtbare Symbol-/Text-Labels. Ein eigenes Offline-Fixture prüft die tatsächlichen Produktionskomponenten in List/TabView, einschließlich Scrollen und Rückrichtung. Keine simulierte Wiedergabe.

Der angehängte JSON-Bericht enthält 1735 Messungen: Zeitfortschritt in 1734, Decoder/gestartete Ausgabe in allen Messungen, 27 neue Pläne und 9 gemeldete Übergänge. Fehlerstatus in zwei Abschnitten, Sekunden 271–283 und 636–648 (je 13 Messungen). ONNX-Beat erkannt; Core-ML-/Vocal-Nutzung nicht nachgewiesen, obwohl alle Modelle als installiert markiert sind. Alle 14 manuellen Prüfungen stehen auf „Nicht getestet“. Berichtsversion 1 enthält weder Build-SHA noch Fehlertext; eine konkrete Fehlerursache ist daraus nicht ableitbar. Version 2 ergänzt datensparsam Version, Buildnummer, Revision und Betriebssystem; bestehende Felder bleiben erhalten. Die Quelldatei mit privaten Nutzerdaten wird nicht veröffentlicht.

Die Quellen erklären außerdem eine mögliche Modellkombination: `AutomixModelPolicy.paths` schaltet im Modus `EFFICIENT` Vocal-Modell und Core-ML-Beschleuniger bewusst aus, während ONNX-Beat aktiv bleiben kann. Dieses Muster passt zum Bericht, der gewählte Modus fehlt dort aber; deshalb ist das keine bestätigte Ursache. `playbackErrorPresent` basiert auf dem gemeinsamen `lastError`, das auch abgewiesene Favoriten-Aktionen aufnehmen kann. Die beiden Abschnitte sind daher Fehlerstatus-Nachweise, kein Beleg für zwei Audioausfälle. Für die Zuordnung werden ein neuer Export mit Revision und die dazugehörige konkrete Fehlermeldung benötigt.

Die kompakte Logo-Insel berücksichtigt zusätzlich die tatsächlich gemessenen Toolbar-Aktionen. In der Bibliothek begrenzt die erste Aktion (Verlauf/Plus) ihre Breite, auf den anderen Hauptseiten das Profil. Die breite erweiterte Steuerung öffnet darunter, damit keine Toolbar-Aktion überdeckt wird. Messungen werden beim Verschwinden der jeweiligen Toolbar entfernt und bei der Präsentation eingefroren. Geräteanimation und VoiceOver bleiben gesondert abzunehmen.
