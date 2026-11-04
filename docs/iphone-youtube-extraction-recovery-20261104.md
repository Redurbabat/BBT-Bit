# iPhone-Wiedergabe: YouTube-Stream kann nicht aufgelöst werden

## Befund anhand des echten iPhone-Berichts vom 4. November 2026

- BBT-Bit **1.0.4 (Build 13)** unter iOS 26.6.1.
- Viele unterschiedliche YouTube-IDs meldeten
  `No playable stream found for this track.` und
  `no client would serve this track (extraction failed)`.
- `latency: tap→resolved unresolved`, kein erster Puffer,
  kein erster Audioton.
- `Audio session activation succeeded` und
  `Default Device — 48000 Hz, 2 ch`; die Audiokomponente konnte
  eine Ausgaberoute initialisieren.
- Engine-Snapshot: Codec leer, 0 decodierte Streams, `bufferedFrames=0`,
  `outputPeak=0`, Status `paused`.
- Automix war aktiv, und viele Downloads/Prefetch-Auflösungen
  scheiterten parallel, teils mit `TimeoutCoroutine was cancelled`.

**Schluss:** Der primäre beobachtete Fehler ist die Stream-Extraktion,
nicht eine Lautstärkeeinstellung oder die Glass-Bloom-Animation.
Der Report kann **nicht** beweisen, ob YouTube serverseitig direkte
URLs zurückhielt, eine konkrete Client-Signatur/PoToken-Konfiguration
veraltete, die Quelle die Wiedergabe verweigerte oder eine
In-App-Extraktionspolitik unvollständig war.

## Technischer Engpass

Die Apple-Rust-Audio-Engine akzeptiert hier nur progressive/direct
Audioquellen. Deshalb fordert
`UpstreamPlaybackExtractor.extractStream()` explizit
`allowHls=false, allowSabr=false, allowBoundedRange=true`.
Die vendorte InnerTubeX-Bibliothek kann **SABR**, aber diese
Apple-Pipeline verfügt noch nicht über einen SABR→Engine-Adapter.
Das Einschalten von `allowSabr` ohne eine eigene kompatible
Demux-/Abspielstrecke wäre ein falscher Fix.

## Im PR implementiert

1. **Session-Reset-Sturm eingedämmt:** Eine fehlgeschlagene
   YouTube-Extraktion konnte die eine gemeinsame InnerTube-Verbindung
   bei *jedem* Song/Download gleichzeitig schließen und neu eröffnen.
   Nun wird eine Session pro Anmeldung/Generation innerhalb von 20 s
   nur einmal zurückgesetzt. Andere Requests behalten die
   bereits aktualisierte Verbindung. Das mindert
   unnötige Verbindungsabbrüche, kann aber keinen fehlenden Stream
   auf magische Weise erzeugen.
2. **Kategorie der echten Fehler sichtbar:** Die Brücke übergibt bei
   `StreamResolveException` jetzt den fest definierten
   Fehlercode (`NO_PLAYABLE_STREAM`, `BOT_CHECKED` usw.), die
   Anzahl der Clientversuche und den Hinweis
   `transport=progressive-only` an den Swift-Resolver.
   Dabei werden weder signierte URLs noch Cookies, PO-Tokens oder
   Header im Diagnosezusatz veröffentlicht.
3. **Offline-Kotlin-Regressionsprüfungen:** Mehrere gleichzeitige
   Fehler dürfen die gemeinsame Verbindung nicht immer wieder
   zurücksetzen. Bei neuem Konto/Session darf sofort neu
   initialisiert werden.
4. Enthält auch die separate neue Diagnoseoberfläche aus PR #35.

## Was noch offen ist

Die **vollständige Wiederherstellung des YouTube-Streams ist nicht
bewiesen**. Dazu muss ein erfolgreicher Live-Stream-Abruf auf der
Zielinstallation nachgewiesen werden, inklusive gültiger
Audio-Bytes und Wiedergabefortschritt. Weitere echte Lösungen
könnten aktualisierte unterstützte progressive Clients oder einen
korrekten HLS/SABR-Audiopfad erfordern. Solange die Extraktion
keine Medien-URL bzw. kein nutzbares Segment liefert, hilft ein
UI-/Lautstärke-Fix nicht.

## Für den iPhone-Test

1. Auf der bestehenden App zum schnellen Entlastungstest Automix
   ausschalten und aktive Downloads pausieren.
2. Einen Song einzeln starten. Optional einmal im WLAN statt 5G.
3. Nach dem signierten Build dieses PR-Branches in
   **Einstellungen → Playback → Musik spielt nicht?**
   den echten Status ansehen und Diagnosebericht speichern.
4. Auf `reason=` und `client_attempts=` in der Fehlerzeile achten.
5. Lokal gespeicherten Song als Kontrollversuch abspielen.
   Wenn lokal funktioniert und YouTube nicht, ist die
   Extraktionsstrecke der nächste Fixpunkt.

Dieses Update ist ein **separater Draft-PR gegen einen Review-Branch**.
Nichts nach `main` mergen, ohne ausdrückliche Anweisung.
