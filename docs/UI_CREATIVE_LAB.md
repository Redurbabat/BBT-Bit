# BBT-Bit · UI Creative Lab (isolierter Entwurfsbranch)

Stand: 2026-11-08. Ausgangspunkt: PR #50 (`feature/bitchord-v1-9-1-port-20261106`).

## Zweck und Grenzen

Dieser Branch ist ein isolierter, **nicht freigegebener** Experimentierraum. Änderungen bleiben als Draft-PR gegen PR #50 sichtbar; keine direkten Commits nach `main`, kein automatisches Merge. Wiedergabe, Queue, Streaming, Rust/Kotlin, Datenmodelle, Nutzerbibliothek und die drei Automix-Modelle werden für reine UI-Ideen nicht verändert. Vor jeder Implementierung prüfen, ob die Funktion schon existiert.

## Recherchierte Apple-Grundlagen

- Apple: [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) – `glassEffect`, `GlassEffectContainer`, `glassEffectID`; Glas nur für wichtige Bedienelemente, nicht für jede Inhaltskarte.
- Apple: [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass) – Systemmaterialien bevorzugen, Reduce Transparency / Reduce Motion beachten.
- Apple: [tabViewBottomAccessory](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory%28content%3A%29) – Mini-Player gehört auf neueren iPhones in das native Bottom Accessory, das zwischen normaler und kompakter Tabbar-Position wechselt.
- Apple: [TabBarMinimizeBehavior](https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior) – Scrollverhalten nativ lösen, nicht durch überlagerte Custom-Docks.

## Ideen-Backlog (Reihenfolge nach Nutzen und Risiko)

| Priorität | Idee | Konkretes UI-Verhalten | Risiko / Sicherheitsbedingung |
| --- | --- | --- | --- |
| P0 | Glass-Polish Mini-Player | Neutraler, nicht coverfarbener Glass-Look; kontrastreiche Symbole; konsistenter Übergang zwischen kompakter und erweiterter Tabbar | Nur SwiftUI, keine Änderung an Play/Pause-Bindings; native Bottom-Accessory-Platzierung erhalten |
| P0 | Queue Horizon 3D | Größere, lesbare Cover; fokussierte mittlere Karte; seitliche Cover erkennbar; sanfter Snap | Kein Queue-Reordering; komplexe View-Builder in kleine Subviews trennen, damit Swift kompiliert |
| P1 | Infinity Control | Neutrales Glass für Wiederholen, Shuffle, Infinity und Automix; ausgewählter Modus über Symbolzustand statt greller Hintergrundfarbe | Engine-Modus bleibt exakt an bestehenden Commands gebunden |
| P1 | Search Flow | Native Suche mit sofortigem Fokus, Recent Searches als klar zugängliche Karten und besserer Abstand zur Mini-Player-Leiste | Keine Änderungen an Suchprovider, Suchhistorie oder Persistenz |
| P1 | Musik-Details | Mehr Metadaten bei langer Berührung auf Cover, klare Künstler-/Album-Typografie | Nur bereits vorhandene Daten anzeigen, keine erfundenen Credits |
| P2 | Subtile Audio-Motion | Kleine, deaktivierbare Fortschritts- und Equalizer-Mikroanimationen | Nur echte Playback-States; keine simulierte Audiowiedergabe |
| P2 | Queue Gesten | Optionales Haptic Feedback bei Fokuswechsel im 3D-Karussell | Nur bei bestätigtem Fokuswechsel; Reduce Motion berücksichtigen |

## Designregeln

1. **Native zuerst:** SwiftUI-Systemkomponenten und Apple-Liquid-Glass-Effekte statt nachgebauter Fake-Island. iPhone 13 Pro Max hat eine Notch, keine Hardware-Dynamic-Island.
2. **Funktion vor Dekoration:** Niemals Playback-State, Audio-Ausgabe oder Stream-Erfolg visuell vortäuschen.
3. **Barrierefreiheit:** VoiceOver, Dynamic Type, Kontrast, Dark Mode, Reduce Motion und Reduce Transparency.
4. **Performance:** Keine schweren Blur-Stacks, keine unbeschränkten Animationen und keine komplexen SwiftUI-Expressions, die den Type-Checker überlasten.
5. **Isolierung:** Kleine, nachvollziehbare Commits; jeden visuellen Vorschlag mit Screenshots und Tests validieren, bevor er in PR #50 übernommen wird.

## Abnahme-Checkliste

- [ ] Swift-Syntaxprüfung auf geänderten Dateien
- [ ] Vollständige Swift/Xcode-Kompilierung
- [ ] iPhone-Simulator: 3D-Karussell, Mini-Player, Search, Tabbar, Infinity
- [ ] Reduce Motion / Reduce Transparency / VoiceOver
- [ ] Bestehende Queue- und Playback-Interaktionen
- [ ] Echtes iPhone 13 Pro Max: UI, Sperrbildschirm und 10+ Minuten hörbare Wiedergabe
- [ ] Signierte IPA

**Status:** Recherche und Entwurfsplanung dokumentiert. Sämtliche oben genannten Prüfungen sind für diesen Branch **NICHT GETESTET**. Keine UI-Implementierung durch dieses Dokument.
