# BBT-Bit: iPhone-Selbsttest und echte XCUITest-Automation

## 1. Ohne Mac: direkt in der installierten BBT-Bit-App

Voraussetzung: die **signierte** Testversion aus dem Branch
feature/iphone-ui-selftest-20261103 ist auf dem iPhone installiert.

Einstellungen → Your Data & Backup → iPhone-Selbsttest
→ **Alle 15 Designs prüfen** → **JSON-Testbericht teilen**.

Der Bericht heißt BBT-Bit-iPhone-Testbericht.json. Er enthält für jede der 15
Liquid-Motion-Änderungen Name, Einbauort, Renderstatus und PNG-Größe.
Die Ansicht bietet außerdem antippbare Einträge für die 15 Vorschauen.

**Wichtig:** Das ist ein Offline-Rendering-Smoke-Test der Beispielansichten.
Er testet weder echte Streaming-Wiedergabe, Login, Downloads,
Automix-Songübergänge, Handoff, Geräteausgabe noch Party-Synchronisation.
Es werden keine persönlichen Songs, Fotos oder Zugangsdaten gelesen.
Ein PNG-Render-Erfolg ist kein vollständiger Funktionstest.

## 1b. RED Bit Testzentrale – produktive App im Alltag prüfen

PR #59: **Einstellungen → Tests & Diagnose → RED Bit Testzentrale**.
Es gibt keine manuellen Bewertungsfelder. Der Nutzer startet den Lauf, nutzt die
App normal und wählt anschließend **Beenden und speichern**. **In Dateien sichern**
und Teilen exportieren den aktuellen Bericht; gespeicherte Läufe bleiben im Archiv.

### Automatische Prüfungen

Der vorhandene Monitor bewertet 33 klar benannte Softwareprüfungen anhand echter
Zustände und Ereignisse. Fortschritt, Queue, Decoder, Ausgabestream, aktive
Audiositzung, Fehler und Netzwerkstatus werden aus derselben PlaybackSession
gelesen. Pause/Fortsetzen, Titelwechsel, lokale Wiedergabe, abgeschlossene neue
Downloads, Lyricsdaten, Hintergrundfortschritt und Fortschritt nach einem
Routenwechsel werden erkannt, sobald sie auftreten.

Home-/Paging-Antworten, Suchantworten, Album-Vorschau, Übernahme des Tagesmixes,
Einreihen und erfolgreicher Cover-Drop liefern Nachweise an ihren tatsächlichen
Erfolgs-/Fehlerpfaden. Bibliothek, Einstellungen und Vollplayer bestätigen ihre
Anzeige über den View-Lebenszyklus. Die Inline-Prüfung verlangt die tatsächliche
native Bottom-Accessory-Pill, nicht die separate Tastaturdarstellung. Der
Party-Nachweis prüft lokalen Track-/Transport-/Zeitabgleich zum Serverzustand;
er behauptet keine physisch synchrone Wiedergabe mehrerer Geräte.

Vorhandene Modell-Dateien werden beim Start automatisch mit einer rein lesenden
Größen-/SHA-256-Prüfung geprüft. Sie kompiliert, repariert oder entfernt keine Datei;
anders als die bisherige Installer-Prüfung ändert sie auch keine Modell-Einträge.
Die Berechnung läuft außerhalb des Main Actors und lässt sich abbrechen.
Optionale fehlende oder vorübergehend nicht lesbare Modelle erhalten „Nicht verfügbar“;
es werden keine Modelle heruntergeladen. Bei laufenden Downloads oder später
verfügbaren Dateien wird nach 30 Messpunkten erneut geprüft. Auf iOS rendert der
vorhandene Vorschauweg zusätzlich alle 15 gekennzeichneten Beispielkarten. Nur
wenn alle PNGs die Größen-/Byteprüfung bestehen, ist diese Prüfung erfolgreich.
Der Renderer wartet im Hintergrund auf die Rückkehr in den Vordergrund und
beendet sich bei Testabbruch. Die PNGs werden nicht als private App-Screenshots
exportiert. macOS/ältere Systeme kennzeichnen nicht verfügbare iPhone-Prüfungen.

**Nicht beobachtet**, **Beobachtet – Prüfung offen**, **Automatisch geprüft**,
**Fehler beobachtet** und **Nicht verfügbar** sind getrennte Zustände. Nicht
verwendete Funktionen werden nicht pauschal grün. Ein Fehler bleibt im Bericht,
auch wenn später eine Wiederholung gelingt. Neue Ereignisse alter asynchroner
Anfragen dürfen keinen neuen Testlauf bewerten. Der Export enthält nur feste
Prüf-/Ergebniscodes, Zähler und Zeitpunkte; keine Song-IDs, Suchtexte, Pfade,
Zugangsdaten oder privaten Fehlertexte.

### Speichern und Kompatibilität

Automatische Ergebnisse ersetzen die früheren Handbewertungen. Neue Berichte
verwenden **JSON v5**, mit `automaticChecks` und automatischen Summen; sie enthalten
keine `manualChecks` oder manuell gesetzten Urteile. Vorhandene v4-Dateien werden
weiter unverändert gelesen und als ältere Berichte angezeigt. Ihre ursprünglichen
Bewertungen bleiben in der exportierbaren Originaldatei; sie werden niemals als
automatische Nachweise umgedeutet.

Zwischenstände und Abschluss bleiben atomar je UUID unter Application Support in
`RED-Bit/Testberichte`. Ein neuer Lauf verwirft bei Schreibfehlern keinen alten.
30-Messpunkt-/Hintergrundspeicherung, maximal 1800 Messpunkte, Unterbrechungsstatus
nach Neustart und eindeutiger Dateiexport bleiben bestehen. Der Monitor verändert
keine Queue, Lautstärke, Konten oder Downloads. Fehler-/Statusübergänge werden
zusätzlich gesichert. Hintergrundausführung bleibt vom OS abhängig.

Automatische Softwarewerte bestätigen keine physische Hörbarkeit oder vollständige
Bildschirmqualität. Die PNG-Prüfung bestätigt Renderbarkeit, kein Durchklicken
sämtlicher Oberflächen. Dafür gibt es im App-Bericht keine manuelle Bewertung.

### Tatsächliche Nachweise

Linux / Swift 6.2.1: `SWIFTC=…/swiftc bash scripts/check-automix-live-test.sh`
verwendet Produktionsmonitor, Ereignisregister und Archiv einschließlich
Observation-Typprüfung. Kontrollierte Laufzeittests prüfen automatische Bewertung,
fehlende Nachweise, bleibende Fehler, alte Ereignisse nach Neustart, automatischen
Modellstart, fehlende optionale Dateien ohne Download, JSON v5, Datenschutz,
Erhalt von v4, Archiv-/Schreibfehler und die 1800-Punkte-Grenze. Home-/Queue- und
17 Feed-Regressionsfälle verwenden dieselben instrumentierten Produktionspfade.
`bash scripts/check-test-model-integrity.sh` prüft auf Apple mit echtem CryptoKit
die Produktionsfunktion an korrektem Inhalt, falscher Größe, falschem Hash und
fehlender Datei. Dabei dürfen weder Dateien gelöscht noch Zusatzdateien erzeugt
werden. Dieser zusätzliche native Nachweis wird im PR-Job ausgeführt.

Apple-SDK-/Simulator-/iPhone-Ergebnisse werden für die neue Revision separat
festgehalten. BBT-028 hält die Abnahme von automatischen Modell-/PNG-Prüfungen,
Dateiexport, Lifecycle und tatsächlicher Nutzung auf Apple offen.

## 2. Echte automatische Fingertipps auf deinem iPhone

Benötigt:
- Einen Mac mit Xcode 26, XcodeGen, Python 3 und ZIP.
- Einen gültigen Apple-Developer-Account bzw. signierbare Test-App.
- Ein mit dem Mac verbundenes, entsperrtes, vertrauenswürdiges iPhone.
- Developer Mode aktiviert und das Entwicklerteam in Xcode konfiguriert.
- Die nativen Kotlin/Native- und Rust-Frameworks im AppleApp/Frameworks-Ordner.
- Den Branch feature/iphone-ui-selftest-20261103.

Auf dem Mac im BBT-Bit-Repository:

    CONFIG=release ./scripts/build-shared-framework.sh
    ./scripts/build-native-core.sh
    xcrun xctrace list devices
    BBT_APPLE_TEAM_ID=<TEAM_ID> bash scripts/run-iphone-ui-tests.sh <IPHONE_UDID>

Das Skript führt xcodegen generate aus, startet xcodebuild test auf dem
physischen Gerät und erzeugt:
- BBT-Bit-iPhone-Testbericht.json (Teststatus mit Xcode-Ergebnissen)
- xcresult-summary.json und xcresult-tests.json (strukturierte Testergebnisse)
- screenshots/ (UI-Test-Anhänge)
- xcodebuild.log (Build- und Testprotokoll)
- BBT-Bit-iPhone-Tests.zip (die wichtigsten Ergebnisdateien)
- BBT-Bit-UI.xcresult (vollständiges Apple-Test-Result-Bundle)

Die XCUI-Teststrecke öffnet den Self-Test-Diagnosebildschirm über einen
nur in DEBUG verfügbaren Startparameter, führt die 15 Renderprüfungen aus,
öffnet alle 15 Vorschauansichten nacheinander, bedient mehrere
repräsentative SwiftUI-Komponenten und zeichnet Screenshots auf.
Sie **navigiert nicht automatisch durch Login, Netzwerkwiedergabe oder
alle produktiven App-Seiten**. Diese End-to-End-Fälle benötigen eigene
Tests und kontrollierte Testkonten.

## Testbericht interpretieren

Ein pass in der iPhone-App heißt: eine Design-Vorschau ließ sich als PNG
rendern. Ein pass in Xcode heißt: die definierte UI-Teststrecke wurde auf
dem ausgewählten Gerät erfolgreich abgespielt. **Keiner der beiden
Berichte bedeutet, dass alle Funktionen der App fehlerfrei sind.**

Wenn Xcode wegen Code-Signing scheitert, wurde noch kein iPhone-UI-Test
durchgeführt. Bei einem fehlgeschlagenen Build oder einer App-Crash
bleibt der Test entsprechend failed-or-incomplete.

## Sicherheit

Keine Cloud-Fernsteuerung und keine unbeaufsichtigte Kontrolle über das
private iPhone aus dieser Chat-Sitzung. Alle Klicks werden durch den
lokalen XCUITest-Runner oder einen ausdrücklich verbundenen Gerätetest-
dienst ausgeführt. Die Nutzerin oder der Nutzer startet den Test.
Das Projekt wird nur auf einem Review-Branch geändert; kein Merge nach main.
