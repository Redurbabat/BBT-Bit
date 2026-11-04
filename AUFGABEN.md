# Offene Aufgaben

| ID | Aufgabe und Abnahme | Nachweis |
| --- | --- | --- |
| BBT-001 | Erste vollständige native Prüfmatrix auf Apple Silicon erfassen. Die Berichte nennen SHA, Xcode und Zielgerät. | Kotlin `:shared:macosArm64Test`, Rust `cargo test --locked`, iOS-XCUITest und XCResult |
| BBT-002 | „Training Season“ und zwei weitere YouTube-Titel am signierten iPhone-Build des Reparaturbranches prüfen. Danach Wiedergabe im Hintergrund, Ausgabewechsel und lokalen Offline-Titel prüfen. | [Echtgeräte-Prüfplan](docs/TESTPLAN.md#echtes-iphone) mit erstem Audiopuffer, Zeitfortschritt und hörbarem Audio. Bei Fehler die redigierten Resolver-Ergebnisse sichern. |
| BBT-003 | Agenten-Grundlage im eigenen PR nach `main` prüfen und durch den Maintainer übernehmen. | Agenten finden Regeln und Skills im Integrationsstand. Bestehende Arbeitsbranches können den Regelstand bei ihrer nächsten Synchronisierung übernehmen. |
