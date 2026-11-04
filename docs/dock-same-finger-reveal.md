# iPhone-Dock und Logo: Richtungswechsel innerhalb derselben Fingerbewegung

## Reproduzierter Wunsch (4. November 2026)

Auf der Entdecken-Seite mit den farbigen Kategorien (Chill, Christmas,
Commute …) minimiert die untere Apple-System-Tab-Leiste beim
Herunterscrollen. Wenn man **ohne Loslassen desselben Fingers** die Richtung
nach oben umkehrt, erscheint sie bisher nicht zuverlässig sofort wieder.
Erst nach Loslassen und einem neuen Wisch kehrt die volle Dock zurück.

Das links oben sichtbare BBT-Bit-Logo soll außerdem nicht nur durch
Antippen reagieren. Das referenzierte automatische macOS-Dock reagiert
auf einen Mauszeiger am Bildschirmrand; ein iPhone kann einen noch nicht
aufgesetzten Finger nicht erfassen.

## Implementierung im Review-Branch

1. **Passiver Richtungsdetektor** auf den jeweils primären vertikalen
   ScrollViews von Home, Explore und der Library-Startseite. SwiftUI
   `onScrollPhaseChange` erkennt die aktive Fingerinteraktion;
   `onScrollGeometryChange` misst die Richtung auch bei einer
   **Umkehr innerhalb desselben Kontakts**. Dadurch werden keine
   Scroll-, Karten- oder horizontalen Carousel-Gesten abgefangen.
2. **Entprellung (13 pt)** im reinen `DockDirectionTracker` und
   Clamping an beiden Scroll-Grenzen. Winziges Zittern, Bounces und
   auslaufende Scroll-Trägheit lösen keinen Moduswechsel aus.
3. **Native Dock bleibt**: Beim Scrollen nach unten nutzt
   BBT-Bit Apples `.tabBarMinimizeBehavior(.onScrollDown)`.
   Beim aktiven Richtungswechsel nach oben schaltet die bestehende
   TabView kurzfristig auf `.never` und fordert dadurch die
   Wiederherstellung derselben nativen Leiste mit nativer Search-
   Rolle und dem vorhandenen `tabViewBottomAccessory` an.
   Beim Beginn einer neuen Fingerbewegung wird `.onScrollDown`
   wieder aktiviert. iPad, ältere iOS-Versionen und Mac behalten
   die bestehende Darstellung.
4. **Logo-Glass-Bloom ohne Pflichtklick**: Bei erkanntem aktiven
   Aufwärtsscroll wird die kompakte Musikblase am Logo ausgelöst,
   sofern ein echter Track existiert und kein Dialog/Vollbild
   darüber liegt. Beim Abwärtsscroll wird die kompakte Blase
   geschlossen; eine bewusst aufgeklappte Blase bleibt stehen.
5. **Direkte Geste auf dem Logo**: Vom Logo nach unten ziehen
   öffnet bei einem geladenen Track die erweiterte Musiksteuerung.
   Tippen und Halten bleiben als barrierefreie Alternativen erhalten.

## Was NICHT behauptet wird

- Es gibt **keine** öffentliche iOS-API, die das native
  Tabbar-Minimierungs-**Fortschrittsmaß** an einen Finger koppelt.
  Das Umschalten der Systempolitik ist ein vorsichtiger
  Kompatibilitätsansatz, keine Garantie für framegenaue
  macOS-Dock-Physik. Eine völlig fingergebundene,
  interaktive Tab-Bar bräuchte ein eigenes Nav-System und
  erhebliche separate Tests; das wurde bewusst nicht eingebaut.
- Dieser Branch behebt **nicht** die bereits dokumentierte
  YouTube-Streamauflösung. Player und Queue bleiben unverändert.
- Die Glasblase erscheint nur mit echtem ausgewähltem Track.
  Bei fehlendem Track bleibt das Logo normal sichtbar.

## Testplan

### Automatische Offline-Prüfung
`swiftc AppleApp/Sources/UI/LiquidMotion/DockDirectionTracker.swift scripts/test-dock-direction-tracker.swift -o /tmp/bbt-dock-test && /tmp/bbt-dock-test`

Prüft Richtung nach unten, denselben Kontakt nach oben,
Zitterbewegung, Freigeben und erneute Richtungsänderung.

### iPhone 26.6.1 / aktueller signierter Build
- Entdecken öffnen, deutlich nach unten scrollen: Tabbar minimiert,
  Mini-Player wandert nach unten inline.
- **Finger nicht abheben**: Richtung nach oben wechseln, mindestens
  20–30 pt bewegen. Dock soll ohne neuen Fingerkontakt
  wieder erscheinen. Langsames und schnelles Umkehren prüfen.
- Bis ganz oben/unten ziehen und federnd zurückkommen:
  kein Flackern, kein falsches Wiedereinblenden.
- Mit und ohne geladenen Song testen: Ohne Song kein
  falscher Player; vorhandener Track darf Glass Bloom zeigen.
- Logo nach unten ziehen: Erweiterte Glasblase erscheint;
  Tippen und Long-Press weiterhin nutzbar.
- Dasselbe in Home und der Bibliothek-Startseite wiederholen.
- Eine Genre-Karte antippen, horizontalen Shelf wischen,
  Suche und Bibliothek öffnen: Gesten dürfen nicht
  geblockt sein, Tabs und Search bleiben native Controls.
- Player vergrößern, verkleinern und Automix/Queue prüfen;
  keine Änderungen am Audio-/PlaybackController.
- VoiceOver, Reduce Motion, größere Schrift und
  Tastatureinblendung separat testen.
- Dasselbe Verhalten am iPad und auf macOS vergleichen;
  diese Plattformen dürfen keine neue Scrollpolitik bekommen.

**Nur der reine Richtungs-Regressionstest ist automatisch
eingerichtet. Der reale iPhone-Dock-Restoration-Test bleibt
NICHT GETESTET, bis ein signierter Build auf dem Gerät vorliegt.**
