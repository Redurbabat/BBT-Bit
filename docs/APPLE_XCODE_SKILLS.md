# Apple Xcode-Agent-Skills für BBT-Bit

## Stand und Quellen

**Status: Import vorbereitet; Apple-Inhalte NICHT exportiert oder installiert.** Die eigentlichen Apple-`SKILL.md`-Dateien gehören zum lokalen Xcode und sind nicht Bestandteil dieses GitHub-Branches. Xcode 27+ liefert von Apple erstellte Spezialisten und unterstützt den Markdown-Export per `xcrun agent skills export`.

- [Apple WWDC26: What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/) – SwiftUI Specialist und What's New in SwiftUI.
- [Apple WWDC26: Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/) – Modernisierung und Skill-Export.
- [Apple Xcode 27 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes) – Skills/Spezialisten und aktuelle Einschränkungen.

Die Namen **variieren je nach Xcode-Version**. Xcode 27 exportierte beispielsweise diese sieben Skills, die dieses Projekt sämtlich akzeptiert:

| Exportname (Xcode 27) | BBT-Bit-Einsatz |
| --- | --- |
| `swiftui-specialist` | SwiftUI-Views, State, Performance, Komponenten |
| `swiftui-whats-new-27` | Neue SwiftUI-APIs, iOS-/macOS-27-Verfügbarkeit; keine ungeprüfte API-Migration |
| `uikit-app-modernization` | Größenklassen, Scene-Lifecycle, Apple-UI-Interoperabilität |
| `test-modernizer` | Swift Testing / XCTest, Teststruktur |
| `device-interaction` | Simulator und echtes iPhone: Tastatur, Scroll-Morph, Wiedergabe-UI |
| `audit-xcode-security-settings` | XcodeGen-Build-Einstellungen und Sicherheitsprüfung |
| `c-bounds-safety` | FFI-/C-Grenzen und Speicher-/Bounds-Sicherheit, nicht pauschal Rust ändern |

In neueren Xcode-Versionen können etwa `app-resizability`, `modernize-tests` oder `adopt-c-bounds-safety` an die Stelle älterer Namen treten. **Nicht beide Versionen desselben Skills gleichzeitig verwenden**, ohne ihre Anwendbarkeit zu prüfen. Der Installer übernimmt alle `SKILL.md`-Ordner, die die tatsächlich installierte Xcode-Version exportiert; keine fest verdrahtete Liste beschränkt den Import.

## Alle Skills lokal einrichten (Mac mit Xcode 27 oder neuer)

Im eigenen BBT-Bit-Git-Checkout auf dem **zugewiesenen Feature-Branch**:

```bash
# Welche Version ist ausgewählt?
xcode-select -p
xcodebuild -version

# Verfügbare Apple-Skills anzeigen, ohne Dateien zu verändern.
python3 scripts/install-apple-xcode-skills.py --from-xcode --dry-run

# Alle von dieser Xcode-Version angebotenen Skills installieren.
python3 scripts/install-apple-xcode-skills.py --from-xcode

# Nach einem Xcode-Update nur bereits vom Installer verwaltete Skills ersetzen.
python3 scripts/install-apple-xcode-skills.py --from-xcode --replace-existing
```

Wenn Xcode 27 nicht von `xcrun` gefunden wird, in Xcode unter *Settings → Locations → Command Line Tools* die richtige Xcode-Version wählen. `xcrun agent skills export --help` zeigt die Parameter der lokalen Version.

**Alternativ:** Zuerst den Originalexport erstellen, dann importieren:

```bash
xcrun agent skills export --output-dir ~/Downloads/apple-xcode-skills
python3 scripts/install-apple-xcode-skills.py --source ~/Downloads/apple-xcode-skills
```

Nach erfolgreichem Import liegen identische, vollständig kopierte Apple-Skill-Verzeichnisse lokal unter `.agents/skills/<exportname>/` (Codex) und `.claude/skills/<exportname>/` (Claude Code). Referenzdateien/Skripte bleiben erhalten. Es werden **keine Symlinks** erstellt und **keine bestehenden BBT-Bit-Skills** verändert. Vorhandene fremde Skill-Namen lösen einen Abbruch statt Überschreiben aus. Für Aktualisierungen ist `--replace-existing` erforderlich.

Der Installer ergänzt **ausschließlich die lokale `.git/info/exclude`** um die übernommenen Ordner. Sein lokales Inventar liegt unter `.bbt-local/`. **Apple-Inhalte und lokale Geräte-/Diagnosedaten nicht committen**, insbesondere nicht mit `git add -f`. Es werden keine fremden GitHub-Reuploads der Apple-Inhalte verwendet. Die ursprüngliche Lizenz und die lokale Xcode-Version sind maßgeblich.

## Priorität und Projektgrenzen

1. **BBT-Bit-AGENTS.md, Arbeitsbranch und Nutzerdatenregeln** sind verbindlich. Apple-Skills ergänzen technische Empfehlungen; sie überschreiben nicht die Projektarchitektur, den Nutzerauftrag oder die Sicherheitsregeln.
2. **RED Morph (E-006/E-007):** native iPhone-Suche bleibt integriert; `tabViewBottomAccessory` plus `tabBarMinimizeBehavior(dockScroll.keepExpanded ? .never : .onScrollDown)` erhält das gemeinsame Schrumpfen/Aufklappen von Tab-Leiste und Mini-Player. `matchedTransitionSource` und `navigationTransition(.zoom(...))` erhalten den Vollplayer-Morph. Ein Apple-Skill darf nicht stillschweigend die feste `.never`-Regression wieder einführen.
3. **Audio zuerst:** Kotlin/Innertube, Rust-Engine und Streaming nur nach explizitem Auftrag ändern; keine DRM-Umgehung und kein simulierter Audioerfolg.
4. **API-Verfügbarkeit:** iOS-/macOS-27-Neuerungen nur nach Prüfung von Deployment Target, `#available`, iOS 26 und realem Geräteverhalten übernehmen.
5. **Prüfstatus unterscheiden:** lokaler Skill-Import ist kein Swift-Typecheck, kein Simulator-Build, keine signierte IPA und kein Beweis hörbarer Wiedergabe. Bei fehlendem Xcode/CI-Kontingent ausdrücklich **NICHT GETESTET**.

Die Auswahl der **projektspezifischen** Skills bleibt unter [Agenten-Workflow](AGENT_WORKFLOW.md) dokumentiert. [RED Morph](red-morph-player-search-navigation.md) · [Testplan](TESTPLAN.md) · [Entscheidungen](../ENTSCHEIDUNGEN.md) · [Probleme](../PROBLEME.md).

## Verifikation des Imports

```bash
# Nach lokalem Import; alle importierten Ordner müssen hier erscheinen:
find .agents/skills .claude/skills -name SKILL.md -print

# Prüfen, dass exportierte Apple-Dateien nicht für einen Git-Commit vorgemerkt sind:
git status --short
git check-ignore .agents/skills/swiftui-specialist/SKILL.md

# Repository-Regeln (auf einem Mac oder Linux mit PyYAML verfügbar):
python3 scripts/check-repository.py
```

Falls ein bestimmter Name in deinem Xcode nicht exportiert wurde, ersetzt `git check-ignore` ihn nicht durch eine erfundene Datei. Das tatsächliche Manifest `.bbt-local/apple-xcode-skills.json` enthält die erfolgreich importierten Namen. Ein erfolgreicher Import und ein Geräte-Build sind zwei getrennte Nachweise.
