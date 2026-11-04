# BBT-Bit · Regeln für Coding-Agenten

- Prüfe zu Beginn jeder Sitzung `git status --short --branch`, die letzten Commits und [offene Aufgaben](AUFGABEN.md). Prüfe vor jedem Commit den Branch erneut.
- Der laufende Architekturauftrag verwendet ausschließlich `codex/longterm-architecture-20261104`. Andere Arbeitsbranches sind lesbar. Commits und Pushes bleiben auf dem zugewiesenen Branch. Ein Merge nach `main` erfordert die ausdrückliche Anweisung des Maintainers.
- Erhalte fremde Änderungen, bestehende Dateien, Nutzerfunktionen und Daten. Vermeide Force-Push, Hard Reset und pauschales Clean. Dokumentiere Überschneidungen mit anderen Agenten und löse Konflikte anhand beider Absichten. Größere Verschiebungen oder Audio-Umbauten brauchen einen eigenen Plan.
- Lies [Einstieg](AI_START_HERE.md), die betroffenen Abschnitte der [Architektur](docs/ARCHITEKTUR.md), passende Skills und den [Arbeitsablauf](docs/AGENT_WORKFLOW.md). Suche zuerst nach vorhandener Funktion, Tests und dokumentierten Fehlern. Prüfe Risiken für Daten, Wiedergabe, Navigation und Plattformen.
- Beschränke den Diff auf den Auftrag. Bei reproduzierbaren Fehlern möglichst erst einen Regressionstest schreiben und den Fehler damit nachweisen. Prüfe Herkunft und Lizenz neuer Komponenten vor der Übernahme. Datenformate brauchen eine Migrationsstrategie.
- Führe die betroffenen Prüfungen aus und protokolliere Befehl, Ergebnis und fehlende Nachweise. [Testplan](docs/TESTPLAN.md) und [Release-Regeln](docs/RELEASE.md) unterscheiden Quellprüfung, Simulator, Hardware und Auslieferung.
