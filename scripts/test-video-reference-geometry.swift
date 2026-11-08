import Foundation
import CoreGraphics

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
        let quickEnd = ConstellationGeometry.camera(points: points, current: 3, elapsed: 80,
            size: size, reduced: false, duration: 80)
        precondition(abs(quickEnd.width - next.width) < 0.000001 && abs(quickEnd.height - next.height) < 0.000001,
                     "Auch kurze Wortzeiten müssen die Kamera vor dem Folgewort abschließen")
        precondition(ConstellationGeometry.camera(points: points, current: 3, elapsed: 100, size: size, reduced: true) == .zero)
        let repeated = ConstellationGeometry.point(index: 4, count: 12, seed: 1000, size: size, reduced: false)
        precondition(repeated == points[4], "Seek muss dieselbe Lage wiederherstellen")
        precondition(ConstellationTimeline.finaleProgress(position: 169.999, duration: 180) == nil)
        precondition(ConstellationTimeline.finaleProgress(position: 170, duration: 180) == 0)
        precondition(ConstellationTimeline.finaleProgress(position: 175, duration: 180) == 0.5)
        precondition(ConstellationTimeline.finaleProgress(position: 180, duration: 180) == 1)
        precondition(ConstellationTimeline.finaleProgress(position: 200, duration: 180) == 1)
        precondition(ConstellationTimeline.finaleProgress(position: 120, duration: 180) == nil,
                     "Zurückspulen muss die Schlusskarte verlassen")
        precondition(ConstellationTimeline.finaleProgress(position: 0, duration: 0) == nil)
        precondition(ConstellationTimeline.finaleProgress(position: 0, duration: .nan) == nil)
        precondition(ConstellationTimeline.finaleProgress(position: .infinity, duration: 180) == nil)
        precondition(ConstellationTimeline.finaleProgress(position: 2.5, duration: 5) == 0.5)
        precondition(ConstellationTimeline.pulse(position: 0.5, markers: []) == 0)
        precondition(ConstellationTimeline.pulse(position: 0.4, markers: [0.5, 1]) == 0)
        precondition(ConstellationTimeline.pulse(position: 0.5, markers: [0.5, 1]) == 1)
        precondition(ConstellationTimeline.pulse(position: 0.6, markers: [0.5, 1]) > 0)
        precondition(ConstellationTimeline.pulse(position: 0.9, markers: [0.5, 1]) == 0,
                     "Zwischen echten Markern darf kein erfundener Lichtschlag entstehen")
        let words = (0..<100).map { ConstellationWord(text: "Licht", start: Int64($0 * 1000), end: Int64(($0 + 1) * 1000)) }
        precondition(ConstellationTimeline.activeIndex(words: [], milliseconds: 0) == nil)
        precondition(ConstellationTimeline.activeIndex(words: words, milliseconds: -1) == nil)
        precondition(ConstellationTimeline.activeIndex(words: words, milliseconds: 89000) == 89)
        precondition(ConstellationTimeline.activeIndex(words: words, milliseconds: 23000) == 23)
        for width: CGFloat in [320, 390, 768] {
            let viewport = CGSize(width: width, height: 650)
            for word in words {
                let point = ConstellationTimeline.point(word: word, span: 100000, size: viewport)
                precondition(CGRect(origin: .zero, size: viewport).contains(point), "Alle Songsterne müssen in die Schlusskarte passen")
                precondition(point == ConstellationTimeline.point(word: word, span: 100000, size: viewport))
            }
            for count in [1, 2, 7, 30] {
                let neighbours = MusicMotionGeometry.neighbours(selected: count - 1, count: count)
                precondition(Set(neighbours).count == neighbours.count && !neighbours.contains(count - 1))
                for index in 0..<count {
                    let point = MusicMotionGeometry.orbit(index: index, count: count, size: viewport)
                    precondition(CGRect(origin: .zero, size: viewport).contains(point))
                }
            }
        }
        precondition(MusicMotionGeometry.neighbours(selected: 0, count: 0).isEmpty)
        precondition(MusicMotionGeometry.neighbours(selected: 0, count: 5, maximum: 0).isEmpty)
        precondition(MusicMotionGeometry.wrapped(-1, count: 5) == 4)
        precondition(MusicMotionGeometry.wrapped(6, count: 5) == 1)
        precondition(MusicMotionGeometry.progress(.nan) == 0)
        precondition(MusicMotionGeometry.progress(.infinity) == 0)
        precondition(MusicMotionGeometry.progress(-1) == 0)
        precondition(MusicMotionGeometry.progress(2) == 1)
        print("Geometrie: Bogen-Seek, Zeitgrenzen, Sternroute, echte Lichtmarker, Schlusszoom und Sammlungsauswahl BESTANDEN")
    }
}
