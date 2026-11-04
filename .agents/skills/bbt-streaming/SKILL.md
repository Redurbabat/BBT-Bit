---
name: bbt-streaming
description: Diagnostiziert und ändert YouTube-/Innertube-Auflösung, HTTP, Sitzungen und Rückfallverhalten.
---

# bbt-streaming

Verfolge den Aufruf vom [Swift-Resolver](../../../AppleApp/Sources/App/InnertubeStreamResolver.swift) über [Shared Kotlin](../../../shared/src/commonMain/kotlin/) und [InnerTubeX](../../../vendor/innertubex/) bis zum Load-Ergebnis. Unterscheide Kandidatenwahl, Authentifizierung, HTTP/Timeout, Abrufbarkeit der Quelle und Ausgabe. Verwende bestehende Recovery-Pfade und halte verspätete Ergebnisse von der aktuellen Auswahl fern.

[GuardedHTTP](../../../AppleApp/Sources/App/GuardedHTTP.swift) und die [Datenregeln](../../../docs/DATENREGELN.md) bestimmen, wo Header, Redirects und Cookies verarbeitet werden. Diagnosen enthalten keine Cookie- oder signierten URL-Werte.

## Prüfung

Kotlin-Test mit kontrollierten Antworten für Timeout, ungültige Sitzung und Rückfall. Auf macOS je nach Änderung [check-network-errors](../../../scripts/check-network-errors.sh), [check-stream-recovery](../../../scripts/check-stream-recovery.sh) und [check-source-bridge](../../../scripts/check-source-bridge.sh). Live-Wiedergabe und tatsächliche Audioausgabe separat belegen.
