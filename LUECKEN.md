# Lücken im Prüf- und Auslieferungsstand

| Bereich | Beobachtbarer Stand |
| --- | --- |
| Automatisierte iOS-Interaktionen | [LiquidMotionUITests](AppleApp/UITests/LiquidMotionUITests.swift) prüft Designvorschauen. Echte YouTube-Wiedergabe, Gerätewechsel und Hintergrundbetrieb brauchen separate Nachweise. |
| Alternative Stream-Transporte | Die Apple-Pipeline verwendet progressive Quellen. Der [Recovery-Bericht](docs/iphone-youtube-extraction-recovery-20261104.md) dokumentiert den fehlenden SABR-Adapter. |
| Signierte Auslieferung | Die konfigurierten Codemagic-Wege erzeugen unsignierte IPA-Dateien. Installations- und Update-Freigaben erfordern die Schritte im [Release-Ablauf](docs/RELEASE.md). |
| Technische Merge-Sperre | Die Branch-Regel gilt organisatorisch. In der vom Maintainer gemeldeten privaten Repository-Konfiguration steht das Ruleset aktuell nicht zur Verfügung. |
