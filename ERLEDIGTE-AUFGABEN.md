# Erledigte Aufgaben

## 2026-11-04 · Agenten- und Prüfgrundlage

- Die Dokumente trennen Arbeitsregeln, offene und abgeschlossene Arbeit, Entscheidungen, Fehler, Lücken und Fremdcode. Die Skills verbinden SwiftUI- und BBT-Bit-Aufgaben mit bestehenden Einstiegspunkten und Tests.
- Betroffen sind die Einstiegsdokumente, `.agents/skills/`, `.claude/skills/`, [Versionsmetadaten](version.md), der [Repo-Validator](scripts/check-repository.py) und die [bestehenden Actions-Workflows](.github/workflows/). Das Review-Risiko liegt bei CI-Laufzeiten und der Abgrenzung der statischen Prüfungen. Es gab keine Änderungen an Nutzerdatenformaten, Wiedergabe, Navigation oder Plattformzielen.

| Lokale Prüfung unter Windows | Ergebnis |
| --- | --- |
| `python scripts/check-repository.py --base HEAD` | `BESTANDEN` für Doku-Links, Skills, App-/Widget-Version, Modulgrenzen und Herkunftsprüfung |
| `python scripts/repository-verify/check.py -v` | `BESTANDEN`, sieben Gegenproben |
| `python scripts/release-verify/check.py` | `BESTANDEN`, Metadaten und Prüfsummen mit Fixture-Artefakten |
| `quick_validate.py` aus dem Skill Creator | `BESTANDEN`, zehn Skills und zehn Claude-Einstiege |
| `actionlint .github/workflows/pr-regressions.yml .github/workflows/ios-simulator-tests.yml` | `BESTANDEN` |
| `git diff --cached --check` und gestagter Diff mit `gitleaks stdin --redact=100` | `BESTANDEN`, keine Funde |
| Swift, Kotlin/Native, Rust und iOS-Simulator | `NICHT GETESTET` auf diesem Windows-Rechner. Die Apple-CI-Nachweise stehen in [AUFGABEN.md](AUFGABEN.md). |
| Echtes iPhone, Signierung und Auslieferung | `NICHT GETESTET`. Dafür ist ein signierter Build und ein Geräteprüflauf erforderlich. |
