import Foundation

/// Misst Zeitfortschritt zwischen zwei Beobachtungen, ohne Wiedergabe zu verändern.
struct PlaybackProgressTracker {
    private struct Sample {
        let trackID: String
        let position: Double
        let at: TimeInterval
        let advancing: Bool
    }
    private var previous: Sample?

    mutating func observe(trackID: String?, position: Double, at: TimeInterval,
                          playing: Bool, buffering: Bool) -> Bool {
        guard let trackID, position.isFinite, position >= 0, at.isFinite else {
            previous = nil
            return false
        }
        let current = Sample(trackID: trackID, position: position, at: at,
                             advancing: playing && !buffering)
        defer { previous = current }
        guard let previous, previous.trackID == trackID,
              previous.advancing, current.advancing else { return false }
        let elapsed = at - previous.at
        let delta = position - previous.position
        // Große Sprünge sind Seeks; sie belegen keinen laufenden Transport.
        return elapsed > 0 && delta > 0.25 && delta <= elapsed * 2 + 0.5
    }
}
