import Foundation

struct ConstellationWord: Equatable {
    let text: String
    let start: Int64
    let end: Int64
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

    static func camera(points: [CGPoint], current: Int, elapsed: Int64, size: CGSize, reduced: Bool) -> CGSize {
        guard !reduced, points.indices.contains(current) else { return .zero }
        let previous = points[max(0, current - 1)]
        let target = points[current]
        let t = min(1, max(0, Double(elapsed) / 260))
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
