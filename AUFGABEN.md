# Offene Aufgaben

| ID | Aufgabe und Abnahme | Nachweis |
| --- | --- | --- |
| BBT-001 | Erste vollständige native Prüfmatrix auf Apple Silicon erfassen. Die Berichte nennen SHA, Xcode und Zielgerät. | Kotlin `:shared:macosArm64Test`, Rust `cargo test --locked`, iOS-XCUITest und XCResult |
| BBT-002 | Streaming, Wiedergabe im Hintergrund und Ausgabewechsel am gleichen signierten iPhone-Build nachvollziehen. | [Echtgeräte-Prüfplan](docs/TESTPLAN.md#echtes-iphone) mit Play/Pause, Zeitfortschritt und hörbarem Audio |
| BBT-003 | Agenten-Grundlage im eigenen PR nach `main` prüfen und durch den Maintainer übernehmen. | Agenten finden Regeln und Skills im Integrationsstand. Bestehende Arbeitsbranches können den Regelstand bei ihrer nächsten Synchronisierung übernehmen. |
