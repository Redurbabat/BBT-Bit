# Lücken im Prüf- und Auslieferungsstand

| Bereich | Beobachtbarer Stand |
| --- | --- |
| Original-Funktionen auf Apple | PR #59 implementiert die fünf gefundenen Verbesserungsbereiche. [Lokale Nachweise und Migration](docs/ORIGINAL_PARITAET_PR59.md); Xcode-/Kotlin-Native-Build, echte Wellenformdarstellung, Systemplayer-Handoff und hörbare Wiedergabe bleiben BBT-024. |
| Automatisierte iOS-Interaktionen | [LiquidMotionUITests](AppleApp/UITests/LiquidMotionUITests.swift) prüft Designvorschauen. Echte YouTube-Wiedergabe, Gerätewechsel und Hintergrundbetrieb brauchen separate Nachweise. |
| Alternative Stream-Transporte | Die Apple-Pipeline verwendet progressive Quellen. Der [Recovery-Bericht](docs/iphone-youtube-extraction-recovery-20261104.md) dokumentiert den fehlenden SABR-Adapter. |
| Signierte Auslieferung | Die konfigurierten Codemagic-Wege erzeugen unsignierte IPA-Dateien. Installations- und Update-Freigaben erfordern die Schritte im [Release-Ablauf](docs/RELEASE.md). |
| Technische Merge-Sperre | Die Branch-Regel gilt organisatorisch. In der vom Maintainer gemeldeten privaten Repository-Konfiguration steht das Ruleset aktuell nicht zur Verfügung. |
