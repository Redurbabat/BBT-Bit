# RED Bit · Integration und Motion-Prüfung vom 8. November 2026

## GitHub-Prüfungen und IPA vom 10. November 2026

### Aktueller Prüfstand · 64960ab und macOS-Korrektur

Die vier zwischenzeitlichen PR-Commits einschließlich des automatischen App-Tests wurden per Fast-forward übernommen. Deren gemeinsame Vorschau-Umgebung und Lyrics-Accessibility-Korrektur bleiben erhalten; überschneidende lokale Zwischenänderungen wurden nicht darübergelegt.

Der [native Lauf für 64960ab](https://github.com/Redurbabat/RED-Bit/actions/runs/42788297930) besteht bei **allen fünf iPhone-UI-Tests** einschließlich aller 15 Vorschauen, Lyrics-Umschaltung, Suche/Tastatur, Top-Ergebnis/Dock, Sternkarten-Finale und Video-/Listenwechsel. Kotlin-/Downloadprüfungen bestehen; Rust: **324 bestanden, 0 fehlgeschlagen, 1 ignoriert** (privater Audiokorpus). Der gesamte Lauf bleibt wegen des zusätzlichen macOS-App-Builds fehlgeschlagen: `MacNowPlayingSlot` verwendete `reduceMotion`, las den Environmentwert aber nur in der übergeordneten View ein.

Die Korrektur liest `accessibilityReduceMotion` direkt in der betroffenen macOS-View. Der schnelle Vorschau-Typecheck und der vollständige native App-Build bleiben aktiv; es wird keine Prüfung übersprungen oder gelockert. Die erneute Ausführung dieser Änderung steht bis zum nächsten PR-Lauf aus.

Die [IPA für 64960ab](https://github.com/Redurbabat/RED-Bit/actions/runs/42788288574/artifacts/13750101914) wurde bereits erfolgreich erzeugt und hochgeladen. Sie enthält den Stand vor der macOS-Korrektur. Nach dem Push folgt automatisch ein neues Paket desselben Arbeitsbranches. Signing, Installation, Update/Datenerhalt, physische Animationen und hörbare Audiowiedergabe bleiben **NICHT GETESTET**.

### Zweiter nativer Prüfstand · afef572

[Aktuelle IPA für afef572](https://github.com/Redurbabat/RED-Bit/actions/runs/42721097788/artifacts/13719559698): Gerätebuild, Inhaltsprüfung und Upload erfolgreich. Lokale Gegenprüfung derselben echten Datei: SHA-256 `4d6c01aff64793644f6d1e30e22eb92dde53a5b5e28a6942469a5a87f093dfd8`, arm64/iPhoneOS und eingebettete Revision stimmen mit `build.json` überein. [PR-Regressionen](https://github.com/Redurbabat/RED-Bit/actions/runs/42721105026) samt neuen Workflow-/Shellprüfungen und [Build-Konfiguration](https://github.com/Redurbabat/RED-Bit/actions/runs/42721105524) bestehen.

Der [zweite Simulatorlauf](https://github.com/Redurbabat/RED-Bit/actions/runs/42721105354) besteht bei Suche/Tastatur/Mini-Player, Sternkarten-Finale, Dock/Top-Ergebnis und Video-/Listenwechsel. Alle 15 PNG-Vorschauen werden erfolgreich gerendert; der Absturz ist behoben. Ein Interaktionstest fragte jedoch einen separaten StaticText ab, obwohl der Lyrics-Button seinen Text durch eine eigene VoiceOver-Beschriftung zusammenfasst. Die nachfolgende Korrektur veröffentlicht die tatsächliche Zeile als Accessibility-Wert; der Test wartet nach dem Umschalten auf diesen Wert.

Die erstmals zusätzliche macOS-Kompilierung fand außerdem, dass `liquidDesignSample` innerhalb der iOS-Aufnahmefunktion definiert war. Der Schlüssel liegt inzwischen außerhalb der Plattformbedingung; sein Standard bleibt auf beiden Plattformen `false`, ohne macOS-Aufnahmedienst oder neuen Player. Ein gezielter schneller macOS-SwiftUI-Typecheck verwendet die tatsächliche Definition für Lesen und Setzen des Schlüssels und ergänzt den vollständigen App-Build. Der neuere native Prüfstand steht oben. Signing, Installation, Datenerhalt und Audio auf dem echten iPhone bleiben **NICHT GETESTET**.

Fortsetzung auf dem aktuellen PR #59, Ausgangsrevision `5bd8eb3`. Alle sechs neueren Commits wurden ohne Überschreiben übernommen. Keine offenen Review-Kommentare. `main` bleibt unverändert.

Der [Gerätebau 42715735687](https://github.com/Redurbabat/RED-Bit/actions/runs/42715735687) ist tatsächlich erfolgreich: Swift-, Kotlin-/Rust-Frameworks, arm64-iPhoneOS-Paket und Verifikation. [Erstes IPA-Paket herunterladen](https://github.com/Redurbabat/RED-Bit/actions/runs/42715735687/artifacts/13719452748). Enthaltene Revision: `5bd8eb3f3fe41b30c046ee8a8ea85146631ecac3`, Version 1.0.4 / Build 13, Bundle-ID `com.babat.bbtbit`. Die heruntergeladene echte IPA wurde unter Windows nochmals mit `verify-ios-test-ipa.py` geprüft; SHA-256 `3b210473f9f74cd7c48046806eaf1eaa26056551074fe8de3bd021ca9d484dac` stimmt mit `build.json` überein. **Unsigniert:** SideStore-Signierung, Installation, Update/Datenerhalt und hörbares Audio sind weiterhin **NICHT GETESTET**.

Der [Simulatorlauf 42714848615, zweiter Versuch](https://github.com/Redurbabat/RED-Bit/actions/runs/42714848615) kompiliert ebenfalls die vollständige iOS-App. Von fünf UI-Tests bestehen Sternkarten-Finale mit 0/50/100 Prozent und Zurückspulen, Video-/Listen-Rückweg sowie begrenztes Top-Ergebnis mit nativem minimiertem Dock. Zwei Fehler bleiben in diesem Ausgangsstand: PNG-Selbsttest schließt die App wegen fehlender Umgebung, Suchtest findet den Tab über die falsche Kennung nicht. Screenshots, Video und Accessibility-Baum belegen die Fälle. Die nachfolgenden Kotlin-Prüfungen bestehen; Rust auf macOS: **324 bestanden, 0 fehlgeschlagen, 1 ignoriert**. Das macht den fehlgeschlagenen UI-Lauf nicht grün.

Die Korrektur reicht die vorhandene PlaybackSession und die gewählte Sprache in beide separaten `ImageRenderer`-Hierarchien weiter. Es entsteht kein zweiter Player. Gekennzeichnete Automix-Prüfdaten verwenden ihre eigenen Zeitwerte. Vorschau- und Debug-Nutzerwege erhalten dieselbe Spracheinstellung wie RootView; sprachunabhängige Kennungen prüfen den tatsächlichen Textwechsel und die aufgeklappten Signalstufen. Der Suchtest fragt den nativen Tab-Button über sein Symbol-Kindelement ab. Die Schallplatte hält bei Pause ihre echte Position und übernimmt keinen Fortschritt eines anderen Albums.

Zusätzliche CI-Prüfungen: alle Workflows über fixiertes Actionlint/ShellCheck; macOS-App-Build mit vorhandenen nativen Slices und gesichertem Protokoll. Der macOS-Koordinator-Test erhält den notwendigen CoreGraphics-Import und konkrete Geometriefälle. Vor dieser Änderung scheiterte er auf dem echten Apple-Runner an fehlenden CGRect-Eigenschaften, obwohl sein Linux-Adapter bestand. Keine gelockerten Prüfbedingungen.

Der Geräteworkflow verlinkt den tatsächlichen Upload direkt in der Laufübersicht und sichert native Caches auch nach späteren Buildfehlern. Der ausgewählte automatische Testbranch lautet jetzt `codex/red-bit-integration-motion-20261108`; Ausgabenlimits und Release-Prozesse wurden nicht verändert. Lokales Actionlint/ShellCheck, YAML/Python-Syntax, 21 IPA-Gegenproben, sieben Repository-Gegenproben, Release-, deutsche Einstellungs- und bestehende Quellprüfungen bestehen. Die erneute native Prüfung der Korrekturen und der neuen macOS-Stufe steht bis zum nächsten PR-Lauf aus.

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

## Korrekturen vom 9. November 2026

Ausgangsstand: PR #59 bei `a4a2987901013e16eba296cf2a3e11a8c2d914cd`, ausschließlich Branch `codex/red-bit-integration-motion-20261108`.

### Livetest und Range-Abbrüche

- `PlaybackProgressTracker` bewertet jedes Intervall neu. Pause, Puffern, großer Seek, Titelwechsel, ungültige Position und ungültige Uhr liefern keinen Fortschrittsnachweis. `playedProgressed` bleibt der getrennte Gesamtnachweis. Die Oberfläche benennt beide Aussagen getrennt.
- Playback-Fehler erhalten feste Kategorien an ihren ursprünglichen Meldestellen. Der gemeinsame App-Fehlertext bleibt die vorhandene Toast-Quelle; ein Favoritenfehler ist kein Playback-Fehler mehr. Der Export enthält Kategorien, keine rohen Fehlertexte.
- JSON **Version 3** erhält die bisherigen Felder und ergänzt `appErrorObserved`, `engineBuildRevision`, je Messung `appErrorPresent`, optional `playbackErrorKind` sowie `automixPerformanceMode`. Die Semantik von `samples[].progressed` ist jetzt intervallbezogen; `playbackErrorPresent`/`playbackErrorObserved` beziehen sich auf kategorisierte Playback-Meldungen. Version 1/2 dürfen für historische Auswertungen nicht wie Version 3 interpretiert werden. Ein ausgewählter Modellmodus beweist weiterhin keine tatsächliche Inferenz.
- `fetchNetworkRange` gibt nur bei geänderter Netzgeneration den Netzwechsel-Sentinel zurück. Ein lokal abgebrochener oder abgelaufener Request wird zum Transportfehler; die vorhandene äußere Wiederholungsgrenze greift. Echte Download-Cancellation bleibt Cancellation. Öffnender und nachfolgender Range verwenden denselben Wächter.
- Die privaten Diagnose-Anhänge wurden nicht übernommen. Ihre 128-KiB-Stopps, Decoderfehler und Ausgabe-Neuaufbauten sind noch nicht vollständig auf den neuen PR-Stand zurückgeführt. Der neue Coroutine-Nachweis belegt den beschriebenen Robustheitsfehler, nicht die vollständige Reparatur sämtlicher Gerätestopps. Kein ungeprüftes Aktivieren von SABR/HLS und keine Änderung von Chunk-Größen oder Audioausgabe.

### RED-Morph-Referenz und Bestand

Referenzen: [RED-Morph-Skill](https://github.com/Redurbabat/RED-Morph/blob/main/skills/red-morph/SKILL.md) und die live geprüfte [Sound-Ribbon-Studie](https://red-morph.redurbabat7.workers.dev/#/bbt-interactions). Die Browserstudie wurde mit veränderter Reglerposition geprüft; sie ist kein nativer Audiotest.

| Bestand | Entscheidung | Änderung |
| --- | --- | --- |
| Native Suche, Tab-Leiste und Mini-Player | KEEP | Vorhandene Montage und Navigation bleiben bestehen. |
| ArcPlaybackDeck | REWORK, eng begrenzt | Nur lokale Zeitmarken beim Ziehen hervorheben; derselbe Seek-Callback und dieselben Party-Sperren. |
| Zeitvorschau und VoiceOver-Seek | KEEP | Vorhandene Zeitdarstellung und einstellbare Accessibility-Aktion. |
| Daueranimation / neue Glasfläche | Nicht ergänzt | Ruhender Zustand ohne neuen Effekt; Reduce Motion unterdrückt die Vergrößerung. |

`ScrubFocusGeometry` liefert einen endlichen, begrenzten Fokus um den tatsächlichen Drag-Zeitwert. Es werden keine Audiowellenform und keine Beat-Marker erfunden. Beim Loslassen oder Abbruch setzt `GestureState` den Fokus zurück. Keine zusätzliche Timeline, keine Netzwerkabfrage und keine Modellinferenz.

### Tatsächlich ausgeführte Prüfungen

Linux x86_64, Swift 6.2.1, JDK 21, Kotlin-Compiler 2.4.10 und Coroutines 1.11.0 (dieselben Kotlin-/Coroutine-Versionen wie im Projekt). Compiler und Testwerkzeuge liegen außerhalb des Repositorys.

| Prüfung | Nachweis |
| --- | --- |
| Fortschrittsregression | Der extrahierte bisherige Algorithmus scheiterte bei „Ein Stillstand darf keinen früheren Fortschritt erben“. Neuer Produktionstracker besteht. |
| `bash scripts/check-automix-live-test.sh` | BESTANDEN: Typprüfung von Produktionsmonitor und Controller-Fehlerzustand einschließlich Observation-Makros mit Adaptern; Messung, JSON v3, Fehlertrennung, Reset und keine privaten Fixture-Werte im Export. Linux-Verhaltenstest ohne Observation-Anbindung; keine SwiftUI-/FFI-Typprüfung. |
| `NetworkRangeRequestTest` isoliert auf JVM | Vor Korrektur: 6 Fälle, 2 Fehler (lokaler Timeout und lokaler Request-Abbruch). Nach Korrektur: **7 Fälle bestanden**, einschließlich Netzwechsel, Eltern-Cancellation, Folgeversuch und normalem Transportfehler. Produktionsdatei und gemeinsame Testdatei wurden direkt mit Kotlin 2.4.10 kompiliert und mit JUnit 4.13.2 ausgeführt; kein Ersatzalgorithmus. |
| Scrub-Fokus | BESTANDEN mit `scripts/test-scrub-focus.swift`: Fokus, Ränder, inaktiver Zustand, Reduce Motion und ungültige Werte. |
| Geänderte Swift-Produktionsquellen | SYNTAX GEPRÜFT mit `swiftc -frontend -parse`. Kein vollständiger App-Typecheck. |
| Repository / Release / Deutsch | `python3 scripts/check-repository.py --base a4a2987901013e16eba296cf2a3e11a8c2d914cd`, `scripts/repository-verify/check.py` (7 Gegenproben), `scripts/release-verify/check.py`, `scripts/verify-settings-german.py`: BESTANDEN. |
| Bestehende Navigation / Now Playing | `scripts/check-red-morph-source.py` und `scripts/check-native-island-source.py`: je 8 Quellinvarianten BESTANDEN. |
| Vollständiger Apple-Build, Kotlin/Native, Simulator, VoiceOver, GPU-Leistung, hörbares Audio, signierte IPA und Update | **NICHT GETESTET**. Diese Linux-Umgebung besitzt kein Xcode. Keine manuellen CI-Neustarts und keine Budgetänderung. |

Der Gradle-Wrapper konnte in dieser Umgebung seine Distribution über Java nicht herunterladen (`Connection refused`). Die isolierten Kotlin-Tests verwendeten deshalb direkt die offiziellen Maven-Compiler-/Testartefakte in den oben genannten Versionen. Die gemeinsamen Tests bleiben im normalen Apple-Testquellsatz; nächster nativer Befehl: `./gradlew :shared:macosArm64Test --tests '*NetworkRangeRequestTest'`.

### Noch erforderliche Geräteabnahme

1. Neuer signierter PR-Build mit App- und Engine-Revision, zuerst mindestens zehn Minuten progressive YouTube-Wiedergabe.
2. Request-Abbruch vor/nach dem ersten Audiostück sowie WLAN-/Mobilfunkwechsel: Wiederholung begrenzt, echte Cancellation beendet den alten Job, keine falsche erfolgreiche Cachedatei.
3. Livetest bei Wiedergabe, Pause, Seek und bewusstem Favoritenfehler: aktuelles Intervall, Gesamtnachweis und Fehlerkategorie getrennt kontrollieren.
4. Bogen-Scrubber: Anfang/Ende, Abbruch, rasche Richtungswechsel, gesperrte Party-Steuerung, kleine Breite und große Schrift.
5. Reduce Motion, VoiceOver, Hintergrund und Audioausgabewechsel mit tatsächlich hörbarer Musik prüfen. Native Mini-Player-Scrollanimation und Suche zusätzlich gegenprüfen.

Die Abnahme bleibt BBT-022. Kein Merge nach `main`.

## Paket- und Reader-Korrektur vom 9. November 2026

Ausgangsstand: `06a835d11e218b9304942b128ca636161f991eb3`, weiterhin ausschließlich PR #59.

### Geräte-IPA und tatsächliche Laufzeitpfade

Der frühere Gerätebau erzeugte eine Debug-IPA, scheiterte dann aber mit `Binary fehlt: Payload/BitChord.app/Frameworks/BitChord.debug.dylib`. Eine Mach-O-Fixture mit `LC_RPATH=@executable_path` und einer Debug-Bibliothek neben dem App-Programm reproduzierte genau diese Meldung. Zwei weitere Gegenproben zeigten, dass fehlende `@loader_path`-/`@executable_path`-Bibliotheken gar nicht geprüft wurden (12 Fälle, zwei Fehlschläge und ein Fehler vor Korrektur).

`verify-ios-test-ipa.py` liest jetzt `LC_RPATH` und löst die paketbezogenen Ladepfade aus dem aktuellen Binary und seiner Ladekette auf. `@loader_path` wird dort ausgewertet, wo es deklariert wurde. Ein bloßes Suchen an zwei pauschalen Stellen ersetzt diese Zuordnung nicht. Verschachtelte Abhängigkeiten werden geprüft; Zyklen enden nach der ersten Prüfung desselben Binarys. Vorhandene System-/Swift-Laufzeit-Ausnahmen, Bundle-ID, Quellrevision, Gerätearchitektur, Verschlüsselungs- und Extension-Prüfungen bleiben erhalten. Das Kommandozeilenformat ändert sich nicht.

21 Paket-/Konfigurationsfälle bestehen: Debug-Bibliothek im App-Verzeichnis, korrekte und fehlende Laufzeitpfade, vererbte und eigene Framework-Suchpfade, fehlende transitive Bibliothek, Simulator-/verschlüsselte Bibliothek, Zyklus, Systemlaufzeit, Paketgrenzen und defektes `LC_RPATH`. Die Fixture-Prüfung ist nun auch im normalen PR-Repository-Job eingebunden. Sie beweist weder eine gültige Signatur noch einen erfolgreichen App-Start.

### Fehlgeschlagene progressive Downloads

Der Downloader setzt `.failed` und anschließend `.complete`, um einen blockierten Leser freizugeben. Der Reader prüfte `.failed` bisher nicht. Im laufenden Read konnte das zu normalem EOF führen; ein erneutes Öffnen fiel wegen `.complete` auf eine gewöhnliche Datei zurück und umging den progressiven Reader vollständig.

- Fehlgeschlagene/abgebrochene Transfers werden beim Öffnen sowie im Reader geprüft. Für normale lokale Dateien greift die zusätzliche Öffnungsprüfung nur bei vorhandenem `.grow`-Marker.
- `.failed` liefert `ConnectionAborted`, statt einen regulären Titelabschluss zu signalisieren. Der vorhandene Decoder-/Recovery-Weg erhält den Fehler; Mixer, Queue, Ausgabe und FFI bleiben unverändert.
- Ein leerer `Read::read`-Puffer liefert sofort `Ok(0)`. Die bisherige Implementierung konnte dabei auf Download-Bytes warten.
- Eine regulär abgeschlossene Datei liefert weiterhin ihre vollständigen Bytes und normales EOF. Die vorhandene nicht blockierende Analyse und die Abbruchprüfung des progressiven Readers bestehen weiterhin.

Vier neue Regressionen scheiterten vor der Korrektur: Fehler als EOF, verbliebene Teilbytes nach Fehler, erneutes Probe einer fehlgeschlagenen Datei und blockierende leere Leseanfrage. Danach bestehen alle 32 Decoderfälle. Dies erklärt eine konkrete fehlerhafte Behandlung von Download-Abbrüchen, belegt aber noch nicht die Ursache jeder gemeldeten WebM-/128-KiB-Störung.

### Lokaler Prüfstand und offene Grenze

Linux x86_64, Rust/Cargo 1.99.1, unverändertes `Cargo.lock`. CMake und ALSA-Entwicklungsdateien wurden ausschließlich in benutzereigenen Werkzeugverzeichnissen eingerichtet; die Projektabhängigkeiten bleiben unverändert.

| Befehl / Bereich | Tatsächliches Ergebnis |
| --- | --- |
| `python3 scripts/ios-test-verify/check.py` | **BESTANDEN: 21 Tests**. Künstliche Mach-O-/IPA-Pakete, keine erzeugte App. |
| `cargo test --locked --manifest-path native-core/Cargo.toml decode:: -- --test-threads=2` | **BESTANDEN: 32 Tests**, vorher 28 bestanden / 4 fehlgeschlagen. Echter Produktionsdecoder mit generierten Audiodaten. |
| `cargo test --locked --manifest-path native-core/Cargo.toml` | Ausgeführt: **316 bestanden, 4 fehlgeschlagen, 1 ignoriert**. Drei Swap-Fehler waren `StorageFull`; nach Bereinigung temporärer eigener Werkzeugdateien alle drei gezielt erneut bestanden. Der verbleibende AAC-Regionenfehler steht unten. Die Gesamtreihe wird nicht als grün ausgegeben. |
| AAC-Baseline | `mixer::tests::regions::aac_region_cuts_advance_without_reseeking_preroll` scheitert auch mit den unveränderten Decoder-Produktionsdateien aus `06a835d`: identisch `113624 frames`, anschließend `Disconnected`. Finale Decoderdateien danach wiederhergestellt. AAC-Test und Toleranz bleiben unverändert. |
| Apple-Verknüpfung / Hardware | **NICHT GETESTET**: `check-engine.sh`, Xcode-/Simulator-Build, neue echte IPA, SideStore, hörbare Recovery, Hintergrund und Ausgabewechsel. Linux-Tests ersetzen diese Nachweise nicht. |

Der erste Gesamtlauf scheiterte bereits beim Linken wegen lokalem Platzmangel. Nach Entfernen des selbst heruntergeladenen Compilerarchivs lief die Testreihe; weiteren Platzmangel in den drei Swap-Fixtures haben die gezielten Wiederholungen abgegrenzt. Der verbleibende AAC-Befund ist unabhängig vom neuen Reader auf dem Ausgangsstand belegt (P-021), seine Linux-/Apple-Ursache ist noch offen.

Für BBT-023: Nach verfügbarer Apple-Kapazität dieselbe PR-Revision bauen, das echte Paket mit den neuen Laufzeitpfaden prüfen und Download-Abbruch, begrenzte Wiederherstellung, natürlichen Titelabschluss sowie Datenbestand am iPhone nachweisen. Keine privaten Anhänge übernommen und kein Merge nach `main`.

## Home-Kopfzeile und gemischte Regale vom 9. November 2026

Der Nutzer meldete anhand von drei Home-Fotos ein unruhiges Layout und benannte den Apple-Port [bagumamartin/BitChord](https://github.com/bagumamartin/BitChord) als Referenz. Die Fotos stammen laut Nutzer von einer älteren PR-59-IPA. Die angezeigte Version `1.0.4 (build 13)` identifiziert keinen bestimmten PR-Commit; die About-Aufnahme enthält keine Quellrevision. Die Fotos sind keine Abnahme des neuen Codes.

Der Quellvergleich zeigt zwei konkrete Unterschiede: Der Apple-Port zeichnet keinen zusätzlichen Logo-Player über die Kopfzeile und verwendet quadratische Regalkarten. RED Bit öffnete seine zusätzliche Logo-Steuerung beim Wiedergabestart und beim Hochscrollen; gleichzeitig konnten innerhalb einer Reihe quadratische Cover neben 16:9-Videos stehen. Damit hatten Titel derselben Reihe unterschiedliche Höhen und die obere Steuerung konnte Seitentitel überdecken.

Korrektur ausschließlich auf PR #59:

- Logo-Steuerung öffnet nur durch bewussten Tipp/Halten am Logo. Titelwechsel halten eine bereits geöffnete Steuerung kurz offen; beide Scrollrichtungen schließen sie. Der Spark beginnt weiter am Logo, lesbare kompakte/erweiterte Zustände liegen unterhalb der Toolbar.
- Ein Regal erhält eine gemeinsame Bildform: gemischte und reine Audio-Regale quadratisch, reine Video-Regale 16:9. Die Inhalte, Video-Wiedergabe und Trefferaktionen bleiben erhalten.
- Home und Explore fordern den sichtbaren systemeigenen Navigationshintergrund an. Kein eigener Glaslayer wird hinzugefügt. Die native untere Tab-/Mini-Player-Minimierung und der Zoom bleiben erhalten.
- About zeigt die eingebettete Build-Revision zusätzlich zur unveränderten Versionsnummer, damit verschiedene PR-Pakete unterscheidbar werden.

`SWIFTC=…/swiftc bash scripts/check-phone-layout.sh` verwendet den tatsächlichen Präsentationskoordinator mit kontrollierten Animations-/UIKit-Adaptern. Vor der Änderung scheiterte er an der ungefragten Playeröffnung beim Wiedergabestart. Danach bestehen automatische Ruhe, bewusster Tipp/Halten, erweiterter Zustand bei Titelwechsel und Abbruch durch beide Scrollrichtungen. Swift-Syntax, Workflow-YAML und vorhandene RED-Morph-/Now-Playing-Quellprüfungen bestehen. Diese Nachweise prüfen keine Pixel, native Materialdarstellung oder Animation.

**NICHT GETESTET:** Apple-SDK-Typprüfung, Simulator, neue IPA, tatsächliches iPhone-Layout, Dynamic Type/VoiceOver und hörbare Wiedergabe. BBT-025 verlangt Home/Explore bei Abwärts-/Aufwärtsscrollen, sofortiger Umkehr, Logo-Tipp, Titelwechsel, gemischten/reinen Videoregalen und geöffneter Tastatur. Neue Screenshots müssen die eingebettete Build-Revision nennen. Das Actions-Budget war zuletzt ausgeschöpft; kein manueller Neustart und keine Budgetänderung.

## Persönlicher Home-Bereich vom 9. November 2026

Auftrag „Bau alles“, Ausgangsstand `64dcf17cee48ae6301e99c8da1475a810b90f7f6`, ausschließlich PR #59. Die fünf zuvor recherchierten Ideen werden nativ auf die vorhandenen Daten und Aktionen gesetzt.

| Funktion | Tatsächliches Verhalten |
| --- | --- |
| Persönliche Karten | Große Fortsetzen-Karte nutzt dieselbe Wiedergabesitzung. Bei laufendem Titel öffnet sie den Vollplayer; bei Pause setzt sie fort. Ohne Sitzung startet sie auf Wunsch den vorhandenen Mix oder führt zum Entdecken. Zwei kleine Karten zeigen höchstens zwei vorhandene Playlist-Pins, sonst echte Feed-Sammlungen oder ehrliche Bibliotheks-/Entdecken-Zugriffe. Bei großer Bedienungshilfen-Schrift stehen die Bereiche untereinander. |
| Album-Vorschau | Langes Drücken zeigt die ersten drei tatsächlichen Titel, Titel-/Künstlerangaben und vorhandene Sammlungsaktionen. Ein sichtbares 44-Punkt-Aktionsmenü öffnet dieselbe Vorschau als Sheet. Laden, Fehler, Wiederholung und gespeicherte Offline-Sammlung sind berücksichtigt; die Vorschau startet keine Wiedergabe. |
| Tagesmix | Morgen-, Tages-, Abend- oder Nachtmix aus dem echten lokalen Hörverlauf und bereits geladenen Feed-Titeln. „Vertraut“ bevorzugt bekannte Titel, „Gemischt“ verschränkt beide Quellen, „Neugierig“ zeigt neue Feed-Titel. Keine behauptete Audio-/Stimmungsanalyse. Auswahl innerhalb derselben Tagesphase stabil; IDs und normalisierte Titel-/Künstlerpaare werden dedupliziert, bekannte Videos ausgeschlossen. Die geöffnete Titelliste bleibt ein Snapshot. |
| Cover zur Queue | Karten übertragen nur eine prozessinterne Einmal-Kennung mit zwei Minuten Lebensdauer. Drop auf die bestehende Playback-Pill fügt als Nächstes ein. Sammlungen werden einschließlich höchstens 20 Folgeseiten und insgesamt höchstens 500 Titeln vollständig geladen; Fehler, Schleifen und Überschreitung fügen keinen Teil ein. Ein explizites „Als Nächstes“ im Sammlungsmenü bietet dieselbe Aktion ohne Drag. |
| Medienfilter | „Alle“, „Musik“, „Videos“ filtern die geladenen Home-Regale. Vorhandene Einstellungen zum Ausblenden von Videos/Recents bleiben vorrangig. Bei leerem Filter höchstens drei Seiten automatisch nachladen, dann bewusster Ladebutton. Ausgeblendete Videos lösen keine nutzlosen Ladeversuche aus. |

### Queue, Daten und Navigation

`QueueNextAction` verwendet die bestehende `PlaybackController.playNext`-Batch-Aktion. Die laufende Wiedergabe wird bei nicht leerer Queue nicht neu geladen. Vor und nach asynchronem Laden werden Kontogeneration, Wiedergabegeneration, aktueller Titel und Queue-Revision verglichen. Cancellation oder Beitritt zu „Gemeinsam hören“ verhindert die Mutation. Der Party-Modus nutzt weiterhin seinen vorhandenen gemeinsamen Steuerungsweg. Die Einreihbestätigung mit Cover erscheint erst nach der tatsächlichen Queue-Mutation, ohne Wiedergabe-/Decoder-Erfolg vorzutäuschen.

Die nativen Tab-/Bottom-Accessory-Montagepunkte, Scroll-Minimierung, Vollplayer-Zoom und Suchnavigation werden weiter verwendet. Keine zusätzliche dauerhafte Glasfläche oder Animationsschleife; die kurze Drop-Bestätigung berücksichtigt reduzierte Bewegung. Große Schrift erhält einen vertikalen Kartenaufbau, Vorschau und Einreihen bleiben ohne langes Drücken erreichbar.

Keine Änderung vorhandener Datenformate und keine Migration erforderlich. Zwei neue additive `UserDefaults`-Schlüssel merken Medienfilter und Mixmodus. Bestehende Pins bleiben bis zur bisherigen Grenze von fünf erhalten; Home zeigt nur die ersten zwei. Der neue UTType kennzeichnet ausschließlich kurzlebige lokale Tickets; keine lokalen Pfade, Stream-URLs, Kontodaten oder Mediendateien werden exportiert. Keine neue Netzwerkquelle, Laufzeitbibliothek oder Modellinferenz. [Herkunft](../FREMDCODE.md) dokumentiert die reinen Ideenreferenzen.

### Lokaler Nachweis und Grenze

Linux x86_64, Swift 6.2.1. `SWIFTC=/pfad/zu/swiftc bash scripts/check-home-discovery.sh` typprüft die tatsächlichen Foundation-Produktionsdateien sowie beide tatsächlichen Observation-Modelle mit kontrollierten Dienstadaptern. Der Laufzeittest nutzt dieselben Modelle ohne Observation-Anbindung und die unverändert extrahierte Produktionsmethode `playNext`. Er prüft deterministische Mixe, Filter, Deduplikation, drei Preview-Titel, Pin-Fehler, Einmaltickets, Kontowechsel, Abbruch, Party-Wechsel, Queue-/Playback-Änderung, Offline-Sammlung, vollständige Mehrseiten-Reihenfolge und atomare Fehlerfälle. Diese Prüfung ist im vorhandenen PR-Regressionsjob eingebunden.

Swift-Syntaxprüfung der geänderten/neuen Swift-Dateien, Repository-/Release-/Deutsch-Prüfungen und die bestehenden RED-Morph-/Now-Playing-Quellinvarianten ergänzen den Nachweis. **Keine SwiftUI-/CoreTransferable-SDK-Typprüfung:** kontrollierte Adapter prüfen weder Apples Gestenerkennung noch das native Rendering.

| Ausgeführt am Implementierungsstand | Ergebnis |
| --- | --- |
| `SWIFTC=…/swiftc bash scripts/check-home-discovery.sh` | **BESTANDEN:** tatsächliche Auswahl-/Queue-/Modelllogik mit kontrollierten Netzwerk-, Speicher- und Engineadaptern, einschließlich der oben genannten asynchronen Grenzen. |
| `SWIFTC=…/swiftc bash scripts/check-phone-layout.sh` | **BESTANDEN:** Produktionskoordinator bleibt ohne ungefragten Zweitplayer; Logo-Bedienung und Scroll-Abbruch. |
| `SWIFTC=…/swiftc bash scripts/check-original-parity.sh` | **BESTANDEN:** Seeds, Playlist-Journal, gemessene Bänder, Vorschau, Update-Identität und neun asynchrone Playlist-Fälle. |
| Queue-Fixtures aus `scripts/queue-verify/main.swift` direkt mit `QueueEntry`, `PlaybackQueuePolicy`, `PlaybackQueueWindow` und `LastPlayed` kompiliert/ausgeführt | **BESTANDEN: 113 Fälle** für Queue, Empfehlungen, Reihenfolge und Wiederherstellung. Linux-Swift direkt statt des Apple-`xcrun`-Aufrufs. |
| `swiftc -frontend -parse` für alle zwölf geänderten/neuen Swift-Produktionsdateien | **BESTANDEN:** Syntax; kein App-Build. |
| `python3 scripts/check-repository.py --base b571aab`, `scripts/repository-verify/check.py`, `scripts/release-verify/check.py`, `scripts/verify-settings-german.py` | **BESTANDEN:** Repo-/Release-Grenzen, sieben Gegenproben und deutsche Einstellungen. 56 neue deutsche Katalogeinträge ergänzt; vorhandene Übersetzungen erhalten. |
| `scripts/check-red-morph-source.py`, `scripts/check-native-island-source.py`, YAML-Parse und `git diff --check` | **BESTANDEN:** je acht Quellinvarianten, gültige Projekt-/Workflow-Dateien und sauberer Diff. |

**NICHT GETESTET:** vollständiger Apple-/Kotlin-Native-Build, Simulator, neue signierte IPA, iPhone/iPad/Mac-Darstellung, echte Drag-/Kontextmenü-Gesten, VoiceOver, GPU-Leistung, native Dock-Animation und hörbare Wiedergabe. Keine manuelle CI-Neuausführung oder Budgetänderung.

### Geräteabnahme BBT-026

1. Dieselbe PR-Revision frisch bauen und unter About kontrollieren. Home mit laufender, pausierter und leerer Sitzung öffnen: richtige Fortsetzen-Aktion, kein zweiter automatisch geöffneter Logo-Player.
2. Zwei Pins, ein Pin und keine Pins mit echten Kontodaten prüfen; offline/abgemeldet, Feedfehler und Kontowechsel dürfen keine fremden Titel oder erfundenen Sammlungen zeigen. Bestehende Pins und Downloads nach Update erhalten.
3. Album lange drücken sowie sichtbares Aktionsmenü öffnen: drei Titel entsprechen der Detailseite, Fehler/Wiederholung funktionieren, reine Vorschau startet keinen Titel. Mit VoiceOver und auf Mac ohne langes Drücken bedienen.
4. Tageszeit und alle drei Modi mit/ohne Verlauf prüfen. Geöffnete Mixliste bleibt beim Zeit-/Feedwechsel stabil; Start/Zeilen-Tipp ersetzen die Queue nur bewusst. Alle/Musik/Videos, ausgeblendete Videos und weitere Seiten kontrollieren.
5. Titel und mehrseitige Sammlung auf die Playback-Pill ziehen: richtige Reihenfolge direkt nach dem aktuellen Titel, Bestätigung erst nach Einfügen, kein Neustart des laufenden Audios. Netzfehler, Drop-Abbruch, rascher zweiter Drop, Konto-/Titel-/Queue-Wechsel und Party-Beitritt während Laden prüfen. Doppelte Tickets und externe Drops bleiben wirkungslos.
6. Kleine iPhone-Breite, große Schrift, hell/dunkel und reduzierte Bewegung prüfen. Abwärts-/Aufwärtsscrollen einschließlich sofortiger Umkehr, Such-Tastatur, Dock-Minimierung und Zoom zum Vollplayer müssen erhalten sein. Hörbares Audio getrennt bestätigen; Screenshots nennen die Build-Revision.

## Zuverlässiges Nachladen vom 9. November 2026

Fortsetzung auf PR #59 nach `9f40a26`, Befund P-024. Der bisherige `FeedLoader` verwarf eine ganze nachgeladene Zeile, sobald deren Titel schon vorhanden war. Deshalb verschwanden auch zusätzliche Titel und Videos, die der neue Medienfilter hätte zeigen müssen. Gleichzeitig waren Folgeseiten bereits während des progressiven Erstladens erreichbar: Ein späterer erster Snapshot konnte nachgeladene Inhalte wieder ersetzen. `loadingMore` war nicht einer Anfrage zugeordnet; ein alter Kontorequest konnte neue Seiten blockieren oder deren Spinner beenden. Ein erfolgreicher leerer Feed beendete `.loading` nicht.

`FeedShelfMerge` erweitert nun die bestehende Zeile an derselben Position. Karten werden anhand der vorhandenen `ShelfCard.id` pro Zeile dedupliziert; neue Zeilen behalten ihre Reihenfolge und derselbe Musiktitel darf in unterschiedlichen Regalen stehen. Vorhandene Untertitel bleiben erhalten. Die Regal-/Kartenidentität und Datenformate ändern sich nicht; keine Migration, neue Abhängigkeit oder zusätzliche Datenquelle.

Folgeseiten sind erst nach vollständig beendetem Erstladen verfügbar. Jede Paging-Anfrage besitzt ihren eigenen Abschlusszustand. Ein neuer Feed-Request setzt den alten Paging-Zustand zurück; verspätete Antworten/Fehler werden anhand der bestehenden Request- und Kontogeneration verworfen. Der alte Abschluss darf keinen neuen Spinner zurücksetzen. Netzwerkfehler erhalten sichtbare Inhalte und ermöglichen Wiederholung, die den alten Fehler löscht. Eine erfolgreiche leere Antwort wird als leerer Inhalt dargestellt.

Home erhält unten auch bei bereits sichtbaren Regalen einen expliziten „Weitere Inhalte laden“-Button. Dadurch bleibt Paging erreichbar, wenn die letzte Zeile schon während des Erstladens sichtbar war. Der vorhandene begrenzte Drei-Seiten-Versuch für einen leeren Medienfilter reagiert zusätzlich auf die tatsächliche Ladebereitschaft und die Recents-Einstellung. Keine Änderung an Audio, Wiedergabesitzung, nativer Suche, Dock-Montage oder Zoom. Der Button verwendet den vorhandenen deutschen Katalogeintrag.

### Tatsächlich ausgeführter Nachweis

`SWIFTC=…/swiftc bash scripts/check-feed-loading.sh`, Linux x86_64 / Swift 6.2.1: Der tatsächliche vollständige `FeedLoader`, `FeedShelfMerge` und die tatsächlichen Feedmodelle werden mit kontrollierten Konto-/Netzwerk-/Readiness-Diensten typgeprüft, einschließlich Observation-Makros. Der Laufzeittest entfernt ausschließlich Observation-Anbindung; Anfrageablauf, Merge und Zustände bleiben Produktionscode. Kontrollierte Streams und Antworten bestimmen die Reihenfolge ohne echte Konten, HTTP oder private Daten. Ein Zeitlimit beendet unerwartet hängende Fixtures.

Vor der Produktionskorrektur: **12 Prüfungen, 4 bestanden, 8 fehlgeschlagen**. Nach Korrektur einschließlich zusätzlicher Abbruch-/Refresh-Fälle: **17 bestanden, 0 fehlgeschlagen**. Abgedeckt: paralleles Erstladen, sichtbare Folgeseite, gleiche Regaltitel, neue Videos, Kartenduplikate, Reihenfolge, Fehler und Wiederholung, alter/neuer Kontorequest, Spinnerbesitz, Cancellation, leerer Feed sowie verspäteter Fehler nach Pull-to-refresh im selben Konto. Die Prüfung läuft zusätzlich im bestehenden PR-Regressionsjob.

Die bestehenden Home-/Queue-/Vorschauprüfungen, der Produktionskoordinator ohne ungefragten Zweitplayer sowie Repository-/Release-/Deutsch-, Syntax- und RED-Morph-/Now-Playing-Quellprüfungen ergänzen den lokalen Nachweis. **NICHT GETESTET:** vollständige Apple-SDK-Kompilierung, reale SwiftUI-Darstellung, native Gesten, echte Konten/Netzwerk, signierte IPA und hörbares Audio. GitHub Actions war zuletzt durch das Budget gesperrt; keine manuelle Neuausführung oder Budgetänderung.

BBT-027 verlangt auf Home langsames progressives Erstladen, eine Folgeseite mit zusätzlichem Video im gleichnamigen Regal, leeren Feed, Fehler/Wiederholen und Konto-/Pull-to-refresh-Wechsel während einer laufenden Folgeseite. Zusätzlich Ladebutton, Video-/Recents-Einstellungen und große Schrift prüfen; Dock-Minimierung und Zoom weiterhin mit laufender Musik testen. Jede Geräteaufnahme nennt ihre Build-Revision.
