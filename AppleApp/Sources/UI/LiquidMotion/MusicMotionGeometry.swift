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

    /// Geneigte Umlaufbahn einer Galaxie. `depth` ist 0 hinten (oben) und 1 vorn (unten).
    static func tiltedOrbit(angle: Double, size: CGSize, inset: CGSize = CGSize(width: 34, height: 40)) -> (point: CGPoint, depth: Double) {
        guard angle.isFinite else { return (CGPoint(x: size.width / 2, y: size.height / 2), 0.5) }
        let radiusX = max(0, size.width / 2 - inset.width)
        let radiusY = max(0, size.height / 2 - inset.height)
        return (CGPoint(x: size.width / 2 + CGFloat(cos(angle)) * radiusX,
                        y: size.height / 2 + CGFloat(sin(angle)) * radiusY),
                (sin(angle) + 1) / 2)
    }

    /// Ein Teilchen der zweiarmigen Spiralgalaxie; dieselbe Nummer liegt immer
    /// auf derselben Bahn, `rotation` dreht die ganze Scheibe.
    static func spiralParticle(index: Int, rotation: Double, size: CGSize) -> (point: CGPoint, depth: Double, radius: Double) {
        let key = UInt64(max(0, index)) &* 3
        let radius = 0.08 + 0.92 * unit(key &+ 1)
        let arm = Double(index % 2) * .pi
        let spread = (unit(key &+ 2) - 0.5) * 0.6 * (1.25 - radius)
        let angle = arm + radius * 2.6 * .pi + spread + (rotation.isFinite ? rotation : 0)
        let radiusX = max(0, size.width / 2 - 12)
        let radiusY = max(0, size.height / 2 - 12) * 0.82
        return (CGPoint(x: size.width / 2 + CGFloat(cos(angle) * radius) * radiusX,
                        y: size.height / 2 + CGFloat(sin(angle) * radius) * radiusY),
                (sin(angle) + 1) / 2, radius)
    }

    /// Deterministischer Zufall (SplitMix64), unabhängig von Prozess und Gerät.
    static func unit(_ seed: UInt64) -> Double {
        var value = seed &+ 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value >> 11) / 9_007_199_254_740_992.0
    }

    static func arc(index: Int, count: Int, size: CGSize) -> CGPoint {
        let phase = count > 1 ? Double(index) / Double(count - 1) : 0.5
        let angle = (-150 + phase * 120) * .pi / 180
        let radius = max(1, size.width * 0.43)
        return CGPoint(x: size.width / 2 + cos(angle) * radius,
                       y: size.height - 12 + sin(angle) * radius)
    }
}
