# Logo Glass Bloom – BBT-Bit Music Island

## Neue Bedienung auf dem iPhone

Die bisherige **dauerhaft mittig oben eingeblendete Music Island** wurde auf
iOS durch eine **temporäre Glass Bloom am App-Logo links oben** ersetzt.

- **Kein Song geladen:** Das normale BBT-Bit-Logo bleibt sichtbar, es gibt
  keine zusätzliche Music Island.
- **Neuer Song / Wiedergabe gestartet:** Das Logo stößt einen leichten
  Cyan-Impuls an; ein kleiner gläserner Kreis dehnt sich zu einer Kapsel
  mit dem echten Albumcover, Titel, Interpret und Play/Pause aus.
- **Einmal auf das Logo tippen:** Kompakte Kapsel öffnen. Bei offener Kapsel
  wird sie zur erweiterten Steuerung; beim dritten Tippen verschwindet sie.
- **Logo gedrückt halten:** Erweiterte Steuerung direkt öffnen.
- **Albumcover in der Kapsel antippen:** Erweiterte Steuerung öffnen.
- **Erweiterte Steuerung:** Vorheriges Lied / Play-Pause / Nächstes Lied /
  Vollbild-Player. Kein zweiter Audio-Controller wird erstellt.
- **Einklappen:** Die erweiterte Karte wird zur Kapsel und verschwindet
  anschließend automatisch.
- **Automatisch ausblenden:** Kompakt nach 4 Sekunden, ausgeklappt nach
  8 Sekunden. Interaktion mit Musiksteuerung verlängert die Anzeige.
- **Player, Einstellungen, Login, Onboarding öffnen:** Das Bloom schließt
  sofort, damit keine Navigation überdeckt wird.

**Visuell:** Die Animation startet am selben oberen linken Bildschirmbereich
wie das native BBT-Bit-Toolbar-Logo. Die Karte dehnt sich mit Spring,
Cyan/Purple-Lichtkante und weichen Reflexionen aus. Unter iOS 26 wird
Apples natives Liquid Glass verwendet; iOS 18 bis 25 erhalten
`ultraThinMaterial` als Fallback. Der Betrieb mit „Bewegung reduzieren“
verwendet eine dezente Fade-Animation.

Die Kapsel wird **nicht mehr permanent über „Jetzt hören“ gelegt**.
Aufnahme der tatsächlich sichtbaren Music Island ist über den vorhandenen
Live-Screenshot-Recorder weiterhin möglich.

## Auf einem echten iPhone prüfen

1. Einen **signierten** Build des Branches
   `feature/logo-glass-bloom-20261104` installieren.
2. Startseite öffnen, ohne Song zu starten: nur Logo, keine Bubble.
3. Song starten: Logo-Puls → kompakte Glass Bloom → nach 4 s zurück.
4. Logo antippen oder gedrückt halten: Steuerung öffnen; nach 8 s
   automatisch schließen.
5. Pause / Play / Next vergleichen mit dem unteren Miniplayer.
6. Vollbild-Player oder Einstellungen öffnen: Bubble verschwindet sofort.
7. In Einstellungen → Echte Screenshots einmalige Aufnahme starten,
   Logo erneut antippen, Resultat ansehen; Foto muss die tatsächliche
   aktuell sichtbare Glass Bloom zeigen.

## Qualitätsgrenzen

Swift-Syntax- und GitHub-Konfigurationsprüfungen sind nur ein erster Schritt.
Ein erfolgreiches `xcodebuild`, tatsächliche iPhone-Animation, Audiozustände
und Layering müssen auf einem Gerät oder iOS-Simulator geprüft werden.
Veränderungen gehen ausschließlich in den separaten Review-PR;
nichts wird automatisch nach `main` gemergt.
