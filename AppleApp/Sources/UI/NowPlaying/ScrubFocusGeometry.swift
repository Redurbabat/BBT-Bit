import Foundation

/// Lokale Vergrößerung am Finger, keine erfundene Audiowellenform.
enum ScrubFocusGeometry {
    static func emphasis(at value: Double, focus: Double,
                         scrubbing: Bool, reducedMotion: Bool) -> Double {
        guard scrubbing, !reducedMotion, value.isFinite, focus.isFinite,
              (0...1).contains(value), (0...1).contains(focus) else { return 0 }
        let proximity = max(0, 1 - abs(value - focus) / 0.12)
        return proximity * proximity * (3 - 2 * proximity)
    }
}
