# Offene Aufgaben

| ID | Aufgabe und Abnahme | Nachweis |
| --- | --- | --- |
| BBT-001 | Erste vollständige native Prüfmatrix auf Apple Silicon erfassen. Die Berichte nennen SHA, Xcode und Zielgerät. | Kotlin `:shared:macosArm64Test`, Rust `cargo test --locked`, iOS-XCUITest und XCResult |
| BBT-002 | Streaming, Wiedergabe im Hintergrund und Ausgabewechsel am gleichen signierten iPhone-Build nachvollziehen. | [Echtgeräte-Prüfplan](docs/TESTPLAN.md#echtes-iphone) mit Play/Pause, Zeitfortschritt und hörbarem Audio |
| BBT-003 | Mit dem Maintainer die Basis für den späteren Draft-PR festlegen. Den isolierten Architektur-Diff und die Prüfmatrix im Review nachvollziehen. | Vergleich mit dem aktuellen Integrationsstand und Prüfung auf Überschneidungen |
