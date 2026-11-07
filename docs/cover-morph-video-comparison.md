# BBT-Bit – Cover Morph aus zwei echten Bildschirmaufnahmen

## Vergleich (4. November 2026)

**Video A (eigenes iPhone, ~25,3 s):**
`ScreenRecording_11-04-2026 11-37-46_1(1).mp4`

- Dunkle Startseite mit „Jetzt hören“, Quick Picks und dem
  ständig verfügbaren Mini-Player direkt oberhalb der Tabbar.
- Die Logo Glass Bloom oben links erscheint kurz und öffnet sich
  gegen Ende der Aufnahme zur erweiterten Steuerung.
- Es wird **kein** klarer Vorgang vom unteren Mini-Player in den
  Vollbild-Player gezeigt.
- Im Material ist keine laufende Wiedergabezeit erkennbar.
  Der separate iPhone-Diagnosebericht zeigt fehlgeschlagene
  YouTube-Streamextraktion; kein UI-Effekt repariert diese allein.

**Video B (Referenz, ~17,2 s):**
`ssstwitter.com_1793789346518.mp4`

- 0–7 s: Startseite, Explore und Library. Ein kleiner Player bleibt
  unten oberhalb der Tabs. Die Navigation bleibt frei.
- 7–10 s: Mood-/Genre-Kacheln und eine zum Albumcover passende
  **farbige, gläserne Mini-Player-Kapsel**.
- ~10,5–11,5 s: Interaktive Öffnung zum Vollbild mit großem
  Albumcover und einem farblich passenden Hintergrund.
- ~11,5–12 s sowie ~13,7–14,1 s: Rückkehr vom Vollbild in den
  unteren Player. Die Oberfläche fühlt sich wie eine
  **zusammenhängende Zoom-/Rückfluss-Bewegung** an.
- ~14–15 s: Erneutes Öffnen und Verkleinern. Der untere Player
  bleibt als Anker sichtbar.
- Die im Referenzvideo fortschreitende Wiedergabezeit ist
  kein Nachweis für die bestehende Wiedergabe in BBT-Bit.

## Umsetzung in dieser PR

### 1. Natives Liquid Glass am Mini-Player (Nutzerkorrektur 7. November)
Die `PlaybackPill` bleibt mit dem **echten**
`PlaybackController` verbunden. Nach dem iPhone-Screenshot und der
ausdrücklichen Designentscheidung wurde der frühere
`CoverMorphMiniSurface`-Farbverlauf **aus der Mini-Pill entfernt**:
Keine goldenen, violetten oder cyanfarbenen Hintergrundschichten hinter
den Bedienelementen. Auf iOS 26+ zeichnet die systemeigene
`TabViewBottomAccessory` ihr Liquid Glass selbst. iPad und macOS
haben eine einzelne native Glasfläche; ältere Systeme und
Barrierefreiheit erhalten eine semantische, ausreichend kontrastreiche
Fallback-Fläche.

`CoverMorphMiniSurface` bleibt vorerst als historischer, ungenutzter
Baustein erhalten; seine Farben werden **nicht mehr** in den sichtbaren
Mini-Player eingeblendet. Keine erfundenen Songtitel oder Audiofortschritte.

### 2. Cover-Farben nur im Vollbild
`CoverMorphFullBackdrop` nutzt weiterhin den echten Artwork-Cache
und den vorhandenen `MeshBackdrop`. Der Vollbild-Player kann aus
dem Cover passende Farben beziehen, **nicht** aber die System-Glasflächen
der Music Island, Tab-Leiste oder Mini-Pill.

### 3. System-eigener Zoom bleibt die Quelle der Bewegung
Die `PlaybackPill` ist unverändert `matchedTransitionSource`;
`NowPlayingTakeover` nutzt weiterhin
`.navigationTransition(.zoom(...))`. iOS öffnet und schließt den
Player damit zwischen derselben unteren Kapsel und der
Vollbild-Sheet, einschließlich des systemeigenen Ziehens zum
Verkleinern. **Kein zweiter eigener Sheet-Animator**, der mit der
interaktiven Geste kollidiert.

Die obere temporäre **Logo Glass Bloom** bleibt separat erhalten.
Eine erfolgreiche Animation beweist nicht, dass YouTube-Audio
entschlüsselt oder geladen wurde.

### 4. Zugänglichkeit und Performance
- Reduce Transparency / `reduce_dynamic_blur`: keine zusätzliche
  leuchtende, farbige Mini-Pill.
- Reduce Motion und Stromsparmodus: keine unendliche Driftbewegung.
- Systemweite `.primary`-/`.secondary`-Textfarben für die neutrale
  Mini-Pill und die appinterne Music Island; kein festes Weiß über
  einer farbigen Album-Tönung.
- Keine Audiozeit/Progressbar erfinden: der dünne Fortschrittsbalken
  wird ausschließlich mit `controller.position/controller.duration`
  berechnet, falls eine echte Dauer vorhanden ist.
- Artwork laden nur bei Titelwechsel; Albumfarben folgen
  demselben gecachten Bild wie der große Player.

## Test auf dem echten iPhone

1. Eine **signierte** BBT-Bit-IPA dieses Branches installieren.
2. Einen ausgewählten Song mit einem gelb/goldenen oder violetten
   Cover öffnen: Der Mini-Player muss **neutrales Liquid Glass** zeigen,
   unabhängig von der Cover-Farbe. Bei reduzierter Transparenz opak.
3. Zwischen Start, Entdecken und Bibliothek wechseln:
   mini-player bleibt unten sichtbar.
4. **Unteres Albumcover/Titel antippen** oder Pill nach oben wischen:
   Vollbild öffnet mit Zoom aus derselben Kapsel.
5. **Am oberen Griff nach unten ziehen**: der Player fließt wieder
   zur unteren Kapsel.
6. Vergleichen: Das Vollbild darf die Cover-Palette verwenden; die
   Mini-Kapsel bleibt bewusst **systemneutral**.
7. Anderes Lied wählen: Das Artwork wechselt, ohne dass die neutrale
   Glasfläche neue Cover-Farben annimmt.
8. „Bewegung reduzieren“, „Transparenz reduzieren“ und
   Stromsparmodus separat aktivieren.
9. Gesondert prüfen: Wird echte YouTube-Audiozeit fortgeschrieben?
   Falls nicht, den Resolver-Fehler aus dem Diagnosebericht untersuchen.

## Einschränkung

Nicht Pixel-für-Pixel oder mit übernommener Grafik einer fremden App
kopiert; die **Bewegungsprinzipien** bleiben erhalten. Das frühere
coverabhängige Farberlebnis der Mini-Pill wurde durch neutrales
Apple-Liquid-Glass ersetzt. Die UI-Änderungen reparieren nicht den separaten
`No playable stream`-Fehler aus dem 4.-November-Gerätebericht.

Alle Änderungen in einem **separaten Draft-PR nur gegen Review-Branch**.
Kein Merge nach main.
