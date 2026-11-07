# Native Apple Dynamic Island × BBT-Bit RED Morph

**Stand: 06.11.2026 · Arbeitsbranch:** `feature/red-morph-player-search-navigation` · [Draft-PR #49](https://github.com/Redurbabat/BBT-Bit/pull/49)

## Designentscheidung

Die **echte Dynamic Island** ist Apples Systemoberfläche am oberen iPhone-Displayrand und wird **nicht von einer eigenen SwiftUI-View direkt gezeichnet**. BBT-Bit integriert laufende Musikwiedergabe über **Now Playing**. Auf Dynamic-Island-fähigen iPhones entscheidet iOS anhand aktiver Audiowiedergabe und Systempriorität, wie die kompakte/erweiterte Musiksteuerung erscheint. Eine bestimmte Darstellung oder dauernde Sichtbarkeit kann die App nicht erzwingen.

Die eigene **Logo Glass Bloom** und die bisherige `MusicIsland` sind **nur innerhalb der App** sichtbare RED-Morph-Oberflächen, **keine** Hardware-Dynamic-Island-Implementierung. Sie dürfen die native Island nicht vortäuschen. Die RED-Morph-Mini-Player-Animation an der unteren Tab-Bar bleibt eine **separate** native Interaktion und darf nicht entfernt werden.

Originalquellen:
- [Apple WWDC26 – Meet the Now Playing framework](https://developer.apple.com/videos/play/wwdc2026/312/)
- [Apple – Publishing media sessions](https://developer.apple.com/documentation/nowplaying/publishing-media-sessions)
- [Apple – MPNowPlayingInfoCenter](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter)

## Implementierungsweg (vorhanden und ergänzt)

| System | Nativer Medienpfad | Angaben und Aktionen |
| --- | --- | --- |
| iOS 18 bis 26 | `MPNowPlayingInfoCenter` und `MPRemoteCommandCenter` | Titel, Interpret, **Albumtitel**, Cover, Dauer, Position, Wiedergaberate; Play/Pause, Zurück/Weiter, Seek |
| iOS 27+ mit passendem SDK | `NowPlaying.MediaSession<ModernNowPlaying>` | `MusicContent` mit Titel, Interpret, **Albumtitel**, Dauer, Cover sowie `MediaPlaybackSnapshot` und `MediaCommand` |
| Apple Watch, Sperrbildschirm, Kontrollzentrum, Kopfhörer, CarPlay | Dieselbe vom iOS-System ausgewählte Medienquelle | Keine eigene zweite Wiedergabesitzung; sichtbare Funktionen von Betriebssystem und Route abhängig |
| iPhone-RED-Morph-Tab-Leiste | `tabViewBottomAccessory`, `tabViewBottomAccessoryPlacement`, `DockScrollCoordinator` | Separater Mini-Player unten, der beim Abwärtsscrollen **inline** minimiert und beim Hochscrollen zurückkehrt; `matchedTransitionSource` zum Vollplayer |

**Neue Quellkorrektur:** Die Playlist-/Trackdaten enthielten `QueueEntry.albumName`, aber `NowPlayingController` veröffentlichte den Albumnamen bisher weder über `MPMediaItemPropertyAlbumTitle` noch im `MusicContent`-Modell (dort war `albumName: ""` fest kodiert). Die Metadatenübergabe wurde durchgängig über `prepareForPlayback`, `update` und alle acht Song-Update-Aufrufstellen ergänzt. Bestehende Audio-Engine, Wiedergabe-Befehle, Audio-Session-Optionen und Nutzerdaten blieben unangetastet.

**Keine konkurrierende Live Activity:** `NowPlayingActivityController.endLegacyActivities()` beendet nur die alten, aus früheren App-Versionen stammenden ActivityKit-Karten. Die aktuelle Widget Extension enthält ausschließlich ein normales `WidgetKit`-Widget, keine `ActivityConfiguration`. Keine `Activity.request`-Aufrufe für Wiedergabe einführen: Eine zusätzliche Musik-Live-Activity könnte parallel zur systemeigenen Musikinsel erscheinen.

## Keine erzwungene Systempriorität

Die vorhandene App-Einstellung **„Play Alongside Other Apps“** (`mix_with_other_audio`) bleibt vollständig unter Nutzerkontrolle. Mit `.mixWithOthers` kann iOS andere Audio-Apps als primäre Medienquelle wählen. Die Dynamic Island wird nicht zuverlässig BBT-Bit zugeordnet, nur weil ein Titel in der App als „Playing“ angezeigt wird.

**Nicht automatisch** das Benutzerpräferenz-Flag oder die Audio-Session-Route verändern, um die Island zu erzwingen. Für die Geräteabnahme BBT-Bit zunächst alleine abspielen, bei Bedarf die bestehende Misch-Einstellung auf exklusiv stellen und mit einem zweiten Musikdienst erneut testen. Eine erfolgreiche Veröffentlichung ist von tatsächlich **hörbarem** Audio getrennt nachzuweisen.

## RED-Morph-Abnahme (echtes Dynamic-Island-iPhone)

1. Gerät und Build-SHA dokumentieren. Einen **hörbaren** Titel starten. Nach Verlassen der App über der nativen Dynamic Island auf Cover/Wellenform achten; durch langes Drücken erweitern. Titel, Künstler und Cover müssen zum **wirklich laufenden** Titel passen.
2. Play/Pause, Weiter/Zurück und gegebenenfalls Zeitposition über Systemoberflächen betätigen; vergleichen, ob der echte Audioausgang stoppt/weiterläuft. Bei gesperrter Party-Steuerung keine unzulässigen Aktionen auslösen.
3. Albumtitel auf Sperrbildschirm/Kontrollzentrum kontrollieren; die kompakte Dynamic Island muss nicht alle Texte gleichzeitig anzeigen. Wechsel des Songs aktualisiert Artwork und Metadaten ohne alte Coverreste.
4. Kurz auf Pause, danach lange Pause, dann Wiedergabe; ferner schnelles Skip/Seek, Hintergrund, Gerät sperren, Bluetooth-/AirPlay-Wechsel, Audio-Unterbrechung und Wiederherstellung testen. Wiederholte Gesten dürfen keine zwei Sessions oder oscillierenden Wiedergabestatus erzeugen.
5. Für iOS 18–26 (`MediaPlayer`) und iOS 27+ (`NowPlaying`) **getrennt** prüfen. iPad/macOS haben nicht die iPhone-Hardware-Island; dort nur native Now-Playing-Systemsteuerung verifizieren.
6. Bei geöffneter App die getrennte **RED-Morph-Logo-Bloom** und die Mini-Player-Tab-Bar-Morph-Animation testen. Sie dürfen keine zweite Hardware-Live-Activity erzeugen und dürfen die native Tab-Bar-Mini-Player-Scrollanimation nicht blockieren.
7. Auch mit „Play Alongside Other Apps“ an/aus und einer zweiten Audio-App testen. Falls die System-Island auf der anderen App bleibt, zuerst iOS-Medienpriorität und wirkliche Audio-Sitzung überprüfen, **nicht** eine zweite Live Activity als Workaround bauen.

## Prüfstand

- **Quellcode:** Album-Metadaten im nativen `NowPlayingController` und in acht Übergaben ergänzt; alte Activities weiterhin nur bereinigt. Statischer Kontrollpfad: `python3 scripts/check-native-island-source.py`.
- **Befund ohne Apple-Build:** Auf GitHub sind die betreffenden Aufrufstellen und die getrennten iOS-Version-Pfade vorhanden. Das ist **kein ausgeführter Swift-Typecheck**.
- **NICHT GETESTET:** Xcode-Kompilierung, GitHub-Actions-Lauf, iPhone-/Dynamic-Island-Funktionstest, reale Pause/Seek/Skip-Bedienung, signierte IPA und hörbare Wiedergabe. Der Projektinhaber hat derzeit kein CI-Build-Kontingent; keine manuellen Build-Runs starten.
- **Kein Merge nach `main`**, keine Änderungen am Kotlin-/Rust-Audiopfad oder an persönlichen Nutzerdaten.

[RED-Morph-Gesamtprojekt](red-morph-player-search-navigation.md) · [Testplan](TESTPLAN.md) · [Entscheidungen](../ENTSCHEIDUNGEN.md) · [Bekannte Probleme](../PROBLEME.md)
