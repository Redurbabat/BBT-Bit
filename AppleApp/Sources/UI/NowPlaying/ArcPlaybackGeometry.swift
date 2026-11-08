import Foundation

/// Gemeinsame Geometrie für Zeichnung, Trefferbereich und Seek des Wiedergabebogens.
struct ArcPlaybackGeometry {
    let size: CGSize
    var center: CGPoint { CGPoint(x: size.width / 2, y: size.height - 24) }
    var radius: CGFloat { max(1, size.width * 0.46 - 34) }
    var controlsRadius: CGFloat { radius + 42 }

    func point(progress: Double, radius: CGFloat? = nil) -> CGPoint {
        let angle = (-160 + 140 * Self.clamp(progress)) * .pi / 180
        let distance = radius ?? self.radius
        return CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
    }

    func progress(at point: CGPoint) -> Double {
        guard point.x.isFinite, point.y.isFinite else { return 0 }
        let angle = atan2(point.y - center.y, point.x - center.x) * 180 / .pi
        // Unterhalb der Mitte gehört der linke Rand zum Anfang, der rechte zum Ende.
        if angle > 0 { return point.x < center.x ? 0 : 1 }
        return Self.clamp((angle + 160) / 140)
    }

    static func clamp(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }

    static func seconds(progress: Double, duration: Double) -> Double? {
        guard duration.isFinite, duration > 0 else { return nil }
        return clamp(progress) * duration
    }
}
