---
name: swiftui-ux-auditor
description: Prüft native SwiftUI-Nutzerwege auf Navigation, Accessibility, Performance und konsistente Eingabe.
---

# swiftui-ux-auditor

Wähle einen konkreten Nutzerweg, etwa von der Suche über [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) zur [Vollansicht](../../../AppleApp/Sources/UI/NowPlaying/). Folge den Zuständen von leer bis geladen, Fehler, Abbruch und Rückkehr.

Prüfe sichtbare Alternativen zu Gesten, Fokusreihenfolge, VoiceOver, Tastatur und Pointer. Kontrolliere Textgröße, Kontrast auf Cover-Artwork, Safe Areas und Reduce Motion. Priorisiere Funde anhand des blockierten Nutzerziels. Nenne betroffene Stelle und kleinste Korrektur.

## Prüfung

Berichte reproduzierbare Schritte, Gerät bzw. Simulator, Ausgangszustand und beobachtetes Resultat. Verknüpfe jeden Fund mit einem konkreten Nachtest im [Testplan](../../../docs/TESTPLAN.md).

## Regression: Scrollende iPhone-Tab-Leiste mit Mini-Player

Prüfe bei jedem Umbau von Suche, `RootView`, `PlaybackPill` oder Scroll-Containern den im Nutzer-Referenzvideo vom 06.11.2026 sichtbaren Ablauf: Tab-Leiste groß und Pill darüber; Abwärtsscrollen minimiert die native Leiste und führt das Pill **inline** hinein; Aufwärtsscrollen (auch während derselben Geste) stellt den großen Zustand wieder her. Das Öffnen des Vollplayers muss weiterhin aus dem Pill heraus zoomen und beim Schließen zurückkehren. Feste `.never`-Minimierung, abgetrenntes Suchfeld, gesonderte Tab-Bar, zweites Pill und verschobene Tastatur-Overlays sind Regressionen.

Mindestens in „Jetzt hören“, „Entdecken“ und Suche prüfen; außerdem schneller Richtungswechsel, Scrollen bei laufender Musik, VoiceOver, Reduce Motion/Transparency, Dynamic Type und Safe Areas. Für jedes Bild oder Video Build-SHA, iOS-Version und tatsächlich sichtbaren Zustand nennen; ohne Geräteprüfung **NICHT GETESTET** vermerken. [Testplan](../../../docs/TESTPLAN.md) und [RED Morph](../../../docs/red-morph-player-search-navigation.md).
