import Foundation

@main enum OriginalParityChecks {
    static func main() async throws {
        let now = Date(timeIntervalSince1970: 1000)
        var seeds = AutoplaySeedState()
        let a = seeds.begin(entryID: "addon:a", playbackGeneration: 1, sessionGeneration: 1, now: now)!
        assert(seeds.begin(entryID: "addon:a", playbackGeneration: 1, sessionGeneration: 1, now: now) == nil)
        assert(!seeds.finish(a, seed: "abcdefghijk", currentID: "addon:b", playbackGeneration: 2, sessionGeneration: 1, now: now))
        let b = seeds.begin(entryID: "addon:a", playbackGeneration: 3, sessionGeneration: 1, now: now)!
        assert(!seeds.finish(b, seed: "abcdefghijk", currentID: "addon:a", playbackGeneration: 3, sessionGeneration: 2, now: now))
        let c = seeds.begin(entryID: "addon:a", playbackGeneration: 4, sessionGeneration: 2, now: now)!
        assert(!seeds.finish(c, seed: nil, currentID: "addon:a", playbackGeneration: 4, sessionGeneration: 2, now: now))
        assert(seeds.begin(entryID: "addon:a", playbackGeneration: 4, sessionGeneration: 2, now: now.addingTimeInterval(10)) == nil)
        let d = seeds.begin(entryID: "addon:a", playbackGeneration: 4, sessionGeneration: 2, now: now.addingTimeInterval(16))!
        assert(seeds.finish(d, seed: "abcdefghijk", currentID: "addon:a", playbackGeneration: 4, sessionGeneration: 2, now: now))
        assert(seeds.seed(for: "addon:a", sessionGeneration: 2) == "abcdefghijk")
        assert(seeds.seed(for: "addon:a", sessionGeneration: 3) == nil)
        print("ok: Seed-Identität, parallele Antwort, Kontowechsel, Timeout-Pause und Cache")

        var record = PlaylistSyncRecord(seenEntryIDs: ["kept", "deleted"])
        assert(record.additions(listing: ["kept", "deleted", "new", "new"]) == ["new"])
        record.handled("new")
        assert(record.additions(listing: ["deleted", "new"]).isEmpty)
        let decoded = try JSONDecoder().decode(PlaylistSyncRecord.self, from: JSONEncoder().encode(record))
        assert(decoded == record)
        assert(PlaylistSyncPolicy.browseID("VLPL123") == "VLPL123")
        assert(PlaylistSyncPolicy.browseID("PL123") == "VLPL123")
        for unsupported in ["local:playlist:1", "spotify:playlist:1", "MPREb_1", "VLOLAK1"] {
            assert(PlaylistSyncPolicy.browseID(unsupported) == nil)
        }
        assert(!PlaylistSyncPolicy.due(lastComplete: now, now: now.addingTimeInterval(6 * 3600), foreground: false))
        assert(PlaylistSyncPolicy.due(lastComplete: now, now: now.addingTimeInterval(6 * 3600), foreground: true))
        assert(PlaylistSyncPolicy.due(lastComplete: nil, now: now, foreground: false))
        print("ok: Playlist-Journal, Löschabsicht, Duplikate, Persistenz und Fälligkeit")

        let silence = MixWaveform.measure(samples: [Float](repeating: 0, count: 4410), sampleRate: 44100)!
        assert(silence.bars.count == 160 && silence.bars.allSatisfy { $0.low == 0 && $0.mid == 0 && $0.high == 0 })
        assert(MixWaveform.measure(samples: [], sampleRate: 44100) == nil)
        assert(MixWaveform.measure(samples: [1], sampleRate: .nan) == nil)
        assert(MixWaveform.measure(samples: [1], sampleRate: 44100, columns: 0) == nil)
        let invalid = MixWaveform.measure(samples: [.nan, .infinity, 0], sampleRate: 44100)!
        assert(invalid.bars.allSatisfy { $0.low.isFinite && $0.high.isFinite && $0.mid.isFinite })
        for frequency in [90.0, 6000.0] {
            let samples = (0..<44100).map { Float(sin(2 * Double.pi * frequency * Double($0) / 44100)) }
            let wave = MixWaveform.measure(samples: samples, sampleRate: 44100)!
            let low = wave.bars.reduce(Float(0)) { $0 + $1.low }
            let high = wave.bars.reduce(Float(0)) { $0 + $1.high }
            assert(frequency == 90 ? low > high : high > low)
            assert(abs(wave.duration - 1) < 0.00001)
        }
        let window = MixWaveformWindow(blendStart: 200, fade: 60)
        assert(window.start >= 0 && window.length <= 24 && window.blendStart >= window.start)
        let invalidWindow = MixWaveformWindow(blendStart: .nan, fade: .infinity)
        assert(invalidWindow.start == 0 && invalidWindow.length.isFinite)
        let ending = MixWaveformWindow(blendStart: 296, fade: 4, duration: 300)
        assert(abs(ending.start + ending.length - 300) < 0.00001)
        print("ok: Gemessene Frequenzbänder, digitale Stille, ungültige Samples und begrenzte Fenster")

        let preview = await AutomixWaveformDecoder.shared.decode(engine: PlayerEngine(region:
            PreviewRegion(samples: [Float](repeating: 0.2, count: 44100), sampleRate: 44100, startSeconds: 0)),
            source: "fixture.wav", headers: [:], window: MixWaveformWindow(blendStart: 0, fade: 1))
        assert(preview?.bpm == 120 && preview?.waveform.duration == 1)
        let unavailable = await AutomixWaveformDecoder.shared.decode(engine: PlayerEngine(region: nil),
            source: "fixture.wav", headers: [:], window: invalidWindow)
        assert(unavailable == nil)
        print("ok: Produktions-Vorschaudecoder mit kontrolliertem FFI-Adapter, Cache-BPM und fehlenden Daten")

        assert(ReleaseRepository.accepts(page: URL(string: "https://github.com/Redurbabat/RED-Bit/releases/tag/v1.0.5")!))
        for url in ["https://github.com/Redurbabat/RED-Bit/releases/tag/v1", "https://github.com/Redurbabat/RED-Bit/releases/tag/v1", "http://github.com/Redurbabat/RED-Bit/releases/tag/v1", "https://user@github.com/Redurbabat/RED-Bit/releases/tag/v1", "https://github.com:999/Redurbabat/RED-Bit/releases/tag/v1"] {
            assert(!ReleaseRepository.accepts(page: URL(string: url)!))
        }
        print("ok: Update-Identität bleibt bei RED Bit")
    }
}
