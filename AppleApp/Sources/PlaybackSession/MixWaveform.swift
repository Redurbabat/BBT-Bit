import Foundation

/// Gemessene Energie in drei Frequenzbändern, ohne synthetische Ersatzkurve.
struct MixWaveform: Sendable {
    struct Bands: Sendable { let low: Float; let mid: Float; let high: Float }
    let bars: [Bands]
    let duration: Double

    static func measure(samples: [Float], sampleRate: Double, columns: Int = 160) -> MixWaveform? {
        guard sampleRate.isFinite, sampleRate >= 4_000, !samples.isEmpty,
              (1...512).contains(columns) else { return nil }
        let count = min(columns, samples.count)
        let lowAlpha = 1 - exp(-2 * Double.pi * 200 / sampleRate)
        let highAlpha = 1 - exp(-2 * Double.pi * 2_000 / sampleRate)
        var low = 0.0, upper = 0.0
        var powers = Array(repeating: [Double](repeating: 0, count: 3), count: count)
        var lengths = [Int](repeating: 0, count: count)
        for (i, raw) in samples.enumerated() {
            let value = raw.isFinite ? Double(raw) : 0
            low += lowAlpha * (value - low)
            upper += highAlpha * (value - upper)
            let column = min(count - 1, i * count / samples.count)
            let mid = upper - low, high = value - upper
            powers[column][0] += low * low
            powers[column][1] += mid * mid
            powers[column][2] += high * high
            lengths[column] += 1
        }
        let rms = powers.enumerated().map { i, band in band.map { sqrt($0 / Double(max(1, lengths[i]))) } }
        let peak = max(0.000001, rms.flatMap { $0 }.max() ?? 0)
        let bars = rms.map { band in
            Bands(low: Float(sqrt(band[0] / peak)), mid: Float(sqrt(band[1] / peak)), high: Float(sqrt(band[2] / peak)))
        }
        return MixWaveform(bars: bars, duration: Double(samples.count) / sampleRate)
    }
}

struct MixWaveformWindow: Sendable {
    let start: Double
    let length: Double
    let blendStart: Double
    let blendEnd: Double

    init(blendStart: Double, fade: Double, duration: Double? = nil) {
        let fade = fade.isFinite ? max(0.1, fade) : 0.1
        let anchor = blendStart.isFinite ? max(0, blendStart) : 0
        let start = max(0, anchor - min(4, fade * 0.24))
        self.start = start
        let requested = min(24, anchor + fade + min(4, fade * 0.24) - start)
        self.length = max(0.01, min(requested, duration.flatMap { $0.isFinite && $0 > 0 ? max(0, $0 - start) : nil } ?? requested))
        self.blendStart = anchor
        self.blendEnd = anchor + fade
    }
}
