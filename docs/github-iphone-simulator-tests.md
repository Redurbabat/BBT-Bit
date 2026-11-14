# BBT-Bit auf GitHub testen (auch vom Windows-PC aus)

Der Workflow `BBT-Bit iPhone Simulator UI Tests (GitHub)` benutzt
`macos-26` (Apple Silicon), Xcode und einen iPhone-Simulator.
Er installiert Java 21, XcodeGen, CMake und Rust, baut die
Kotlin/Native- und Rust-Simulator-Frameworks, generiert das
RED Bit-Xcode-Projekt und führt `xcodebuild test` aus.

## Öffnen

GitHub -> Redurbabat/RED-Bit -> Pull requests -> PR dieses Workflows.
Unter **Checks** oder **Actions** den Test anklicken.

Ein PR mit dem neuen Workflow löst den GitHub-Test automatisch aus,
sofern GitHub Actions im Repository freigeschaltet ist.
Der Workflow hat zusätzlich `workflow_dispatch` für manuelle Läufe,
sobald er von GitHub als Workflow zur Auswahl angeboten wird.

Nach Abschluss (auch bei Fehlern) das **Artifact**
`BBT-Bit-iPhone-Simulator-Results` herunterladen. Das ZIP enthält
sofern erzeugt:

- `BBT-Bit-Simulator-Testbericht.json` (strukturierte Ergebnisse)
- `BBT-Bit-Simulator-Testbericht.md`
- `xcodebuild.log` (Kompilier-/Testfehler)
- `xcresult-summary.json`, `xcresult-tests.json`
- `screenshots/` (XCTest-Bildanhänge)
- `last-simulator-screen.png` (letzter sichtbarer Simulatorzustand)

Das Artifact kann unter Windows geöffnet oder hier hochgeladen werden.

## Was wird überprüft?

Der Build kompiliert **die iOS-Simulator-Version von BBT-Bit**.
Dann startet der vorhandene XCTest-Launchparameter
`--bbt-ui-test-designs` die Offline-Ansicht, rendert 15 Liquid-Motion-
Design-Vorschauen und der XCUITest tippt die Vorschauen und
einige Bedienelemente an. Damit werden Syntax, iOS-Typechecking,
Linken, Simulator-App-Start, Navigation und Bildanhänge überprüft.

**Grenze:** Es werden nicht die 15 realen Streaming-/Handoff-Ereignisse
geprüft. Das sind Vorschau-Tests mit Beispieldaten, keine
End-to-End-Musikwiedergabetests und keine reale iPhone-Hardware.
Ein erfolgreicher Simulator-Test erzeugt außerdem keine installierbare
signierte IPA. Dafür bleibt Codemagic/Xcode-Archivierung zuständig.

Der macOS-Runner nutzt **GitHub-Actions-Minuten**. In einem privaten
Repository können dafür je nach Konto Kosten oder Kontingente entstehen.
Die erste Ausführung benötigt wegen Kotlin/Native und Rust ggf.
deutlich länger. Das Resultat ist erst aussagekräftig, wenn der
GitHub-Workflow tatsächlich erfolgreich durchläuft.

Weder der Test noch der zugehörige Draft-PR dürfen ohne ausdrückliche
Anweisung nach `main` gemergt werden.
