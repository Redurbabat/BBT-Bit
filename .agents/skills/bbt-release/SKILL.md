---
name: bbt-release
description: Prüft App-Version, Build, Codemagic, IPA/DMG, Signierung und Release-Freigabe für BBT-Bit.
---

# bbt-release

Lies [RELEASE.md](../../../docs/RELEASE.md), [XcodeGen](../../../AppleApp/project.yml) und [version.md](../../../version.md). Halte App, Widget und Metadaten synchron. Verwende denselben sauberen Commit für IPA und DMG. [Codemagic](../../../codemagic.yaml) baut die vorhandenen unsignierten IPA-Varianten.

## Prüfung

Führe `python scripts/check-repository.py` und [release-verify](../../../scripts/release-verify/check.py) aus. Prüfe am tatsächlichen Paket Plist, eingebetteten Build, Quellrevision und Checksummen. Teste Installation oder Update nach Signierung und dokumentiere die Freigabe, bevor der Status wechselt.
