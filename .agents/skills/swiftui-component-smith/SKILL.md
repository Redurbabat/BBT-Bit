---
name: swiftui-component-smith
description: Entwirft und implementiert wiederverwendbare native SwiftUI-Komponenten für BBT-Bit auf iPhone, iPad und Mac.
---

# swiftui-component-smith

Suche zuerst in [UI](../../../AppleApp/Sources/UI/) und [Theme](../../../AppleApp/Sources/UI/Theme.swift) nach bestehenden Bausteinen. Halte Inputs, Bindings und Callbacks klein. Der Elternzustand bleibt Eigentümer von Auswahl, Queue und Transport.

Definiere sichtbare Zustände für Ruhe, Druck, Fokus, Auswahl und Deaktivierung. Lade- und Fehlerzustände gehören zur API, wenn sie Teil des Nutzerwegs sind. Liefere eine kurze Integration am normalen Aufrufpunkt und kennzeichne separate Vorschauen.

## Prüfung

Wähle mindestens sechs relevante Szenarien für neue interaktive Komponenten. Decke Zustand, Ein-/Ausgabe, Fokus, Dynamic Type, VoiceOver, 44-pt-Ziele und Reduced Motion entsprechend dem [Designsystem](../../../docs/DESIGN_SYSTEM.md) ab. Prüfe iPhone-Touch und macOS-Tastatur, wenn beide Plattformen betroffen sind.
