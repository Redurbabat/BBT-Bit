---
name: bbt-ios-testing
description: Führt SwiftUI- und XCUITests für BBT-Bit aus und dokumentiert Simulator- und Echtgerätenachweise.
---

# bbt-ios-testing

Nutze [LiquidMotionUITests](../../../AppleApp/UITests/LiquidMotionUITests.swift), [Simulatorworkflow](../../../.github/workflows/ios-simulator-tests.yml) und [Gerätetests](../../../docs/iphone-device-self-tests.md). Verwende stabile Accessibility-IDs und erhalte die sichtbaren Labels. Beschreibe für jede Prüfung Startzustand, Eingabe und beobachtetes Ergebnis.

## Prüfung

Unterscheide Swift-Parse, Swift-Typecheck im App-Build, Simulator-XCUITest, Vorschau und Echtgerät. Sichere XCResult und geeignete Screenshots. Reale Wiedergabe braucht hörbare Ausgabe, Zeitfortschritt, Hintergrund und Route am physischen iPhone. Nutze die Statuswörter im [Testplan](../../../docs/TESTPLAN.md).
