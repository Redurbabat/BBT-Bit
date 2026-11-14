---
name: bbt-audio-engine
description: Ändert Rust-Audio-Engine, Decoder, DSP, Equalizer, Mixer, Routen und Swift-FFI.
---

# bbt-audio-engine

Beginne bei [API](../../../native-core/src/api.rs), [Decode](../../../native-core/src/decode/), [Mixer](../../../native-core/src/mixer/), [EQ](../../../native-core/src/eq/) oder [Output](../../../native-core/src/output.rs). Prüfe Raten, Kanäle, Pufferbesitz, Callback-Lebensdauer und Reihenfolge bei Abbruch, Seek und Trackwechsel. Halte blockierende Arbeit vom zeitkritischen Ausgabepfad fern.

Ändert sich der Export, erzeuge die Swift-Bindings mit [build-native-core](../../../scripts/build-native-core.sh) neu und prüfe die Empfänger in [PlaybackSession](../../../AppleApp/Sources/PlaybackSession/).

## Bit-perfect Pause und Gerätewechsel

Bei BitChord-v1.9.1-Parität auf macOS nur echten exklusiven Integer-PCM-Ausgang nach 30 s Pause/Stop freigeben. Der `rtrb`-Puffer wird beim erfolgreichen Fortsetzen **nicht** geleert. Vor der Wiederaufnahme müssen CoreAudio-AudioDeviceID, physische Wortbreite/Kanalzahl/Samplerate und exklusiver Zugriff stimmen. Bei Abweichungen erst kontrolliert neu aufbauen, nie falschen Bit-perfect-Erfolg melden. iOS-RemoteIO-Float ist keine exklusive CoreAudio-Integer-Ausgabe. Prüfe Pause/Play-/Route-Rennen mit demselben Ausgabelock; niemals CoreAudio-Aufrufe im zeitkritischen Callback. Beachte [Entscheidung E-010](../../../ENTSCHEIDUNGEN.md) und [Testplan](../../../docs/TESTPLAN.md).

## Prüfung

`cargo test --locked --manifest-path native-core/Cargo.toml` und gezielte Regression für den geänderten Pfad. Apple-Verknüpfung mit [check-engine](../../../scripts/check-engine.sh) und hörbare Ausgabe einschließlich Route oder Wiederanlauf am Gerät prüfen.
