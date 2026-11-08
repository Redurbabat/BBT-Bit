import Foundation
import CoreGraphics

struct ConstellationWord: Equatable {
    let text: String
    let start: Int64
    let end: Int64
    var line: Int = 0
}

/// Die gesamte Route entsteht aus echten Zeitmarken, nicht aus Zufallsbewegungen.
enum ConstellationTimeline {
    static func finaleProgress(position: Double, duration: Double) -> Double? {
        guard position.isFinite, duration.isFinite, duration > 0, position >= max(0, duration - 10) else { return nil }
        let window = min(10, duration)
        return min(1, max(0, (position - (duration - window)) / window))
    }

    static func activeIndex(words: [ConstellationWord], milliseconds: Int64) -> Int? {
        var low = 0
        var high = words.count
        while low < high {
            let middle = low + (high - low) / 2
            if words[middle].start <= milliseconds { low = middle + 1 } else { high = middle }
        }
        return low == 0 ? nil : low - 1
    }

    static func pulse(position: Double, markers: [Double]) -> Double {
        guard position.isFinite else { return 0 }
        var low = 0
        var high = markers.count
        while low < high {
            let middle = low + (high - low) / 2
            if markers[middle] <= position { low = middle + 1 } else { high = middle }
        }
        guard low > 0 else { return 0 }
        let age = position - markers[low - 1]
        guard age >= 0, age < 0.20 else { return 0 }
        return pow(1 - age / 0.20, 2)
    }

    static func point(word: ConstellationWord, span: Int64, size: CGSize) -> CGPoint {
        let fraction = min(1, max(0, Double(word.start) / Double(max(1, span))))
        let angle = -Double.pi / 2 + fraction * Double.pi * 6
        let radius = min(size.width * 0.40, max(20, size.height - 240) * 0.42) * (0.18 + fraction * 0.82)
        return CGPoint(x: size.width / 2 + cos(angle) * radius,
                       y: size.height * 0.47 + sin(angle) * radius)
    }
}

/// Zustandsfreie Geometrie: Seek und Wiederaufnahme liefern dieselbe Wortposition.
enum ConstellationGeometry {
    static func milliseconds(position: Double, offset: Int32) -> Int64 {
        guard position.isFinite else { return 0 }
        let safe = min(max(0, position), Double(Int64.max / 2) / 1000)
        return max(0, Int64(safe * 1000) - Int64(offset))
    }

    static func point(index: Int, count: Int, seed: Int64, size: CGSize, reduced: Bool) -> CGPoint {
        let key = UInt64(truncatingIfNeeded: seed) &* 31 &+ UInt64(max(0, index))
        let x: CGFloat = reduced
            ? size.width * (0.10 + 0.80 * Double(index) / Double(max(1, count - 1)))
            : CGFloat(index) * min(90, max(44, size.width * 0.12))
        let y = size.height * (0.44 + (unit(key) - 0.5) * (reduced ? 0.10 : 0.14))
        return CGPoint(x: x, y: y)
    }

    static func camera(points: [CGPoint], current: Int, elapsed: Int64, size: CGSize, reduced: Bool,
                       duration: Int64 = 260) -> CGSize {
        guard !reduced, points.indices.contains(current) else { return .zero }
        let previous = points[max(0, current - 1)]
        let target = points[current]
        let t = min(1, max(0, Double(elapsed) / Double(max(1, duration))))
        let eased = t * t * (3 - 2 * t)
        let x = previous.x + (target.x - previous.x) * eased
        let y = previous.y + (target.y - previous.y) * eased
        return CGSize(width: size.width * 0.62 - x, height: size.height * 0.44 - y)
    }

    static func unit(_ seed: UInt64) -> Double {
        var value = seed &+ 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value >> 11) / 9_007_199_254_740_992.0
    }
}
