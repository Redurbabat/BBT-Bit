# Echte iPhone-Screenshots der 15 Liquid-Motion-Funktionen

## Problem, das diese Änderung löst

Die ursprüngliche BBT-Bit-Funktion "Design-Fotos" erzeugte **synthetische
Beispielkarten**, z.B. "Song 1" oder "Gast 1". Diese Bilder waren keine
Screenshots der laufenden iPhone-App und können reale Layoutfehler nicht
nachweisen. Sie werden künftig ausdrücklich "Design-Vorschauen" genannt.

## Neue Aufnahmefunktion auf deinem iPhone

1. Installiere einen signierten Build des Branches
   feature/live-iphone-screenshots-20261103.
2. Öffne **Einstellungen → Your Data & Backup → Echte Screenshots**.
3. Tippe **Echte Screenshots aufnehmen**.
4. Verlasse Einstellungen und öffne die BBT-Bit-Ansichten wie üblich.
5. Sobald eine der 15 Liquid-Motion-Komponenten tatsächlich sichtbar wird,
   nimmt die App nach einer kurzen Verzögerung das **gerade sichtbare
   iOS-App-Fenster** (UIKit UIWindow) mit UIGraphicsImageRenderer auf.
6. Klappe Music Island, Infinity Dock oder Glass Portal auf, um eine
   erneute Aufnahme mit erweitertem Zustand zu speichern.
7. Gehe zurück zu Einstellungen → Echte Screenshots, drücke
   **Aufnahme beenden** und **Echte Screenshots teilen**.
8. Teile die PNG-Dateien und den JSON-Bericht über das iPhone-Teilenmenü.

Die Dateien sind in Application Support/BBT-Bit-Live-Screenshots/<session-id>
gespeichert. Es gibt **keinen automatischen Upload** und die App greift
nicht auf die Foto-Mediathek zu. Screenshots können echte Songtitel,
Albumcover und persönliche Inhalte enthalten; teile sie nur bewusst.
"Aufnahmen löschen" entfernt den aktuellen Aufnahmeordner.

## Wie die 15 Features erfasst werden

- Automix Weave: tatsächliches erkannte Übergangsfenster im Player.
- Lyrics Mirror: nur bei Original UND Übersetzung.
- Signal Prism: Audio-Pipeline öffnen.
- EQ Membrane: Equalizer öffnen.
- Replay Time River: Replay mit 24-Stunden-Daten öffnen.
- Queue Horizon: Player-Warteschlange mit kommenden Songs.
- Download Bloom: Download-Manager mit mindestens einem Job.
- Output Halo: Audioausgabe-Schalter im Player.
- Party Constellation: Listen Together aufrufen.
- Canvas Veil: Song mit verfügbarem Canvas abspielen.
- Handoff Comet: echte angenommene Geräteübergabe.
- Echo Trail: Wiedergabe nach mindestens einem früheren Song in der Queue.
- Music Island: Startseite bei vorhandener aktueller Wiedergabe.
- Infinity Dock: Vollbild-Musikplayer öffnen und ggf. Dock aufklappen.
- Glass Portal: Vollbild-Musikplayer öffnen und ggf. Portal aufklappen.

Es gibt bewusst **keinen erfundenen Erfolg** für ein Feature, das auf dem
Gerät nicht sichtbar war. Der Bericht listet nur tatsächlich gespeicherte
PNG-Dateien. Er beweist nicht, dass Audio, Netzwerk oder Party-Sync korrekt
funktioniert; er dokumentiert die sichtbare Oberfläche.

## Grenze der iPhone-Systemrechte

Eine normale iOS-App kann ihre eigene sichtbare UIWindow aufnehmen,
aber nicht beliebig im Hintergrund durch alle Ansichten klicken und
systemfremde Screenshots erstellen. Für **wirklich unbeaufsichtigte
Button-Klicks** auf dem echten iPhone gibt es XCUITest, der von Xcode
auf einem Mac oder einem autorisierten Gerätetestdienst gestartet werden
muss. Das separate XCUITest in PR #28 testet derzeit einen Offline-
Vorschaudurchlauf; es ist **kein** vollautomatischer Live-End-to-End-Test
aller 15 Produktionsfunktionen.

## Testkriterien

- Mindestens ein aktueller Song auf dem iPhone.
- "Echte Screenshots aufnehmen" aktivieren und Einstellungen schließen.
- Music Island aufklappen: nun echte PNG, nicht das Beispielbild.
- Vollbild-Player öffnen und Infinity Dock aufklappen: zweite echte PNG.
- Albumcover, Liedtitel und übrige sichtbare Elemente müssen mit
  dem tatsächlichen App-Bildschirm übereinstimmen.
- Zurück zu Einstellungen und PNG-Dateien sowie JSON teilen.
- Bei nicht erscheinenden Komponenten fehlen Aufnahmen im Bericht.
- Aufzeichnungen erfolgen ausschließlich nach ausdrücklichem
  Aufnahmestart, bleiben lokal und können gelöscht werden.

Keine iPhone-Hardware oder native Xcode-Compilation in dieser Sitzung
ausgeführt. Vor einem Merge sind Codemagic-Build und echter Gerätetest
erforderlich. Draft PR geht auf einen separaten Review-Branch, nicht main.
