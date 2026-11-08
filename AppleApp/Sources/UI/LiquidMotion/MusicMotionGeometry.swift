import Foundation
import CoreGraphics

/// Zustandsfreie Geometrie für Covergalaxie, Bogen und begrenzte Fortschritte.
enum MusicMotionGeometry {
    static func progress(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }

    static func wrapped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + count) % count
    }

    static func neighbours(selected: Int, count: Int, maximum: Int = 7) -> [Int] {
        guard count > 1, maximum > 0 else { return [] }
        return (1...min(maximum, count - 1)).map { wrapped(selected + $0, count: count) }
    }

    static func orbit(index: Int, count: Int, size: CGSize) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(max(1, count)) - .pi / 2
        return CGPoint(x: size.width / 2 + cos(angle) * max(0, size.width / 2 - 34),
                       y: size.height / 2 + sin(angle) * max(0, size.height / 2 - 32))
    }

    static func arc(index: Int, count: Int, size: CGSize) -> CGPoint {
        let phase = count > 1 ? Double(index) / Double(count - 1) : 0.5
        let angle = (-150 + phase * 120) * .pi / 180
        let radius = max(1, size.width * 0.43)
        return CGPoint(x: size.width / 2 + cos(angle) * radius,
                       y: size.height - 12 + sin(angle) * radius)
    }
}
