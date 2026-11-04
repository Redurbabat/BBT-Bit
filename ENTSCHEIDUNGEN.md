# Technische Entscheidungen

| ID | Datum | Entscheidung und Begründung |
| --- | --- | --- |
| E-001 | 2026-11-04 | AGENTS.md enthält die gemeinsamen Regeln. CLAUDE.md importiert sie und verweist auf projektspezifische Skills. Damit gibt es einen Ort für verbindliche Änderungen. |
| E-002 | 2026-11-04 | Vollständige Skills liegen unter `.agents/skills/`. Claude Code erhält kleine Markdown-Einstiege mit Verweisen. Reguläre Dateien funktionieren in Git-Checkouts unter Windows und macOS ohne Symlink-Unterstützung. |
| E-003 | 2026-11-04 | XcodeGen bleibt die Versionsquelle. Das Metadatenpaar in der Wurzel spiegelt den Kandidaten. IPA und DMG werden anhand der tatsächlich eingebetteten Metadaten geprüft. |
| E-004 | 2026-11-04 | Swift-Quellordner sind Verantwortungsbereiche innerhalb des App-Targets. Die durch Build-Konfiguration prüfbaren Grenzen liegen zwischen App, Widget, Kotlin-XCFramework und Rust-FFI. |
| E-005 | 2026-11-04 | Die Architekturprüfungen verwenden die vorhandenen GitHub-Workflows. Codemagic bleibt der bestehende IPA-Bauweg. Die Freigabe bleibt beim Maintainer. |
