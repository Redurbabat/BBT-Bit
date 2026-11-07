# Glass Bloom Motion Lab — Ideen und sofortige Umsetzung

## Ziel
Die temporäre Musikblase, die links oben am BBT-Bit-Logo startet,
soll **sichtbar lebendiger**, aber nicht ständig präsent oder störend sein.

## Jetzt umgesetzt (7 Bausteine, Stand 7. November 2026)

1. **System Liquid Glass:** neutrale, adaptive Glasfläche ohne
   Cyan-/Violett-Lichtfelder. Die frühere `GlassBloomAtmosphere`
   ist nicht mehr in die Music Island eingeblendet.
2. **Kinetic Status Rail**: in der geöffneten Ansicht ist „JETZT LÄUFT“
   oder „PAUSIERT“ mit vier dezent bewegten Balken sichtbar. Die Balken
   visualisieren nur den Wiedergabestatus, **keine gemessenen Beats**.
3. **Native Glasreflexion:** systemeigenes Highlight; die bisherige
   zusätzliche Kometen-/Gradientenanimation beim Titelwechsel entfällt.
4. **Gesten**: rechts/links wischen wechselt Titel, nach oben ausklappen,
   nach unten einklappen oder schließen. Ein Swipe darf keine
   „Listen Together“-Steuersperre umgehen.
5. **Quick Routes**: im erweiterten Player direkt zu **Lyrics** oder
   **Queue**. Der Vollbild-Player wird geöffnet, dann die gewünschte
   Pane angefordert.
6. **Hierarchie statt Button-Wolke**: zuerst Cover/Titel, dann Status,
   dann Musiktransport, dann Lyrics/Queue, ganz unten eine knappe
   Gestenlegende. Kurze, gestaffelte Einblendbewegungen.
7. **Motion Budget**: bei „Bewegung reduzieren“ oder Stromsparmodus
   keine endlosen Glanz-/Balkenanimationen. Bereits laufende
   Wiedergabe wird nicht verändert. Pausiert = ruhiger Glaszustand.

## Weitere Ideen, absichtlich noch nicht implementiert
- **Albumfarben-Refraktion:** ausdrücklich **nicht für Mini-Player
  oder Music Island** vorsehen; Coverfarben gehören nur in die
  Albumkunst und optional in den Vollbild-Player.
- **Queue Orbit**: zwei kleine kommende Cover beim Öffnen der
  Warteschlange; nur mit echten nächsten Titeln.
- **Gesture Coach**: einmaliger, abschaltbarer Hinweis statt dauerhafter
  Pfeile für neue Nutzer.
- **Micro-Haptics**: dezentes Feedback beim Trackwechsel mit
  Benutzeroption zum Ausschalten.
- **Parallax**: minimaler Neigungs-Effekt nur nach klarer Einwilligung
  und mit deaktivierter Bewegungshilfe.

## Realer Test

1. BBT-Bit auf einem signierten iPhone-Build dieses Branches öffnen.
2. Musik starten: die kompakte Glasblase erscheint automatisch.
3. Logo halten: aufgeklappte Karte zeigt Status, Transport, Lyrics,
   Queue und den Gestenhinweis.
4. Play/Pause vergleichen: Status und Balken müssen wechseln.
5. Nach links/rechts wischen: tatsächlicher Trackwechsel, nur wenn
   vorheriger/nächster Titel verfügbar und die Party-Steuerung frei ist.
6. Nach unten wischen: von ausgeklappt zu kompakt, dann ausblenden.
7. „Lyrics“ und „Queue“ antippen: der passende Vollbild-Player-Pane öffnet.
8. „Bewegung reduzieren“ und Stromsparmodus aktivieren: keine unendlichen
   Hintergrund- oder Equalizer-Bewegungen. Zusätzlich `Transparenz reduzieren`
   und App-Einstellung `reduce_dynamic_blur` prüfen: das Glas muss durch
   einen lesbaren opaken Hintergrund ersetzt werden.
9. Einstellungen öffnen: Glass Bloom wird sofort ausgeblendet.

Die GitHub-iPhone-Simulator-Tests prüfen, ob der iOS-Code baut und die
vorhandenen Vorschau-XCUITests bestehen. Die neuen Gesten und tatsächliche
Musikwiedergabe sind **noch separat auf einem echten iPhone zu prüfen**.

## Branch-Schutz
Nur Review-PR, kein Merge nach main.
