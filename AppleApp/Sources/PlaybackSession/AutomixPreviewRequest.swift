import Foundation

struct AutomixPreviewRequest: Identifiable, Sendable {
    let id = UUID()
    let outgoing: QueueEntry
    let incoming: QueueEntry
    let outgoingSource: String
    let incomingSource: String
    let outgoingHeaders: [String: String]
    let incomingHeaders: [String: String]
    let outgoingWindow: MixWaveformWindow
    let incomingWindow: MixWaveformWindow
    let fade: Double
    let rate: Double
}

/// Ein serieller Decoder für die Vorschau; keine Arbeit im Audio-Callback.
actor AutomixWaveformDecoder {
    static let shared = AutomixWaveformDecoder()
    struct Deck: Sendable {
        let waveform: MixWaveform
        let offset: Double
        let bpm: Double?
        let key: String?
    }
    func decode(engine: PlayerEngine, source: String, headers: [String: String], window: MixWaveformWindow) -> Deck? {
        guard !Task.isCancelled,
              let region = engine.decodeRegionWithHeaders(source: source, startSeconds: window.start,
                  durationSeconds: window.length, mono: true, headers: headers),
              !Task.isCancelled, region.startSeconds.isFinite, region.sampleRate > 0 else { return nil }
        let rate = Double(region.sampleRate)
        let skip = Int(min(Double(region.samples.count), max(0, window.start - region.startSeconds) * rate))
        guard let waveform = MixWaveform.measure(samples: Array(region.samples.dropFirst(skip)), sampleRate: rate) else { return nil }
        let overlay = AutomixOverlayCache.load(forFilePath: source)
        let beats = cachedBeatTimes(path: source)
        let intervals = zip(beats, beats.dropFirst()).map { $1 - $0 }.filter { $0.isFinite && $0 > 0.15 && $0 < 3 }.sorted()
        let bpm = intervals.isEmpty ? nil : 60 / intervals[intervals.count / 2]
        return Deck(waveform: waveform, offset: max(0, region.startSeconds - window.start), bpm: overlay?.bpm ?? bpm, key: overlay?.key)
    }
}
