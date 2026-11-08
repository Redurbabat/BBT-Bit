# Erledigte Aufgaben

## 2026-11-08 · RED-Bit-PRs im eigenen Branch integriert, Motion und Logo überarbeitet

Die offenen PRs #54, #57 und #58 sind auf dem aktuellen `main` im eigenen Integrationsbranch zusammengeführt. Korrigiert sind die vorzeitige Dock-Minimierung bei neuer Berührung, verlorene langsame Scrollbewegungen sowie die fehlende eigene Glasfläche der Tastatur-Pill. Die obere Insel nutzt den gemessenen Logo-Ursprung und einen direkten kompakten Scroll-Einstieg. Ein neuer eigener Vektor-Marker ist in App-Icon und In-App-Logo eingebunden. Lokale Struktur-, Release-, SideStore-, Übersetzungs- und Quellprüfungen bestehen. [Analyse, Regressionen, offene Cloud- und Geräteprüfungen](docs/RED_BIT_INTEGRATION.md). **Kein Merge nach main.**

## 2026-11-07 · Cloud-Bau und SideStore-Gerätetest vorbereitet

Der neue Workflow verwendet die bestehenden nativen Bauskripte und eine ausschließlich generierte SideStore-Konfiguration. Bundle-ID, App-Quellen und lokale Datenformate bleiben bestehen; die kostenlose Testvariante enthält keine Widget-Erweiterung oder iCloud-/App-Group-Freigaben. Acht ausgeführte Fixture-Tests und Actionlint bestehen. Der aktuelle GitHub-Lauf meldet eine Actions-Budgetsperre. **Echte IPA-Erzeugung, Signierung, Installation, Update und Audio sind NICHT GETESTET.** Redion wurde ausschließlich gelesen und enthält bereits einen Capacitor-iOS-Wrapper. [Anleitung, offene Voraussetzungen und Prüfstand](docs/IPHONE_TESTSYSTEM.md)

## 2026-11-05 · YouTube-Anfragen bei deutscher Gerätesprache

Der neue Gerätebericht führte zur fehlerhaften Übergabe regionaler Apple-Sprachkennungen. Im kontrollierten Live-Vergleich scheiterte `hl=de-CH`, während derselbe Titel mit `hl=de` und unverändertem `gl=CH` echte progressive Audio-Bytes lieferte. Die Umwandlung ist korrigiert, 12 gezielte Kotlin-Fixtures und der Metadatenbau der echten Module bestehen. Ein zusätzlicher Cachetest verhindert veraltete Extractor-Frameworks. Der korrigierte iPhone-Build bleibt **ECHTGERÄT NICHT GETESTET**. [Befund, Änderungen und Prüfstand](docs/claude-youtube-playback-handoff-20261104.md#nachuntersuchung-am-5-november-2026)

## 2026-11-04 · Deutsch als App-Vorgabe

[AGENTS.md](AGENTS.md) legt Englisch für Codebezeichner und Deutsch für Texte an Menschen fest. App, Einstellungen und Liedtext-Übersetzung verwenden dieselbe Sprachvorgabe. Gespeicherte Einstellungen haben Vorrang. Die Katalogprüfung bestätigte 36 neue deutsche Einträge, die vorhandenen Übersetzungen und die Platzhalter der geänderten Meldungen. Der Swift-Test für Deutsch, eine gespeicherte Sprache und Gerätesprache ist eingerichtet. **iOS und macOS NICHT GETESTET.** Ältere App-Texte ohne deutschen Katalogeintrag können weiterhin englisch erscheinen. [Sprachregeln](docs/DESIGN_SYSTEM.md#sprache)

## 2026-11-04 · Progressive YouTube-Kandidatenauswahl und Wiederholungen

Die Auswahl prüft eine Antwort auf progressives Audio, bevor sie weitere Profile verwirft. Kotlin, Swift und Downloadtests decken die betroffenen Übergänge ab. Der Kotlin-JVM-Test zeigte zwei Fehlschläge vor der Änderung und sieben bestandene Fälle mit dem Fix. Der Live-Nachweis und der native Prüfstand sind separat erfasst. [Fehleranalyse und Prüfstand](docs/claude-youtube-playback-handoff-20261104.md#analyse-und-prüfstand-des-reparaturbranches)

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

Die [GitHub-Regressionen für `c294252`](https://github.com/Redurbabat/BBT-Bit/actions/runs/41833137474) sind `BESTANDEN`. Die Jobs prüften Netzwerkfehler, Google-Anmeldeidentität, Release-Shellsyntax, Doku, Skills, Version, Modulgrenzen, Herkunft und Geheimnisse.

Der [Apple-Silicon-Lauf für `c294252`](https://github.com/Redurbabat/BBT-Bit/actions/runs/41833137485) erreichte `SYNTAX GEPRÜFT` für die ausgewählten Swift-Dateien. Simulator-, Kotlin- und Rust-Ergebnisse stehen in diesem Lauf. BBT-001 bleibt bis zur Auswertung offen.

## 2026-11-07 · Cloud-Bau und SideStore-Gerätetest vorbereitet
Der neue Workflow verwendet die bestehenden nativen Bauskripte und eine ausschließlich generierte SideStore-Konfiguration. Bundle-ID, App-Quellen und lokale Datenformate bleiben bestehen; die kostenlose Testvariante enthält keine Widget-Erweiterung oder iCloud-/App-Group-Freigaben. Acht ausgeführte Fixture-Tests und Actionlint bestehen. Der aktuelle GitHub-Lauf meldet eine Actions-Budgetsperre. **Echte IPA-Erzeugung, Signierung, Installation, Update und Audio sind NICHT GETESTET.** Redion wurde ausschließlich gelesen und enthält bereits einen Capacitor-iOS-Wrapper. [Anleitung, offene Voraussetzungen und Prüfstand](docs/IPHONE_TESTSYSTEM.md)
