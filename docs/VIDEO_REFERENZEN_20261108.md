# RED Bit · Umsetzung der beiden Videoreferenzen

Die Referenzen wurden am 8. November 2026 lokal mit FFprobe und Einzelbildern geprüft. Video 1: 2,2467 s, 1284 × 2674, 120 Bilder/s, SHA-256 `ECFA1C390848D50ABF51CE632C2B8BECF35E41D2100BC5D225F6AA117928C5BB`. Video 2: 39,0083 s, dieselbe Auflösung/Bildrate, SHA-256 `14E9064CD2E4599F24F57FC0C2DC0CA90F68972151F9AF2F7D294B49E230BEBD`.

Die Videos bleiben Gesprächsreferenzen; Musikbilder und Songtexte daraus werden nicht als App-Assets übernommen. RED Bit verwendet die tatsächlichen Cover, Titel, Wiedergabezeiten und Songtextdaten des Nutzers.

## Umsetzungsplan

1. **Künstlerregale, Video 1:** Die bestehende `ShelfCarousel(rail: true)` erhält eingefasste, mittig beschriftete Karten. Ein eigener Metal-Verzerrungseffekt biegt die Karten während des nativen seitlichen Scrollens. Die bisherige starke Unschärfe entfällt. Reihenfolge, Öffnen-/Abspielen-Aktionen und Kontextmenüs bleiben erhalten. Die Seitenanzeige bleibt an den echten Scrollfortschritt gebunden. Bei reduzierter Bewegung werden Karten unverzerrt angezeigt.
2. **Portrait-Vollplayer, Anfang von Video 2:** Fortschritt und Transport erscheinen als Bogen mit tatsächlichen Playeraktionen. Die geometrische Abbildung von Berührung zu Wiedergabezeit wird separat getestet; der Regler respektiert unbekannte Dauer, Suchgrenzen und gesperrte Party-Bedienung. Landschaft, iPad und Mac behalten die dafür bestehenden Anordnungen. Keine Audio- oder Queue-Umbauten.
3. **Sternbild-Lyrics, Video 2 ab etwa 2 s:** Eine schwarze Vollbildfläche mit ruhigem Sternenhintergrund, wachsender Wortverbindung, hervorgehobenem aktuellem Wort, fließender Kamera und kompletter aktueller Zeile am unteren Rand. Derselbe Lyrics-Versatz und dieselben Wort-/Zeilenzeiten wie in der Liste; keine erfundenen Präzisionsmarker bei ungenauen Daten.
4. **Ausdrückliche Nutzerwahl:** Die aktuelle Listenansicht bleibt erhalten. Eine gespeicherte Auswahl „Liste / Sternbild“ sowie ein direkter Rückweg aus dem Sternbild erlauben jederzeit den Wechsel. Fehlende Synchronisation fällt auf die nutzbare Listenansicht zurück.

## Abnahme

- Reine Geometrie-/Zeitmodelle auf Grenzwerte, Seek, Richtungswechsel und ungültige Zeitwerte testen.
- Swift-Syntax, Metal-Kompilierung und vollständiger iOS-Build.
- Xcode 26 benötigt für eigene Shader die optionale [offizielle Metal-Toolchain](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components). `scripts/ensure-metal-toolchain.sh` prüft den Compiler und installiert ihn bei Bedarf über Apples `xcodebuild -downloadComponent metalToolchain`. Simulator-CI und IPA-Bau rufen diesen Schritt auf.
- Native Simulatorbelege mit klar als Fixtures gekennzeichneten Inhalten; echte App-Navigation getrennt prüfen.
- Künstlerseite: langsames/schnelles Wischen, Abbruch/Umkehr, lesbare ruhende Karten, Kontextmenü und korrekte Navigation.
- Vollplayer: Bogen-Seek, Play/Pause/Skip, Queue, Repeat, Shuffle, Lyrics-Umschaltung; bisheriger Mini-/Vollplayer-Zoom bleibt erhalten.
- Sternbild: zeitlicher Versatz, Pause/Fortsetzen, Seek, Zeilenwechsel, Rückweg zur Liste, VoiceOver, große Schrift und Reduce Motion.
- Referenz und Zielvideo gegenüberstellen, bevor die visuelle Übereinstimmung als abgenommen gilt. **Pixel- und Bewegungsparität, echtes iPhone sowie hörbare Wiedergabe sind bis zu dieser Prüfung NICHT GETESTET.**

Arbeitsbranch bleibt `codex/red-bit-integration-motion-20261108`; Draft-PR #59. Kein Merge nach `main` ohne das Okay des Maintainers.
