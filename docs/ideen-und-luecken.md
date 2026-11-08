# Ideen und Lücken (Stand 08.11.2026)

Alles hier ist **Vorschlag**, nichts davon ist gebaut oder auf dem Gerät geprüft. Die Lücken sind belegt: Das jeweilige Apple-Framework wird in `AppleApp/Sources` nirgends importiert (Suche `import <Framework>`).

## Fehlende Plattformfunktionen

| Lücke | Nutzen für BBT-Bit | Hinweis |
| --- | --- | --- |
| **CarPlay** | Musik im Auto mit eigener Queue und Bibliothek | Braucht das CarPlay-Audio-Entitlement von Apple (Antrag, nicht sofort verfügbar). |
| **Apple Watch** (WatchKit) | Play, Pause, Skip, Titel am Handgelenk | Eigenes Ziel, größerer Umbau. Zuerst Steuerung über `MediaPlayer` prüfen. |
| **SharePlay** (GroupActivities) | „Zusammen hören“ direkt in FaceTime | Listen Together existiert schon; SharePlay wäre ein zweiter Einstieg, kein Ersatz. |
| **Haptik** (CoreHaptics) | Taktschlag spüren, passend zu Beat und Downbeat | Beat-Daten liefert die vorhandene Beat-This-Analyse für Automix schon. |
| **ShazamKit** | „Welcher Song läuft hier?“ und direkt in die Queue | Mikrofonberechtigung nötig, Text im Berechtigungsdialog ergänzen. |
| **Spotlight-Index** (CoreSpotlight) | Playlists und Künstler aus der iOS-Suche starten | Nur lokale Metadaten, keine Streams. |
| **TipKit** | Neue Modi (Konstellation, Karussell) erklären statt verstecken | Kleine, ruhige Hinweise. |

## Kreative Ideen, die auf Vorhandenem aufbauen

1. **Beat-Puls in der Lyrics-Konstellation:** Der aktuelle Stern pulsiert auf dem Downbeat, Haptik optional. Daten sind vorhanden, es fehlt nur die Verdrahtung.
2. **Karussell auf Home und Bibliothek:** `HorizonRailMotion` ist wiederverwendbar; auf Künstlerseiten zuerst testen, dann pro Bereich freigeben.
3. **Bogen-Scrubber** (aus dem zweiten Video): Halbkreis mit Teilstrichen und roter Nadel im Vollplayer, als Alternative zur Zeitleiste. Noch nicht umgesetzt.
4. **Sternbild je Song als Teilen-Karte:** Die Konstellation einer Zeile als Bild exportieren; `LyricShareCard` zeigt den Weg.

## Kostenlose KI, die kein Chat ist

| Kandidat | Wofür | Stand der Prüfung |
| --- | --- | --- |
| **Apple Foundation Models** (Gerätemodell, iOS 26) | Aus „etwas Ruhiges zum Lernen“ eine strukturierte Suche machen, Playlist-Titel, Stimmungs-Tags aus Lyrics | Kostenlos und ohne Download laut Entwicklerberichten, **nicht gegen Apples Dokumentation geprüft**. Läuft nur auf Geräten mit Apple Intelligence (ab iPhone 15 Pro). **Das iPhone 13 Pro Max aus BBT-SIDE-001 gehört nicht dazu.** |
| **Spleeter (PyTorch-Port, MIT)** | Gesang vom Rest trennen (Karaoke), Core-ML-Export möglich | Lizenz laut Projektseite MIT; Qualität laut Entwickler unter dem Original; Gewichte und deren Lizenz **noch prüfen**. |
| **UVR MDX-Net (Core ML)** | Gesang/Instrumental auf dem Gerät | Lizenz in den Ergebnissen **nicht genannt**, vor jeder Übernahme beim Ursprungsprojekt klären. |
| **Open-Unmix** | Trennung in Gesang, Schlagzeug, Bass, Rest | Das Projekt nutzt es bereits (`umxhq`); Erweiterung auf weitere Stems prüfen. |
| Stimmung, Genre, Tonart als Core-ML-Modell | Auto-Tags, „Passt zu diesem Song“ | **Kein permissiv lizenziertes Modell gefunden.** Gängige Modellgewichte sind oft nur nicht-kommerziell; nicht übernehmen, bevor die Lizenz belegt ist. |

Regel aus [AGENTS.md](../AGENTS.md): Herkunft und Lizenz vor der Übernahme prüfen, Modelle mit SHA-256 und Größe festschreiben (wie bei den Automix-Modellen).
