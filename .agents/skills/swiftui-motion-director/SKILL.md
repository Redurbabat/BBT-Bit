---
name: swiftui-motion-director
description: Entwirft native SwiftUI-Übergänge, Gesten und Motion-Varianten mit Fokus auf Unterbrechbarkeit und Eingabeparität.
---

# swiftui-motion-director

Kläre Nutzerziel, Häufigkeit und Auslöser. Beim Variantenentwurf skizziere Calm, Expressive und Pro mit Zuständen, Timing und Aufwand. Bei einer klar vorgegebenen Bewegung arbeite am vorhandenen Ablauf.

[Designsystem](../../../docs/DESIGN_SYSTEM.md) und [Liquid Motion](../../../AppleApp/Sources/UI/LiquidMotion/) liefern die lokalen Muster. Halte Ursprung und Ziel räumlich nachvollziehbar, erhalte die laufende Position beim Umlenken und begrenze kostspielige Unschärfe auf die eigentliche Bewegung. Biete sichtbare Aktionen für Wisch- und Haltegesten.

## Prüfung

Teste Einstieg, Ausstieg, Abbruch, schnelle Wiederholung und neue Ziele während der Animation. Prüfe reduzierte Bewegung, Fokus und Gestenkonflikte. Bewerte ruhende Darstellung und Echtgeräte-Performance separat.

## Apple-API-Parität statt statischem Nachbau

Bevor eine neue Gestenanimation hinzugefügt wird, prüfen, ob `tabBarMinimizeBehavior`, `tabViewBottomAccessoryPlacement`, `matchedTransitionSource`, `navigationTransition(.zoom)` und `accessibilityReduceMotion` bereits den Vorgang abdecken. Beim Suchfokus ab iOS 26.1 den nativen Accessory über `tabViewBottomAccessory(isEnabled: !keyboardUp)` ausschalten und nur das bestehende Keyboard-Pill per `safeAreaInset` anzeigen. Der 26.0-Fallback bleibt. Keine zusätzlichen dauerhaft eingeblendeten Dock- oder Tab-Bar-Overlays. [Apple-API-Abgleich](../../../docs/apple-native-ui-adoption.md) · [iPhone-Tests](../../../docs/TESTPLAN.md).

## RED-Morph-Motion: Scroll-Mini-Player ist verbindlich

Die Referenz vom 06.11.2026 zeigt **eine einzige native Bewegungskette**, keine zwei fest montierten Leisten: große Tab-Leiste mit Bottom-Accessory-Pill → bei Abwärtsscrollen kompakte Tab-Leiste mit Inline-Pill → bei Aufwärtsscrollen wieder große Tab-Leiste mit Pill darüber. Schnelle Richtungswechsel müssen umkehrbar sein. Das Pill bleibt über den Zustandswechsel dasselbe bedienbare Wiedergabeelement. Eine dauerhaft deaktivierte Minimierung (`.tabBarMinimizeBehavior(.never)`) oder ein zweiter künstlicher Dock widerspricht der Vorgabe.

Verwende den bereits vorhandenen `DockScrollCoordinator` und das native `.tabBarMinimizeBehavior(dockScroll.keepExpanded ? .never : .onScrollDown)` zusammen mit `.tabViewBottomAccessory` und `tabViewBottomAccessoryPlacement`. Für Mini-zu-Vollplayer bleibt `matchedTransitionSource`/`navigationTransition(.zoom(...))` erhalten. Die native integrierte Suchdarstellung darf nicht für Motion-Experimente abgetrennt werden.

Prüfe nicht nur Endzustände, sondern Zwischenbilder, Geste-Umkehr, Scrollen mit laufender Musik, Rückkehr aus Vollplayer, offene Tastatur, VoiceOver, Reduce Motion und fehlende doppelte Pill-Montage. Ohne iPhone-/Simulatorlauf den Effekt als **NICHT GETESTET** dokumentieren. [RED-Morph-Referenz](../../../docs/red-morph-player-search-navigation.md) · [Testplan](../../../docs/TESTPLAN.md).
