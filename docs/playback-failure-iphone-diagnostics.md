# BBT-Bit spielt keine Musik – Wiedergabe-Diagnose

## Sofort auf der vorhandenen iPhone-App prüfen

**Diese Schritte funktionieren auch ohne den neuen PR.**

1. BBT-Bit öffnen, einen Song starten und etwa 10 Sekunden warten.
2. Profilbild → Einstellungen → **Playback** → **Diagnostic Reports**.
3. **Save Diagnostic Report** und **Share Diagnostic Report** wählen.
4. Die TXT-Datei zur Diagnose hochladen. Vor dem Teilen prüfen, ob
   persönliche Angaben enthalten sind; keine Zugangsdaten mitsenden.

Der Report enthält einen Engine-Snapshot und die bisherigen technischen
Ereignisse des iPhones, darunter ggf. Resolver-/HTTP-Fehler,
fehlgeschlagene Aktivierung der AVAudioSession oder Output-Recovery.
Ein erfolgreicher GitHub-iPhone-Simulator-Designvorschau-Test beweist
ausdrücklich **keine echte YouTube-/Audio-Wiedergabe**.

## Ergänzung auf diesem Review-Branch

Mit der nächsten signierten App-Version gibt es in den Einstellungen
unter **Playback → Musik spielt nicht?** eine Live-Diagnose:

- tatsächlicher Wiedergabestatus (Lädt, Pausiert, Gestoppt, Läuft)
- aktueller Song und Quelltyp ohne private URL
- echte Position und Dauer
- Verbindungsstatus und iPhone-Audiositzung
- letzter Wiedergabefehler mit gekürzter/sanitisierter Anzeige
- **Aktuellen Song neu laden**, ausschließlich wenn nicht bereits
  aktiv oder in der Ladephase; es wird eine frische Quelle angefordert
- **Diagnosebericht speichern/teilen** für die Ursache

Der Fehlerpfad `loadDidFail` schreibt zusätzlich Art der Quelle
(YouTube/andere), Netzwerkverbindung, Audiositzungszustand und die
Fehlermeldung in den bestehenden lokalen Debug-Log. Logs werden beim
Export über `PlaybackDebugLog.sanitize` bereinigt. Den Bericht trotzdem
vor dem Teilen prüfen.

## Diagnostische Unterscheidung

- **Online-Songs funktionieren nicht, lokale Musik schon:** Ein Problem
  mit Streamauflösung, YouTube-Verifikation, Netzwerk oder Onlinequelle
  ist wahrscheinlicher.
- **Auch lokale Musik funktioniert nicht:** Audio-Engine,
  Audiositzung oder Ausgabe-Route genauer prüfen.
- **Player zeigt 0:00 / -0:00:** Zeit/Dauer sind nicht vorhanden;
  das allein beweist weder eine YouTube-Sperre noch einen Audiodefekt.
- **Player meldet Wiedergabe, Zeit läuft, kein Ton:** Lautstärke und
  Ausgabeziel (iPhone/Bluetooth/AirPlay) prüfen.
- **Es erscheint ein Fehler:** Diagnosebericht auswerten, bevor eine
  eigentliche Playback-Änderung erfolgt.

Dieser PR liefert eine konkrete Fehlersuche und einen begrenzten
manuellen Wiederholungsversuch. **Er behauptet nicht, die unbekannte
Ursache auf dem Gerät bereits behoben zu haben.** Es gibt keine
automatischen Tests mit den privaten YouTube-Zugangsdaten.

Änderungen auf separatem Review-Branch, nicht auf main.
