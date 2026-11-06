---
name: bbt-player
description: Ändert Wiedergabesitzung, Queue, Transport und Mini- oder Vollplayer in BBT-Bit.
---

# bbt-player

Beginne bei [PlaybackController](../../../AppleApp/Sources/PlaybackSession/PlaybackController.swift) und den Erweiterungen für Queue, Transport, LoadResults und Ticks. [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) und [NowPlaying](../../../AppleApp/Sources/UI/NowPlaying/) lesen dieselbe Sitzung.

Halte Identität und Reihenfolge der Queue beim Laden, Überspringen und Wiederaufnehmen stabil. Aktualisiere Anzeige und Transport aus den bestätigten Zuständen. Prüfe, ob verspätete Rückrufe zu einer früheren Anfrage gehören.

## Prüfung

Wähle je nach Änderung [check-queue](../../../scripts/check-queue.sh), [check-queue-runtime](../../../scripts/check-queue-runtime.sh), [check-transport](../../../scripts/check-transport.sh) und [check-playback](../../../scripts/check-playback.sh). Prüfe Mini-/Vollplayer-Wechsel und echte Wiedergabe nach [Testplan](../../../docs/TESTPLAN.md).

## Native Dynamic Island (iPhone) – dieselbe PlaybackSession

Die **echte Hardware-Dynamic-Island** ist Apple-System-Now-Playing, **nicht** eine selbst gezeichnete `MusicIsland`-/Logo-Bloom-View. Auf iOS 18–26 den bestehenden `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`-Pfad und unter iOS 27+ mit verfügbarem SDK `NowPlaying.MediaSession` benutzen. Titel, Künstler, **Album**, Artwork, Dauer, Zeit und tatsächlichen Wiedergabestatus aus derselben `PlaybackController`-Session veröffentlichen; alle System-Transportaktionen gehen zurück an die echten Controller-Methoden. Keine neue `Activity.request`-Musikkarte parallel zum nativen Systemplayer erstellen.

iOS bestimmt bei konkurrierendem Audio und `mix_with_other_audio`, welche App die Island beansprucht. Die Nutzereinstellung nicht heimlich auf exklusiv setzen. Der iPhone-Mini-Player unten und der Zoom zum Vollplayer sind **eine andere** RED-Morph-Interaktion und müssen weiterhin wie in der Nutzerreferenz funktionieren. Tests mit echtem Dynamic-Island-iPhone, hörbarem Audio, Sperrbildschirm, Kontrollzentrum, Hintergrund, AirPlay, Interruptions und Songwechseln; ohne echten Test **NICHT GETESTET**. [Dynamic-Island-Design](../../../docs/native-dynamic-island-red-morph.md) · [Testplan](../../../docs/TESTPLAN.md).

## Mini-Player-Navigation (iPhone, RED Morph)

Bewahre beim Scrollen den nativen Übergang des `PlaybackPill` vom regulären `tabViewBottomAccessory` oberhalb der Tab-Leiste zur kompakten **Inline-Darstellung** in der minimierten Leiste; bei Umkehr muss der Zustand zurückkehren. Die Regel `dockScroll.keepExpanded ? .never : .onScrollDown` in `RootView` gehört zum Wiedergabe-Nutzerweg und darf nicht durch permanentes `.never` ersetzt werden. Die native Suche (`role: .search`, `CompactPhoneSearchDrawer`) bleibt integriert. Mini-Player-Tap und Wisch zum Vollplayer benutzen weiter den verknüpften Zoom-Ursprung `matchedTransitionSource`, Ziel `navigationTransition(.zoom(...))`.

Die Umstellung betrifft ausschließlich Navigation und Darstellung: Wiedergabesitzung, Queue, Transport, Audioausgabe und Persistenz dürfen nicht neu erzeugt werden. Bei offener Tastatur nie doppelten Mini-Player präsentieren. Prüfe mit tatsächlich laufender Musik Scrollrichtung, schnelle Umkehr, Öffnen/Schließen, Suchfokus und Reduce Motion. Nutzerreferenz/Fehlerbehebung: [RED Morph](../../../docs/red-morph-player-search-navigation.md), [Probleme](../../../PROBLEME.md).
