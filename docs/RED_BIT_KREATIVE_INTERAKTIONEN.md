# RED Bit · zwölf kreative Interaktionen

Auftrag vom 8. November 2026, PR #59, Branch `codex/red-bit-integration-motion-20261108`.
Die öffentlichen React-Bits-Pro-Vorschauen dienen als visuelle Referenz. Es werden weder Pro-Quellcode noch Demo-Medien übernommen. Die folgenden Komponenten entstehen eigenständig mit SwiftUI, Canvas und eigenen Shadern.

| Nutzerweg | Umsetzung und reale Datenquelle | Abnahme |
| --- | --- | --- |
| Lyrics | Look nach Nutzerreferenz (Bildschirmaufnahme 05.11.2026): schwarz, jede Liedzeile ein eigenes Sternbild aus geraden Linien, kleine Beschriftung je Stern, aktuelles Wort groß in Serifen mit weichem Leuchten über einem Funkelstern; das vorige Wort schrumpft in seine Beschriftung, alte Zeilen gleiten nach links oben. Dazu: Wortabstand nach Beats (halbe Schläge gerastet), Höhe nach gemessener Gesangstonhöhe (YIN in `lyric_voice_contour`, sonst Klangfarbe, sonst Zeilenbogen je Song), Sterngröße nach Pegel, Farbe nach Stimmlage. Nach links wischen öffnet den Verlauf; dort folgt der Inhalt dem Finger, über das aktuelle Wort hinaus geht es live weiter. Letzte zehn Sekunden: Route faltet sich zur Karte, ein Blitz läuft in gut einer Sekunde durch alle Sterne, danach Nachglühen im Beat. Streams ohne lokale Datei werden nicht erneut geladen | Pause, Seek, Verlauf vor Schlussblitz, zehn Sekunden, Songende, Listen-Rückweg, Reduce Motion (statische Karte) |
| Bibliothek / Entdecken | Galaxie nach Gerätevideo vom 11.11. überarbeitet: Sternstaub in drei Tiefen, 420 additiv leuchtende Spiralpartikel und heller Kern, Farbe aus dem Cover der Auswahl (Palette), langsames Treiben der Scheibe (aus bei Reduce Motion). Cover auf geneigter Bahn größer mit Glaskante; Auswahl unter getönter Glaslinse mit Leuchten; Aktionsknopf in Galerie und Regal klein und gläsern (Trefferfläche 44 pt). Entdecken: frei drehbar mit Einrasten | Leere Daten, ein Element, Datenwechsel, VoiceOver, Reduce Transparency/Motion |
| Start / Künstler | Plattenregal mit Liquid-Glass-Linse wie im Dock (Gerätevideo 11.11.: Glasbühne wirkte als grauer Block, Hüllen überdeckten sich). Die gewählte Hülle steht in der Glaslinse; beim Wechsel dehnt sich die Linse flüssig in Laufrichtung, ein Lichtstreif zieht über das Glas, Nachbarhüllen gleiten flach daneben ohne Überlappung, die Platte gleitet in die Hülle und rollt oben wieder heraus. Platte dreht nur bei tatsächlicher Wiedergabe dieses Albums | Auswahl, Öffnen, Kontextmenü, schnelles Wischen, reduzierte Bewegung und Transparenz |
| Vollplayer | Eigene gläserne Übergangslinse beim bestätigten Titelwechsel | Schneller Skip, fehlendes Cover, Video bleibt bedienbar |
| Automix | Lichtfäden zwischen echten Queue-Covern im vorhandenen Detailsheet; Fortschritt aus Engine-Zeitfenster. Beim Mischen tritt das alte Cover zurück, das neue nach vorn, Fäden schwellen in der Mitte an und Lichtpunkte laufen exakt auf den Bézierfäden | Geplant / aktiv / beendet, kein erfundener Fortschritt |
| Warteschlange | Coverbogen aus der vorhandenen Queue mit unverändertem Index-Callback und erhaltener Listenbearbeitung; beim Umlauf über das Queue-Ende blendet eine Karte am anderen Rand neu ein, statt quer durch das Karussell zu fliegen | Doppelte Titel, Queue-Änderung, Auswahl, Party-Sperre |
| Suche | Native Zoom-Navigation vom Sammlungsergebnis zur Detailseite | Öffnen, Zurück, Suchfeld bleibt frei |
| Playlist | Auffächerbare Cover aus tatsächlichen Playlist-Songs mit vorhandenem Queue-Start; Stapel und Reihe teilen die Cover-Identität (`matchedGeometryEffect`), jedes Cover fliegt aus dem Stapel an seinen Platz | Auf-/Zuklappen, Auswahl, leere Playlist |
| Favoriten | Kurzer Sternimpuls erst nach bestätigtem Speichern | Fehler, Entfernen, Wiederholung, reduzierte Bewegung |
| Downloads | Coverbewegung beim Übergang eines tatsächlichen Jobs in den fertigen Zustand | Fehler und laufende Jobs erzeugen keinen Erfolg |
| Gemeinsam hören | Teilnehmer um das aktuelle Cover; Rollen und Verbindung aus PartyStore | Beitritt, Austritt, Auswahl, kleine Breite |
| Einschlaftimer | Verdunkelnder Mond aus echter Restzeit; vorhandene Start-/Abbruchaktionen | Ablauf, Änderung, Abbruch, nach diesem Titel |

## Gemeinsame Regeln

Ein Elternzustand bleibt Eigentümer von Wiedergabe, Queue und Navigation. Kein neuer Player, keine Schemaänderung an Musikdaten. Keine zusätzlichen System-Docks. Große Effekte liegen in Inhaltsansichten; der native Mini-Player behält neutrales Systemglas. Bei reduzierter Bewegung erscheinen statische Cover, Text und echte Zustandswerte. Bei Fehlern bleibt die vorhandene Fehlermeldung erreichbar. Touch-Ziele mindestens 44 pt; Pfeile und Schaltflächen ergänzen Gesten, macOS bleibt per Tastatur und VoiceOver bedienbar. Deutsch ist die Vorgabe, gespeicherte Sprachwahl bleibt erhalten.

## Prüfung

### Sternroute und Schlusszoom

Alle Knoten stammen aus den tatsächlichen Zeitmarken des gesamten Songtexts und behalten beim Blättern dieselbe Lage. Ohne echte Wortzeiten ist eine ganze Zeile ein Knoten; Wörter erhalten keine erfundenen Zeitabstände. Lichtimpulse folgen vorhandenen Beat-Markern, sonst ausschließlich den Lyrics-Zeitmarken. Die Anzeige benennt diese Datenquelle.

Zehn Sekunden vor dem echten Titelende wechselt die Kamera automatisch von der Nahansicht zur ganzen Songkarte. Der Lichtkopf beginnt beim ersten Knoten und erreicht den letzten mit dem Songende. Fortschritt ergibt sich aus der Wiedergabeposition, nicht aus einem separat laufenden Timer. Pause hält den Lichtweg an; Zurückspulen verlässt das Finale. Früheres Blättern verhindert den automatischen Schlusszoom nicht. Sichtbare Pfeile, aktuelle Zeile und Kartenknopf ergänzen die Wischgeste. Bei reduzierter Bewegung bleibt die Gesamtansicht ruhig.

### Begrenzter FFI-Lesezugriff

`cached_beat_times` liefert nur bereits vorhandene Marker der unveränderten Quelldatei aus dem Rust-Analyse-Cache. Der Zugriff läuft außerhalb des Hauptthreads und des Audio-Callbacks; er startet weder Download, Decode noch Inferenz und wartet nicht auf laufende Analysen. Ohne Cache-Eintrag bleibt die Markerfolge leer. Dateigröße und Änderungszeit verhindern die Übernahme von Markern einer inzwischen veränderten Datei. Die Swift-Bindings werden über das vorhandene Buildskript neu erzeugt. Decoder, Mixer, Analyseplanung und Datenformate ändern sich nicht. Neue Rust-Regression: leere Quelle, sortierte endliche Marker, geänderte Datei.

### Gezielte Abnahme

1. Sammlung mit null, einem und mehreren Einträgen; Pfeile, Wischen, Öffnen und Rückkehr prüfen. Alte Kartenansicht bleibt wählbar.
2. Playlist-Fächer und Queue-Auswahl mit doppelten Titeln prüfen; während gesperrter Party darf kein neuer Titel starten.
3. Favoritenfehler und Downloadfehler dürfen keinen Erfolgseffekt zeigen. Wiederholtes Öffnen spielt keinen alten Favoriteneffekt ab.
4. Lyrics von aktueller Stelle nach links blättern, dann ohne weitere Aktion in die letzten zehn Sekunden gelangen; automatische Gesamtkarte und vollständigen Lichtweg bei 100 % prüfen.
5. Pause, Vor-/Zurückspulen, Titelwechsel, fehlende Wort-/Beat-Zeiten sowie Sprachwahl und Listen-Rückkehr prüfen.
6. Kleine Breite, große Schrift, VoiceOver, reduzierte Bewegung/Transparenz und macOS-Tastatur getrennt prüfen.
7. Native Suche mit sichtbarer Tastatur und tatsächlichem Suchfeld messen; beim Scrollen native Tab-Aktionen gegen Mini-Player-Trefferflächen prüfen.

Der neue Debug-Nutzerweg `--red-ui-test-creative` zeigt Produktionskomponenten mit ausdrücklich gekennzeichneten lokalen Prüfdaten. Seine Zeitknöpfe prüfen 70/75/80 Sekunden eines 80-Sekunden-Fixtures; sie belegen keine Audioanalyse oder Musikwiedergabe.

Der Ausgangsstand `c1f991d` kompiliert vollständig. Im Simulator scheitern Suchfeld-Überlagerung, die Tab-Erkennung des Dock-Tests und die durch einen Container überschriebene Kennung des Lyrics-Listenknopfs. Diese Fälle werden vor der Abnahme korrigiert und erneut geprüft. Top-Ergebnis-Höhenprüfung und die 15 bisherigen Designvorschauen bestehen bereits.

Die neuen Effekte benötigen Swift-/Shader-Build, gezielte Geometrieprüfungen und Simulator-Screenshots. **Echtes iPhone, VoiceOver am Gerät, Leistungsaufnahme und hörbare Audiowiedergabe bleiben bis zur Durchführung NICHT GETESTET.**

### Tatsächlich ausgeführt · 8. November 2026

Arbeitsstand `e64efdb` mit anschließendem Review der Cover-Identität, bestätigten Favoriten und des Cache-Lesezugriffs:

| Prüfung | Ergebnis |
| --- | --- |
| `python scripts/check-repository.py --base origin/main` | BESTANDEN: Dokumentstruktur, Verweise, Version, Modulgrenzen und Herkunft |
| `python scripts/repository-verify/check.py` | BESTANDEN: sieben Gegenproben. Unter Windows `TEMP`/`TMP` auf `build/test-tmp` gesetzt; der erste Versuch im gesperrten System-Temp war ein Umgebungsfehler. |
| `python scripts/release-verify/check.py` | BESTANDEN: Release-Identitäts-Fixtures; keine echte IPA erzeugt |
| `python scripts/check-red-morph-source.py` / `python scripts/check-native-island-source.py` | BESTANDEN: je acht bestehende Quellinvarianten |
| `python scripts/verify-settings-german.py` und neue Katalogeinträge | BESTANDEN: deutsche Einstellungen sowie neue Karten-/Musiktexte; gespeicherte Sprachwahl erhalten |
| Sechs Workflow-YAMLs und Python-Prüfblock aus `validate-codemagic.yml` | BESTANDEN: YAML, native Buildabhängigkeiten, bestehende Produktidentität und IPA-Namen |
| `git diff --check` | BESTANDEN |
| Neuer Swift-/Kotlin-/Rust-App-Build, Shader, Geometrie-Ausführung und XCUITests | **NICHT GETESTET**: GitHub startet keine Runner wegen Actions-Budgetsperre. Windows/WSL enthalten hier keinen Swift-/Rust-Compiler oder Xcode. |

GitHub meldet wörtlich: „The job was not started because an Actions budget is preventing further use.“ Betroffen sind [iPhone-Simulator](https://github.com/Redurbabat/RED-Bit/actions/runs/42524297188), [Regressionen](https://github.com/Redurbabat/RED-Bit/actions/runs/42524297234) und [Build-Konfiguration](https://github.com/Redurbabat/RED-Bit/actions/runs/42524297279); es wurde kein einziger Buildschritt ausgeführt. Die Anzeigen „failure“ sind deshalb **kein ausgeführter Code- oder Testerfolg**. Keine kostenpflichtigen Runner gestartet und kein Budget verändert. Nach verfügbarer Kapazität dieselben Prüfungen am aktuellen PR-Kopf erneut ausführen.

Die Source-Review-Korrekturen halten das alte Cover im Vollplayer über den bestehenden titelgebundenen Video-Neuaufbau hinweg, lassen eine Download-Ankunft tatsächlich als Einfügeübergang erscheinen und verwerfen eine inzwischen entfernte Audioquelle. Die Beat-Abfrage bleibt eine Aktion der PlaybackSession. Die nativen Build- und Gerätenachweise bleiben ausdrücklich offen, Aufgabe BBT-021 bleibt in der Aufgabenliste.
