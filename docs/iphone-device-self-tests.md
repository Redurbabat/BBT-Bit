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

Auf PR #59 gibt es einen eigenen Bereich **Einstellungen → Tests & Diagnose**.
Die bisherigen Zugänge über Wiedergabe, Erweiterte Optionen und die Modellseite
bleiben nutzbar. Der Bereich enthält die Testzentrale, gespeicherte Berichte,
die vorhandene Streamdiagnose und auf iOS den separaten Design-Selbsttest.

1. **RED Bit Testzentrale → App-Test starten.** Der vorhandene Monitor zeichnet
   echte Zustände derselben PlaybackSession auf. Er startet keine Musik und
   verändert weder Queue noch Lautstärke. Ein erneuter Start während desselben
   Laufs verwirft keine Ergebnisse.
2. Einstellungen schließen und die App normal verwenden: Musik hören, suchen,
   Home-Filter/Mixe und Vorschauen bedienen, Cover einreihen, Bibliothek und
   Downloads öffnen. Bei Hintergrund/Sperre darf iOS die Ausführung pausieren;
   ein laufender Hintergrund-Timer wird nicht zugesichert.
3. Zur Testzentrale zurückkehren. Die **22 manuellen Bereiche** mit Offen,
   Bestanden oder Fehler bewerten. Dazu gehören nun auch Home-Karten,
   Album-Vorschau, Tagesmix, Cover-Drop, Feed-Paging, native Suche/Dock/Zoom,
   Lyrics-Sternbild und Einstellungen/Updates. Nur selbst ausgeführte Prüfungen
   markieren; hörbarer Ton bleibt eine manuelle Bestätigung.
4. Optional die drei Modell-Dateien erneut auf Bytezahl/SHA-256 prüfen. Ergebnis
   und Prüfzeit stehen im Bericht; installierte Datei, geladene Runtime und
   nachgewiesene Inferenz bleiben getrennte Angaben.
5. **Beenden und speichern.** Der abgeschlossene Bericht bleibt dauerhaft im
   App-Speicher. **In Dateien sichern** öffnet den System-Dateiexport;
   **Testbericht teilen** öffnet ausschließlich auf Wunsch die Freigabe.
   Nachträgliche Handbewertungen werden ebenfalls gesichert. Der Dateiexport
   erfasst ihren aktuellen Stand beim Tippen und hält ihn während des Dialogs fest.
6. Später **Einstellungen → Tests & Diagnose → Gespeicherte Testberichte**
   öffnen. Datum, Status, Messpunkte, manuelle Ergebnisse und Build-Revision
   helfen beim Zuordnen. Jeder Lauf hat eine eigene Datei.

Zwischenstände werden alle 30 Messpunkte, bei manuellen Ergebnissen,
Modellprüfungen sowie beim Hintergrundwechsel eines laufenden Tests atomar
gesichert. Die Aufzeichnung ist auf 1800 Messpunkte begrenzt und beendet sich
beim ausgeführten Monitor nach 30 Minuten. Wird die App vorher beendet, erscheint
nach Neustart der letzte Stand als **Unterbrochen**, mit unverändertem
Speicherzeitpunkt und ohne erfundenes Abschlussdatum. Neue Tests ersetzen nur
ihren eigenen Zwischenstand. Schreibfehler bleiben sichtbar; ein ungesicherter
vorheriger Lauf wird beim Start eines neuen Tests nicht verworfen.

Neue JSON-Berichte verwenden **Version 4**: bisherige Messfelder plus
Sitzungszusammenfassung, tatsächliches optionales Abschlussdatum und
Modell-Prüfsummenresultate. Bereits exportierte v3-Dateien bleiben erhalten;
das neue interne Archiv beginnt mit v4. Es liegt unter Application Support
in `RED-Bit/Testberichte`. Es enthält keine Songtitel, YouTube-IDs, Pfade,
Stream-URLs oder Zugangsdaten. Defekte/unerwartete Dateien bleiben erhalten
und werden in der Archivansicht als nicht lesbar gezählt. Keine Übertragung
oder automatische Löschung; keine neue Bibliothek und keine Migration von
Anmeldung, Musik, Downloads oder Einstellungen.

**Lokaler Nachweis, Linux/Swift 6.2.1:**
`SWIFTC=…/swiftc bash scripts/check-automix-live-test.sh` typprüft den tatsächlichen
Monitor und Archivspeicher einschließlich Observation mit kontrollierten
Player-/Modelladaptern. Laufzeittests ohne Linux-Observation-Anbindung prüfen
Messung/Fehlertrennung, JSON v4, Datenschutz, 22 Bereiche, Modellprüfungen,
persistente Wiederöffnung, mehrere Sitzungen, Doppeltstart, Wiederherstellung
unterbrochener Läufe, defekte Dateien, Schreibfehler und das 1800-Punkte-Limit.
Vorhandene Fortschrittstests prüfen Pause, Seek, Stillstand und Titelwechsel.

**NICHT GETESTET:** Apple-SDK-Typprüfung der neuen UI, Datei-Dialog/Teilen,
VoiceOver/große Schrift, native Gesten, echte Hintergrundausführung,
physischer Ton, signierte IPA und Gerät. Die Abnahme bleibt BBT-028.

Die vorhandene Design-Prüfung auf `afef572` scheiterte im
[Simulator-/Mac-Lauf](https://github.com/Redurbabat/RED-Bit/actions/runs/42721105354):
Lyrics-Textknoten nach Umschalten nicht gefunden; die gemeinsam verwendete
Beispiel-Markierung war nur für iOS definiert. P-027 verschiebt die Markierung
in den gemeinsamen SwiftUI-Bereich und prüft die tatsächlich aktuelle Lyrics-Zeile
über ihren Accessibility-Wert mit Wartebedingung. Diese Korrekturen erhalten die
bestehende Design-Prüfung; ihr erneuter nativer Nachweis bleibt separat offen.

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
