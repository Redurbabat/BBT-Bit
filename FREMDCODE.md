# Herkunft und Lizenzen

Das bestehende Inventar für BitChord, InnerTubeX, die YouTube-Solver, Kotlin/Native, Rust-Bibliotheken, Sparkle, Modelle, Icons und Übersetzungen steht in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Lizenztexte liegen in [LICENSES](LICENSES/) und in den [gebündelten App-Hinweisen](AppleApp/Resources/AudioLicenses/). Übernommene Dateien behalten ihre eigenen Hinweise.

| Quelle | Nutzung in BBT-Bit | Lizenzstatus |
| --- | --- | --- |
| [React Bits Magic Bento](https://reactbits.dev/c/components/magic-bento), [Apple-Kontextmenüs](https://developer.apple.com/design/human-interface-guidelines/context-menus) und [Spotify daylist](https://newsroom.spotify.com/2023-09-12/ever-changing-playlist-daylist-music-for-all-day/) | Gestaltungs-/Verhaltensreferenzen für den persönlichen Home-Bereich vom 9. November 2026: große Fortsetzen-Karte, zwei Schnellzugriffe, native Vorschau und Tageszeit-Mix. | Ausschließlich Ideenreferenz. Eigene SwiftUI-/Foundation-Implementierung; kein übernommener Code, keine Demo-Medien, kein Spotify-/React-Dienst und keine neue Laufzeitabhängigkeit. |
| [BitChord Android `acf219a`](https://github.com/kushagrasinghx/BitChord/tree/acf219a7e4a7f52f026d4336d5c7ac5cf7bfafcc) | Verhalten für Addon-Radio-Seed, Metadatenübergabe im Mix, gemessene Mix-Vorschau und ergänzenden Playlist-Abgleich nativ umgesetzt. [Zuordnung](docs/ORIGINAL_PARITAET_PR59.md). | GPLv3; bestehende BitChord-/Apple-Port-Zuschreibungen bleiben erhalten. Keine neue Bibliothek oder Modellgewichte eingebunden. |
| [Redion](https://github.com/Redurbabat/Redion/tree/c81ff6af9ab65fed52e1962f9864add4385c13ef) | Trennung von Aufgaben, Chronik, Entscheidungen, Fehlern, Versionsstand und Prüfnachweisen. | Ausschließlich organisatorische Referenz. |
| [UI-Kit](https://github.com/Redurbabat/UI-Kit/tree/5e47ef79093626e5da6b78713ab071250ae2a611) | Vier gleichnamige Skills als BBT-Bit-Fassungen. Die Vorlagen und das Motion Lab liefern Workflow und Designideen. | Am geprüften Stand wurde keine allgemeine UI-Kit-Lizenz gefunden. Die neuen Texte formulieren die Ideen für BBT-Bit eigenständig. |
| [PyYAML 6.0.3](https://github.com/yaml/pyyaml/tree/6.0.3) | YAML-Leser für Repo-Prüfungen in CI. | MIT, Prüfwerkzeug. |
| [Gitleaks 8.30.1](https://github.com/gitleaks/gitleaks/tree/v8.30.1) | Geheimnisprüfung der neu hinzugekommenen Commits mit maskierten Funden. | MIT, Prüfwerkzeug. |
| [Actionlint 1.7.12](https://github.com/rhysd/actionlint/releases/tag/v1.7.12) | Syntax, Ausdrücke und Actions-Struktur sämtlicher GitHub-Workflows. | MIT, ausschließlich Prüfwerkzeug. Linux-amd64-Archiv mit SHA-256 `8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8` fixiert; keine App-Abhängigkeit. |
| [ShellCheck 0.11.0](https://github.com/koalaman/shellcheck/releases/tag/v0.11.0) | Bash-Blöcke der Workflows über Actionlint prüfen. | GPL-3.0, ausschließlich Prüfwerkzeug. Linux-x86_64-Archiv mit SHA-256 `8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198` fixiert; keine App-Abhängigkeit. |

Vor jeder Übernahme Herkunft, exakte Version oder Revision, Lizenztext, Rechte Dritter, Einbauort, Zweck und Auswirkungen auf Datenflüsse erfassen. Bei Laufzeitabhängigkeiten auch App-Hinweise und die aufgelöste Abhängigkeitsliste aktualisieren. Bei unklarer Lizenz zuerst die Rechte klären.

## Lokale InnerTubeX-Änderungen

Für [zwölf kreative Musikinteraktionen](docs/RED_BIT_KREATIVE_INTERAKTIONEN.md) wurden am 8. November 2026 die öffentlichen Vorschauen von [React Bits Pro](https://pro.reactbits.dev/docs/components) und deren [Lizenz](https://pro.reactbits.dev/license) geprüft. Sie dienen ausschließlich als visuelle Ideenreferenz; Pro-Code, Demo-Medien und Abhängigkeiten werden nicht übernommen. Die SwiftUI-/Canvas-Komponenten, Zeitgeometrie und Metal-Linse sind eigene Implementierungen für RED Bit. Es gibt keine neue Laufzeitabhängigkeit.

Der YouTube-Reparaturbranch ergänzt in der bestehenden GPLv3-Kopie von InnerTubeX die Kandidatenauswahl für progressive Audioantworten, redigierbare Diagnosekategorien und eigene Regressionsfixtures. Die Herkunft und Lizenz des eingebundenen Codes stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Am 5. November 2026 ergänzt BBT-Bit eine eigene Normalisierung der Apple-Gerätesprache für den Player sowie Regressionsfälle für deutsche Regionstags und unterstützte Sprachvarianten. Es wurden keine neue Laufzeitbibliothek und kein fremder Implementierungscode übernommen.
