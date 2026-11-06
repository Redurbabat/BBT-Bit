# Offene Aufgaben

| ID | Aufgabe und Abnahme | Nachweis |
| --- | --- | --- |
| BBT-001 | Erste vollständige native Prüfmatrix auf Apple Silicon erfassen. Die Berichte nennen SHA, Xcode und Zielgerät. | Kotlin `:shared:macosArm64Test`, Rust `cargo test --locked`, iOS-XCUITest und XCResult |
| BBT-002 | Die Sprachkennung-Korrektur vom 5. November im frisch gebauten, signierten Reparaturbranch mit deutscher Gerätesprache prüfen. „Training Season“ und zwei weitere Titel starten, danach Hintergrund, Ausgabewechsel und lokalen Offline-Titel prüfen. | [Echtgeräte-Prüfplan](docs/TESTPLAN.md#echtes-iphone) mit Build-Revision, erstem Audiopuffer, Zeitfortschritt und hörbarem Audio. Der Live-HTTP-Vergleich ersetzt diese Abnahme nicht. |
| BBT-003 | Agenten-Grundlage im eigenen PR nach `main` prüfen und durch den Maintainer übernehmen. | Agenten finden Regeln und Skills im Integrationsstand. Bestehende Arbeitsbranches können den Regelstand bei ihrer nächsten Synchronisierung übernehmen. |
| BBT-004 | RED-Morph-Such- und Player-Nutzerweg in [PR #49](https://github.com/Redurbabat/BBT-Bit/pull/49) vollständig abnehmen: Top-Ergebnis darf beim Hinzufügen zur Playlist nicht starten, keine unnötigen Leerflächen, Keyboard-Pill verdeckt keine Inhalte; Pane-Wechsel und Mini-Player-Drag respektieren Reduce Motion. | [RED-Morph-Prüfmatrix](docs/red-morph-player-search-navigation.md), Xcode-Simulator-/Gerätetest, VoiceOver-Nachweis und separat bestätigte hörbare Audiowiedergabe; laufende CI-Fehler eingrenzen. |
