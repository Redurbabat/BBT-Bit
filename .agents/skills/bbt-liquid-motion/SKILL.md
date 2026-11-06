---
name: bbt-liquid-motion
description: Implementiert und prüft Glass Bloom, Cover Morph und weitere SwiftUI-Motion in BBT-Bit.
---

# bbt-liquid-motion

Beginne bei [LogoGlassBloom](../../../AppleApp/Sources/UI/LiquidMotion/LogoGlassBloom.swift), [CoverMorphArtworkContext](../../../AppleApp/Sources/UI/NowPlaying/CoverMorphArtworkContext.swift), [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) und [RootView](../../../AppleApp/Sources/UI/RootView.swift). Erhalte den gemeinsamen Artwork-Kontext und die vorhandene Navigationsidentität. Öffnen, Schließen und Abbruch müssen zur aktuellen Playeransicht passen.

Nutze [Designsystem](../../../docs/DESIGN_SYSTEM.md) für Verfügbarkeit, Material und reduzierte Darstellung. Binde Gesten an die vorhandenen Aktionen und Rückmeldungen, einschließlich gesperrter Party-Bedienung.

## Prüfung

Prüfe [Cover-Morph-Sequenz](../../../docs/cover-morph-video-comparison.md), [Glass-Bloom-Ablauf](../../../docs/glass-bloom-motion-lab.md), schnelle Richtungswechsel, Reduce Motion und Transparenz. Dokumentiere Zwischenbilder sowie App-Zustand und Gerät.

## Systeminsel und Logo-Bloom unterscheiden

Die **originale Apple Dynamic Island** wird ausschließlich durch Apples Now-Playing-Medienintegration mit der echten aktiven Wiedergabesitzung gefüllt. `LogoGlassBloomIsland` bleibt eine App-interne, temporäre Animation am BBT-Bit-Logo, nicht die Hardware-Insel; sie darf System-Now-Playing weder ersetzen noch als zweite eigene Music-Live-Activity duplizieren. Die bestehende RED-Morph-Tab-Bar-/Mini-Player-Animation am unteren Rand ist davon unabhängig und bleibt verbindlich. Apple bestimmt die Form, Animation und Priorität der Hardware-Island. [Technik und Abnahme](../../../docs/native-dynamic-island-red-morph.md).

## Apple-Originalmodifikatoren übernehmen, nicht Oberflächen nachbauen

Bei der Such-Tastatur auf iOS 26.1+ ist `tabViewBottomAccessory(isEnabled: !keyboardUp)` die dokumentierte Apple-API für vollständiges Ausblenden des nativen Accessory. Das Keyboard-`safeAreaInset` verwendet in diesem Zustand genau ein kompaktes `PlaybackPill`. iOS 26.0 bleibt als Fallback bestehen. Tab-Leiste/`tabViewBottomAccessoryPlacement` und `matchedTransitionSource`/`.navigationTransition(.zoom)` müssen weiter den unveränderten System-Morph aus der Nutzerreferenz liefern. Keine selbst gezeichnete System-Tab-Bar oder Hardware-Dynamic-Island. Vergleiche mit [Original-Apple-APIs](../../../docs/apple-native-ui-adoption.md); tatsächlicher Tastatur- und Scrollzustand **NICHT GETESTET**.

## Verbindliche iPhone-Referenz: Mini-Player und Tab-Leiste (RED Morph, 06.11.2026)

Das vom Nutzer bereitgestellte Referenzvideo ist die Vorgabe für den **nativen, gekoppelten** Ablauf unter iOS 26+: Im Ruhezustand liegt das Playback-Pill oberhalb der großen Tab-Leiste. Beim Abwärtsscrollen in „Jetzt hören“/„Entdecken“ minimiert die System-Tab-Leiste; der **selbe Mini-Player** wechselt flüssig in die Inline-Position der kompakten Tab-Leiste. Beim Scrollen aufwärts (auch bei Richtungswechsel innerhalb einer Geste) klappen beide wieder gemeinsam auf. Tippen/Ziehen am Mini-Player öffnet den Vollplayer mit Zoom; Herunterziehen kehrt zur Quelle zurück. Das Video bleibt Gesprächsreferenz, keine Medienkopie ins Repository.

**Nicht durch statische Leisten ersetzen.** Behalte in [RootView](../../../AppleApp/Sources/UI/RootView.swift) `.tabViewBottomAccessory` und `tabBarMinimizeBehavior(dockScroll.keepExpanded ? .never : .onScrollDown)`, in [DockScrollDirection](../../../AppleApp/Sources/UI/LiquidMotion/DockScrollDirection.swift) die Richtungswechsel-Erkennung, und in [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) den Inline-Zustand aus `tabViewBottomAccessoryPlacement` und `matchedTransitionSource`. Ein dauerhaftes `tabBarMinimizeBehavior(.never)` ist hier eine Regression. Keine zweite eigene Tab-Leiste oder doppeltes Playback-Pill montieren. Erhalte `navigationTransition(.zoom(...))` des Vollplayers.

Bei Tastatur/integrierter Suche nur den notwendigen sicheren Inset verwenden; der Mini-Player darf Ergebnisse nicht überdecken oder doppelt erscheinen. Gesten, laufende Audiowiedergabe, VoiceOver, Reduce Motion/Transparency und ältere System-Fallbacks erhalten. Abnahme: reales iPhone, Abwärts-/Aufwärtsscrollen, sofortige Umkehr, Tastatur auf/zu, Mini-zu-Vollplayer und zurück; Quellprüfung allein ist **kein** Animationsnachweis. Ohne erfolgreichen iPhone-/Simulatorlauf den Animations- und Zoom-Nachweis ausdrücklich als **NICHT GETESTET** kennzeichnen. Siehe [RED Morph](../../../docs/red-morph-player-search-navigation.md) und [Probleme](../../../PROBLEME.md).
