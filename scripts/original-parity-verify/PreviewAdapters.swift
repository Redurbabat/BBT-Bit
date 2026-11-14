import Foundation

// Kontrollierter FFI-Adapter für den Produktions-Vorschaudecoder, ohne Audioausgabe.
struct PreviewRegion: Sendable { let samples: [Float]; let sampleRate: UInt32; let startSeconds: Double }
final class PlayerEngine: @unchecked Sendable {
    let region: PreviewRegion?
    init(region: PreviewRegion?) { self.region = region }
    func decodeRegionWithHeaders(source: String, startSeconds: Double, durationSeconds: Double,
                                 mono: Bool, headers: [String: String]) -> PreviewRegion? { region }
}
enum AutomixOverlayCache {
    struct Overlay { let bpm: Double?; let key: String? }
    static func load(forFilePath: String) -> Overlay? { nil }
}
func cachedBeatTimes(path: String) -> [Double] { [0, 0.5, 1, 1.5] }
