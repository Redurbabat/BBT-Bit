---
name: bbt-apple-xcode
description: Bindet alle lokal aus Xcode exportierten Apple-Agent-Skills sicher in BBT-Bit ein und vermittelt ihre Anwendung für SwiftUI, Tests, Geräte, Sicherheit und FFI.
---

# bbt-apple-xcode

## Wann anwenden

Nutze diesen BBT-Bit-Skill, wenn offiziell aus Xcode exportierte Apple-Agent-Skills für SwiftUI, iOS-/macOS-27-APIs, UIKit-Resizability, Swift Testing, Gerätesteuerung, Xcode-Sicherheit oder C-Bounds-Safety gebraucht werden. Die **Originaldateien** sind nicht im Git-Repository enthalten. Für den vollständigen lokalen Export folge der [Apple-Skill-Installationsanleitung](../../../docs/APPLE_XCODE_SKILLS.md).

Der Installer `python3 scripts/install-apple-xcode-skills.py --from-xcode` übernimmt **alle tatsächlich exportierten** Skill-Unterordner mitsamt Referenzen nach `.agents/skills/` und `.claude/skills/`; er kopiert keine Apple-Dateien auf den GitHub-Branch. Wenn der lokale Xcode-Export noch fehlt, **nicht behaupten**, die Apple-Skills bereits gelesen oder installiert zu haben. Nutze dann nur die geprüften öffentlichen Apple-Developer-Quellen und die bestehenden BBT-Bit-Skills. Xcode-Version und exportierte Liste unterscheiden sich.

## Zuständigkeiten

- `swiftui-specialist` und `swiftui-whats-new-27` (sofern tatsächlich exportiert): SwiftUI-Architektur, Interaktionen, Performance, API-Verfügbarkeit.
- `uikit-app-modernization` bzw. `app-resizability`: UIKit/SwiftUI-Szenengrößen, iPhone/iPad/Mac-Resizing und Lifecycle.
- `test-modernizer` bzw. `modernize-tests`: Swift Testing und XCTest. Keine Tests als bestanden bezeichnen, die nicht liefen.
- `device-interaction`: echte Simulator-/iPhone-Befunde, Fotos und Gesten statt bloßer Codeannahmen.
- `audit-xcode-security-settings`: XcodeGen-Sicherheit, Build-Flags, keine Schlüssel/Signierungsdaten committen.
- `c-bounds-safety` bzw. `adopt-c-bounds-safety`: C-Interop/FFI erst nach Analyse der tatsächlichen Grenzen; keine pauschalen Rust- oder Kotlin-Umbauten.

Neue Apple-Skills, die Xcode zusätzlich exportiert, sind ebenfalls zulässig. Berücksichtige das lokale `.bbt-local/apple-xcode-skills.json`-Inventar, sofern vorhanden. Kein Drittanbieter-Mirror als autoritativer Ersatz für den Xcode-Export.

## Höhere Projektregeln

[AGENTS.md](../../../AGENTS.md), [Entscheidungen](../../../ENTSCHEIDUNGEN.md), [Probleme](../../../PROBLEME.md), [RED Morph](../../../docs/red-morph-player-search-navigation.md) und die lokalen Wiedergabe-Skills bleiben maßgeblich. Insbesondere **die integrierte native iPhone-Suche** und die **beim Scrollen mit der Tab-Bar gekoppelte native Mini-Player-Animation** dürfen durch keine automatische App-Modernisierung rückgebaut werden. Das Playback-Pill muss inline minimieren und sich bei Gegenbewegung wieder ausklappen; Mini-/Vollplayer behalten den nativen Zoom. Keine Commits auf `main` oder fremde Agenten-Branches.

Prüfe vor neuen APIs Deployment Targets und Verfügbarkeit, vor Tests reale Apple-Hardware/Runner und vor Streamingbehauptungen hörbares Audio. Ohne erfolgreiche Prüfung **NICHT GETESTET**. [Testplan](../../../docs/TESTPLAN.md) · [Agenten-Workflow](../../../docs/AGENT_WORKFLOW.md).
