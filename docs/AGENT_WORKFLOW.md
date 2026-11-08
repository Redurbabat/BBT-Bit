# Agenten-Workflow

## Vor jeder Änderung

1. Branch, Arbeitsbaum und letzte Commits nach [AGENTS.md](../AGENTS.md) prüfen. Einen neueren Stand von `main` nur nach Prüfung der Überschneidungen in den eigenen Branch übernehmen.
2. Aufgabe und Abnahme klären. Vorhandene Funktion, Architektur, bekannte Probleme, Datenflüsse und Tests suchen. Passenden Skill lesen.
3. Risiken für Nutzerdaten, Wiedergabe, Navigation, Kompatibilität und parallele Arbeit benennen. Bei derselben Datei mit einem zweiten Agenten die Überschneidung festhalten und beide Absichten beim Review erhalten.

## Während und nach der Änderung

1. Bei einem Fehler einen reproduzierbaren Fall isolieren und möglichst zuerst einen Test schreiben, der am alten Verhalten scheitert. Kleine Änderungen über den normalen Aufrufpfad prüfen. Fixtures ausdrücklich als solche kennzeichnen.
2. Die Prüfungen der betroffenen Zeilen aus dem [Testplan](TESTPLAN.md) ausführen. Pro Nachweis Befehl, Ergebnis, Revision, Plattform und Artefakt nennen. Fehlende Prüfungen als `NICHT GETESTET` eintragen.
3. Erfüllte Aufgaben mit betroffenen Dateien, Zweck, Testbelegen und verbleibenden Risiken in [ERLEDIGTE-AUFGABEN.md](../ERLEDIGTE-AUFGABEN.md) erfassen. Teilaufgaben und fehlende Abnahmekriterien bleiben in [AUFGABEN.md](../AUFGABEN.md). Entscheidungen, Fehler, Lücken und Herkunft separat pflegen. Versionsdaten nur nach den [Release-Regeln](RELEASE.md) ändern.
4. Vor dem Commit erneut den Branch und den gestagten Diff prüfen. Größere Änderungen für einen Draft-PR mit dem vereinbarten Review-Ziel vorbereiten. Der Text enthält Umfang, Abnahmekriterien, Prüfmatrix, offene Nachweise, Risiken und Überschneidungen.

## Skill-Auswahl

Codex entdeckt die vollständigen Skills aus [`.agents/skills/`](../.agents/skills/). Claude Code entdeckt [`.claude/skills/`](../.claude/skills/). Jeder **BBT-Bit-Skill** hat einen kanonischen Eintrag und einen Claude-Verweis. Name und Beschreibung müssen übereinstimmen. Auf einem Mac können **sämtliche offiziell aus Xcode exportierten Apple-Skills** optional mit dem [lokalen Importwerkzeug](APPLE_XCODE_SKILLS.md) in beide Verzeichnisse kopiert werden; sie werden absichtlich nicht im Git-Repository verteilt. Bei Konflikten gelten die Projektregeln einschließlich der nativen RED-Morph-Scrollanimation. In einer bereits geöffneten Sitzung bei Bedarf den Skill direkt lesen. [Codex-Dokumentation](https://learn.chatgpt.com/docs/build-skills) · [Claude-Code-Dokumentation](https://code.claude.com/docs/en/skills)

| Aufgabe | Skill |
| --- | --- |
| Wiederverwendbare native Komponente | [swiftui-component-smith](../.agents/skills/swiftui-component-smith/SKILL.md) |
| Choreografie und unterbrechbare Gesten | [swiftui-motion-director](../.agents/skills/swiftui-motion-director/SKILL.md) |
| Neue native Produktideen | [swiftui-idea-lab](../.agents/skills/swiftui-idea-lab/SKILL.md) |
| Native Nutzerwege und Accessibility prüfen | [swiftui-ux-auditor](../.agents/skills/swiftui-ux-auditor/SKILL.md) |
| Transport, Queue, Mini- und Vollplayer | [bbt-player](../.agents/skills/bbt-player/SKILL.md) |
| Resolver, Innertube, Netzwerk und Sitzungen | [bbt-streaming](../.agents/skills/bbt-streaming/SKILL.md) |
| Rust-Decoder, DSP, Mixer und Ausgabe | [bbt-audio-engine](../.agents/skills/bbt-audio-engine/SKILL.md) |
| Glass Bloom, Cover Morph und BBT-Bit-Motion | [bbt-liquid-motion](../.agents/skills/bbt-liquid-motion/SKILL.md) |
| XCUITest, Simulator und Hardware | [bbt-ios-testing](../.agents/skills/bbt-ios-testing/SKILL.md) |
| Versionsstand, IPA, DMG und Signierung | [bbt-release](../.agents/skills/bbt-release/SKILL.md) |
