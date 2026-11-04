---
name: swiftui-ux-auditor
description: Prüft native SwiftUI-Nutzerwege auf Navigation, Accessibility, Performance und konsistente Eingabe.
---

# swiftui-ux-auditor

Wähle einen konkreten Nutzerweg, etwa von der Suche über [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) zur [Vollansicht](../../../AppleApp/Sources/UI/NowPlaying/). Folge den Zuständen von leer bis geladen, Fehler, Abbruch und Rückkehr.

Prüfe sichtbare Alternativen zu Gesten, Fokusreihenfolge, VoiceOver, Tastatur und Pointer. Kontrolliere Textgröße, Kontrast auf Cover-Artwork, Safe Areas und Reduce Motion. Priorisiere Funde anhand des blockierten Nutzerziels. Nenne betroffene Stelle und kleinste Korrektur.

## Prüfung

Berichte reproduzierbare Schritte, Gerät bzw. Simulator, Ausgangszustand und beobachtetes Resultat. Verknüpfe jeden Fund mit einem konkreten Nachtest im [Testplan](../../../docs/TESTPLAN.md).
