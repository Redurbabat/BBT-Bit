---
name: bbt-liquid-motion
description: Implementiert und prüft Glass Bloom, Cover Morph und weitere SwiftUI-Motion in BBT-Bit.
---

# bbt-liquid-motion

Beginne bei [LogoGlassBloom](../../../AppleApp/Sources/UI/LiquidMotion/LogoGlassBloom.swift), [CoverMorphArtworkContext](../../../AppleApp/Sources/UI/NowPlaying/CoverMorphArtworkContext.swift), [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) und [RootView](../../../AppleApp/Sources/UI/RootView.swift). Erhalte den gemeinsamen Artwork-Kontext und die vorhandene Navigationsidentität. Öffnen, Schließen und Abbruch müssen zur aktuellen Playeransicht passen.

Nutze [Designsystem](../../../docs/DESIGN_SYSTEM.md) für Verfügbarkeit, Material und reduzierte Darstellung. **Aktuelle Maintainerentscheidung E-011:** Music Island und Mini-Player zeigen neutrales systemeigenes Apple Liquid Glass ohne Cover-Farbverläufe, Cyan-/Violett-Atmosphäre oder zweite Glasfläche. Die nativen Transport-/Zoom-Gesten bleiben erhalten; nur der Vollbildplayer darf die Artwork-Palette als Hintergrund verwenden. Binde Gesten an die vorhandenen Aktionen und Rückmeldungen, einschließlich gesperrter Party-Bedienung.

## Prüfung

Prüfe [Cover-Morph-Sequenz](../../../docs/cover-morph-video-comparison.md), [Glass-Bloom-Ablauf](../../../docs/glass-bloom-motion-lab.md), schnelle Richtungswechsel, Reduce Motion und Transparenz. Dokumentiere Zwischenbilder sowie App-Zustand und Gerät.
