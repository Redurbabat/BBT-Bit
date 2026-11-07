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

## 1b. BBT-Bit Testzentrale – produktive App im Alltag prüfen

Zusätzlich zum reinen Design-Selbsttest besitzt die BitChord-v1.9.1-Portierungsbranche
`feature/bitchord-v1-9-1-port-20261106` die **BBT-Bit Testzentrale**:
`Einstellungen → Wiedergabe → Erweiterte Automix-Optionen → BBT-Bit Testzentrale`
oder `Automix Models → BBT-Bit Testzentrale öffnen`.

- Bis zu 30 Minuten **echte** Player-Zustände während der normalen App-Nutzung
  aufzeichnen, ohne die Queue zu ersetzen oder künstliche Testtöne abzuspielen.
- Die drei optionalen Modelle einschließlich Bytezahl und SHA-256 prüfen;
  die tatsächliche Rust-/Core-ML-/Open-Unmix-Verwendung bei **neuen**
  Automix-Planungen erkennen.
- Decoder, Queue, Netzwerk, Ausgabestream, Audio-Session und Fehlerindikatoren
  einsehen. 14 manuelle Bereiche selbst mit `Offen`/`Bestanden`/`Fehler` bewerten.
- Einen **lokalen JSON-Bericht** speichern und nur auf eigenen Wunsch teilen.
  Er enthält keine Songtitel, YouTube-IDs, Stream-URLs oder Zugangsdaten.

Dies ist ein **Passivtest plus Handcheckliste**, kein vollständiger automatischer
UI-Robotertest. Die App kann nicht beweisen, dass Lautsprecher physisch hörbar
ausgeben; das muss die testende Person bestätigen. Xcode-Kompilierung, signierte
IPA, GitHub-CI und alle externen Tests bleiben separat erforderlich.

**Status:** Implementierter Quellcode auf Draft-Branch; erfolgreiche iPhone-IPA,
tatsächliche Wiedergabe und UI-Prüfung **NICHT GETESTET**.

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
