import Foundation

@main
struct VideoReferenceGeometryTests {
    static func main() {
        for width: CGFloat in [320, 390, 430, 768] {
            let geometry = ArcPlaybackGeometry(size: CGSize(width: width, height: width / 1.48))
            for index in 0...100 {
                let value = Double(index) / 100
                let inverse = geometry.progress(at: geometry.point(progress: value))
                precondition(abs(value - inverse) < 0.00001, "Bogen: Zeichnung und Seek müssen übereinstimmen")
            }
            precondition(geometry.progress(at: CGPoint(x: 0, y: geometry.center.y + 10)) == 0)
            precondition(geometry.progress(at: CGPoint(x: width, y: geometry.center.y + 10)) == 1)
        }
        precondition(ArcPlaybackGeometry.seconds(progress: 2, duration: 180) == 180)
        precondition(ArcPlaybackGeometry.seconds(progress: -1, duration: 180) == 0)
        precondition(ArcPlaybackGeometry.seconds(progress: 0.5, duration: .nan) == nil)
        precondition(ArcPlaybackGeometry.seconds(progress: 0.5, duration: 0) == nil)
        precondition(ConstellationGeometry.milliseconds(position: .nan, offset: 0) == 0)
        precondition(ConstellationGeometry.milliseconds(position: .infinity, offset: 0) == 0)
        precondition(ConstellationGeometry.milliseconds(position: 2.5, offset: 500) == 2000)
        precondition(ConstellationGeometry.milliseconds(position: 0.1, offset: 500) == 0)
        precondition(ConstellationGeometry.milliseconds(position: 2.5, offset: -500) == 3000)
        let size = CGSize(width: 390, height: 844)
        let points = (0..<12).map {
            ConstellationGeometry.point(index: $0, count: 12, seed: 1000, size: size, reduced: false)
        }
        for index in 1..<points.count { precondition(points[index].x > points[index - 1].x) }
        let end = ConstellationGeometry.camera(points: points, current: 3, elapsed: 260, size: size, reduced: false)
        let next = ConstellationGeometry.camera(points: points, current: 4, elapsed: 0, size: size, reduced: false)
        precondition(abs(end.width - next.width) < 0.000001 && abs(end.height - next.height) < 0.000001,
                     "Die Kamera darf beim Wortwechsel nicht springen")
        precondition(ConstellationGeometry.camera(points: points, current: 3, elapsed: 100, size: size, reduced: true) == .zero)
        let repeated = ConstellationGeometry.point(index: 4, count: 12, seed: 1000, size: size, reduced: false)
        precondition(repeated == points[4], "Seek muss dieselbe Lage wiederherstellen")
        print("Videoreferenzen: Bogen-Seek, Zeitgrenzen, Versatz, Kamerastetigkeit und Reduce Motion BESTANDEN")
    }
}
