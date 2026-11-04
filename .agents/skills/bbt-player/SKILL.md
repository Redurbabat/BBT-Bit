---
name: bbt-player
description: Ändert Wiedergabesitzung, Queue, Transport und Mini- oder Vollplayer in BBT-Bit.
---

# bbt-player

Beginne bei [PlaybackController](../../../AppleApp/Sources/PlaybackSession/PlaybackController.swift) und den Erweiterungen für Queue, Transport, LoadResults und Ticks. [PlaybackPill](../../../AppleApp/Sources/UI/PlaybackPill.swift) und [NowPlaying](../../../AppleApp/Sources/UI/NowPlaying/) lesen dieselbe Sitzung.

Halte Identität und Reihenfolge der Queue beim Laden, Überspringen und Wiederaufnehmen stabil. Aktualisiere Anzeige und Transport aus den bestätigten Zuständen. Prüfe, ob verspätete Rückrufe zu einer früheren Anfrage gehören.

## Prüfung

Wähle je nach Änderung [check-queue](../../../scripts/check-queue.sh), [check-queue-runtime](../../../scripts/check-queue-runtime.sh), [check-transport](../../../scripts/check-transport.sh) und [check-playback](../../../scripts/check-playback.sh). Prüfe Mini-/Vollplayer-Wechsel und echte Wiedergabe nach [Testplan](../../../docs/TESTPLAN.md).
