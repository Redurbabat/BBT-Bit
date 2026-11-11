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
        // Sternbild nach Rhythmus, Stimme und Klang
        var sung: [ConstellationWord] = []
        for index in 0..<48 {
            let jitter: Int64 = index % 3 == 0 ? 30 : -20
            let onset: Int64 = Int64(index) * 500 + jitter
            sung.append(ConstellationWord(text: "Wort\(index)", start: onset, end: Int64(index) * 500 + 420, line: index / 6))
        }
        let grid: [Double] = (0..<48).map { (beat: Int) -> Double in Double(beat) * 0.5 }
        let quiet = ConstellationVoiceLayout.layout(words: sung, voices: [], beats: [], seed: 7)
        precondition(quiet.stars.count == sung.count && !quiet.signature.voiced)
        for index in 1..<quiet.stars.count {
            precondition(quiet.stars[index].point.x > quiet.stars[index - 1].point.x, "Die Route läuft mit der Zeit vorwärts")
        }
        precondition(quiet == ConstellationVoiceLayout.layout(words: sung, voices: [], beats: [], seed: 7),
                     "Seek muss dieselbe Form wiederherstellen")
        let gridded = ConstellationVoiceLayout.layout(words: sung, voices: [], beats: grid, seed: 7)
        var widths = Set<Int>()
        for index in 1..<gridded.stars.count {
            let step: CGFloat = gridded.stars[index].point.x - gridded.stars[index - 1].point.x
            widths.insert(Int((step * 100).rounded()))
        }
        precondition(widths.count <= 2,
                     "Erkannte Beats rasten kleine Einsatzschwankungen auf den Rhythmus")
        precondition(gridded.stars.filter { (star: ConstellationStar) -> Bool in star.onBeat }.count > sung.count / 2)
        var low: [ConstellationVoice] = []
        var high: [ConstellationVoice] = []
        for index in sung.indices {
            let interval: Double = pow(2.0, Double(index % 6) / 12.0)
            low.append(ConstellationVoice(energyDb: -20, brightnessHz: 900, pitchHz: 110 * interval, pitchConfidence: 0.9))
            high.append(ConstellationVoice(energyDb: -20, brightnessHz: 2400, pitchHz: 392 * interval, pitchConfidence: 0.9))
        }
        let deep = ConstellationVoiceLayout.layout(words: sung, voices: low, beats: grid, seed: 7)
        let bright = ConstellationVoiceLayout.layout(words: sung, voices: high, beats: grid, seed: 7)
        precondition(deep.signature.voiced && bright.signature.voiced)
        precondition(deep.signature.register < 0.2 && bright.signature.register > 0.8, "Stimmlage bestimmt den Songcharakter")
        precondition(abs(deep.signature.hue - bright.signature.hue) > 0.2, "Tiefe und hohe Stimmen bekommen eigene Farben")
        precondition(deep.stars[5].point.y < deep.stars[0].point.y, "Höher gesungene Wörter stehen höher")
        var climbing = low
        climbing[20].pitchHz = 220
        climbing[20].energyDb = -6
        let melody = ConstellationVoiceLayout.layout(words: sung, voices: climbing, beats: grid, seed: 7)
        precondition(melody.stars[20].point.y < deep.stars[20].point.y && melody.stars[20].energy > deep.stars[20].energy)
        precondition(ConstellationVoiceLayout.layout(words: sung, voices: Array(low.prefix(3)), beats: [], seed: 7) == quiet,
                     "Unvollständige Messung darf keine Stimmform vortäuschen")
        precondition(ConstellationVoiceLayout.layout(words: sung, voices: [], beats: [], seed: 8) != quiet,
                     "Jeder Song bekommt ohne Messung einen eigenen Zeilenbogen")
        for width: CGFloat in [320, 390, 768] {
            for index in 1..<sung.count {
                let onset = sung[index].start
                let arriving = ConstellationVoiceLayout.head(layout: melody, words: sung, milliseconds: onset, width: width)
                precondition(arriving.index == index && arriving.draw == 0 && arriving.appear == 0)
                precondition(arriving.camera == ConstellationVoiceLayout.cameraTarget(layout: melody, index: index - 1, width: width),
                             "Die Kamera gleitet erst nach dem Einsatz weiter")
                let before = ConstellationVoiceLayout.head(layout: melody, words: sung, milliseconds: onset - 1, width: width)
                precondition(hypot(before.camera.x - arriving.camera.x, before.camera.y - arriving.camera.y) < 1,
                             "Die Kamera darf beim Wortwechsel nicht springen")
                // Kürzester Wortabstand hier: 450 ms. Kurz davor ist die Kamera angekommen.
                let settled = ConstellationVoiceLayout.head(layout: melody, words: sung, milliseconds: onset + 449, width: width)
                let target = ConstellationVoiceLayout.cameraTarget(layout: melody, index: index, width: width)
                precondition(settled.index == index && settled.appear == 1 && settled.draw == 1)
                precondition(hypot(settled.camera.x - target.x, settled.camera.y - target.y) < 0.05,
                             "Die Kamera erreicht das Wort vor dem nächsten Einsatz")
            }
        }
        precondition(ConstellationVoiceLayout.head(layout: melody, words: sung, milliseconds: -5, width: 390).camera
                     == ConstellationVoiceLayout.cameraTarget(layout: melody, index: 0, width: 390))
        for index in sung.indices where index > 0 && sung[index].line != sung[index - 1].line {
            precondition(melody.stars[index].point.x - melody.stars[index - 1].point.x > ConstellationVoiceLayout.spacing * 1.5,
                         "Eine neue Zeile beginnt als eigenes Sternbild")
            precondition(melody.stars[index].lineStartX == melody.stars[index].point.x && melody.stars[index].lineStart)
        }
        precondition(ConstellationVoiceLayout.settledHistory(layout: melody, from: 30, drag: 0, current: 30) == 30)
        precondition(ConstellationVoiceLayout.settledHistory(layout: melody, from: 30, drag: 100_000, current: 30) == 0)
        precondition(ConstellationVoiceLayout.settledHistory(layout: melody, from: 30, drag: -400, current: 30) == nil,
                     "Über das aktuelle Wort hinaus wischen kehrt zum Live-Bild zurück")
        let back = ConstellationVoiceLayout.settledHistory(layout: melody, from: 30, drag: 120, current: 30) ?? 99
        precondition(back < 30 && back > 20, "Nach rechts ziehen zeigt frühere Wörter")
        var long: [ConstellationWord] = []
        var longVoices: [ConstellationVoice] = []
        for index in 0..<600 {
            let onset: Int64 = Int64(index) * 420
            long.append(ConstellationWord(text: "x", start: onset, end: onset + 300, line: index / 7))
            let interval: Double = pow(2.0, Double(index % 13) / 12.0)
            longVoices.append(ConstellationVoice(energyDb: -30, brightnessHz: 1800, pitchHz: 180 * interval, pitchConfidence: 0.8))
        }
        for layout in [melody, quiet, ConstellationVoiceLayout.layout(words: long, voices: longVoices, beats: [], seed: 3),
                       ConstellationVoiceLayout.layout(words: Array(long.prefix(1)), voices: [], beats: [], seed: 3)] {
            for viewport in [CGSize(width: 320, height: 568), CGSize(width: 390, height: 844), CGSize(width: 1024, height: 700)] {
                let map = ConstellationVoiceLayout.mapPoints(layout: layout, size: viewport)
                precondition(map.count == layout.stars.count)
                for point in map {
                    precondition(CGRect(origin: .zero, size: viewport).contains(point), "Die Schlusskarte zeigt jeden Stern")
                }
            }
        }
        precondition(ConstellationVoiceLayout.mapPoints(layout: .empty, size: size).isEmpty)
        precondition(ConstellationVoiceLayout.layout(words: [], voices: [], beats: [], seed: 1).stars.isEmpty)
        precondition(ConstellationVoiceLayout.boltProgress(elapsed: 0) == 0)
        precondition(ConstellationVoiceLayout.boltProgress(elapsed: 1.0) < 1 && ConstellationVoiceLayout.boltProgress(elapsed: 1.41) == 1,
                     "Der Schlussblitz läuft in gut einer Sekunde durch alle Sterne")
        precondition(ConstellationVoiceLayout.foldProgress(elapsed: 0.45) == 1 && ConstellationVoiceLayout.flash(elapsed: 3) == 0)
        precondition(ConstellationVoiceLayout.seed("Titel") == ConstellationVoiceLayout.seed("Titel"))
        // Galaxie: geneigte Bahn und Spiralarme bleiben im Bild
        for viewport in [CGSize(width: 320, height: 300), CGSize(width: 390, height: 300), CGSize(width: 768, height: 300)] {
            for step in 0...72 {
                let orbit = MusicMotionGeometry.tiltedOrbit(angle: Double(step) * .pi / 36, size: viewport)
                precondition(CGRect(origin: .zero, size: viewport).contains(orbit.point) && (0...1).contains(orbit.depth))
            }
            for particle in 0..<300 {
                let star = MusicMotionGeometry.spiralParticle(index: particle, rotation: Double(particle) * 0.37, size: viewport)
                precondition(CGRect(origin: .zero, size: viewport).contains(star.point), "Spiralarme bleiben in der Galaxie")
                precondition(star.point == MusicMotionGeometry.spiralParticle(index: particle, rotation: Double(particle) * 0.37, size: viewport).point)
            }
        }
        precondition(MusicMotionGeometry.tiltedOrbit(angle: .pi / 2, size: CGSize(width: 300, height: 300)).depth == 1)
        precondition(MusicMotionGeometry.tiltedOrbit(angle: .nan, size: CGSize(width: 300, height: 300)).point == CGPoint(x: 150, y: 150))
        precondition(MusicMotionGeometry.unit(42) == ConstellationGeometry.unit(42))
        print("Geometrie: Bogen-Seek, Zeitgrenzen, Sternroute, echte Lichtmarker, Schlusszoom, Stimmform, Verlauf, Blitzkarte, Galaxie und Sammlungsauswahl BESTANDEN")
    }
}
