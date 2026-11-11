import Foundation
import CoreGraphics

/// Stimm- und Klangwerte eines Liedtextwortes aus der Rust-Analyse
/// (`lyricVoiceContour`). Fehlt die Messung, bleibt die Liste leer; es werden
/// keine Stimmwerte erfunden.
struct ConstellationVoice: Equatable {
    var energyDb: Double
    var brightnessHz: Double
    var pitchHz: Double
    var pitchConfidence: Double
}

/// Charakter eines Songs aus Stimmlage, Klangfarbe, Dynamik und Tempo.
struct ConstellationSignature: Equatable {
    /// Grundfarbton 0…1: tiefe Stimmen glühen warm, hohe Stimmen kühl.
    var hue: Double
    /// Zweiter Farbton für Blitz und Glanzpunkte.
    var accentHue: Double
    /// 0 = straffe Linie bei schnellem Tempo, 1 = weite Bögen bei ruhigem Tempo.
    var flow: Double
    /// Lautstärkespanne 0…1: spreizt die Sterngrößen.
    var dynamics: Double
    /// Stimmlage 0 (tief) … 1 (hoch).
    var register: Double
    /// true, wenn die Form aus gemessener Stimme oder Klangfarbe stammt.
    var voiced: Bool
}

struct ConstellationStar: Equatable {
    /// Weltkoordinate: x folgt dem Rhythmus, y der Stimmhöhe plus Zeilenstufe.
    var point: CGPoint
    /// Mittlere Höhe der eigenen Zeile: Die Kamera bleibt pro Zeile ruhig.
    var cameraY: CGFloat
    /// Reine Melodiehöhe ohne Zeilenstufe; die Schlusskarte faltet damit enger.
    var melodyY: CGFloat
    /// x des ersten Wortes derselben Zeile.
    var lineStartX: CGFloat
    /// Lautstärke des Wortes relativ zum Song, 0…1.
    var energy: Double
    var onBeat: Bool
    var lineStart: Bool
}

struct ConstellationLayout: Equatable {
    var stars: [ConstellationStar]
    var bounds: CGRect
    var signature: ConstellationSignature

    static let empty = ConstellationLayout(stars: [], bounds: .zero,
                                           signature: ConstellationVoiceLayout.neutralSignature(seed: 0))
}

/// Live-Zustand: aktuelles Wort, Kamerapunkt und Einblendfortschritt.
struct ConstellationHead: Equatable {
    var index: Int
    /// Weltpunkt, der in der Bildmitte stehen soll.
    var camera: CGPoint
    /// 0…1: Die Linie zum neuen Stern wird gezogen.
    var draw: Double
    /// 0…1: Das große Wort blendet ein, das vorige schrumpft zur Beschriftung.
    var appear: Double
}

/// Zustandsfreie Sternbildgeometrie: gleiche Eingaben ergeben nach Seek oder
/// Wiederaufnahme dieselbe Form. Jeder Song bekommt seine Form aus Rhythmus,
/// Stimmhöhe, Klangfarbe und Pegel.
enum ConstellationVoiceLayout {
    /// Abstand zweier Wörter im Abstand eines Beats (wie im Original etwa sieben Wörter je Bildbreite).
    static let spacing: CGFloat = 46
    /// Höhe eines Halbtons in der Weltkoordinate.
    static let semitone: CGFloat = 7
    /// Maßstab der Verlaufsansicht nach dem Wischen nach links.
    static let historyScale: CGFloat = 0.5
    /// Schlussphase: Falten zur Karte, dann ein schneller Blitz durch alle Sterne.
    static let foldDuration = 0.45
    static let boltDelay = 0.3
    static let boltDuration = 1.1

    /// Stabiler Songschlüssel (FNV-1a); `hashValue` wäre pro Prozess zufällig.
    static func seed(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 { hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
        return hash
    }

    static func median(_ values: [Double]) -> Double? {
        let sorted = values.filter(\.isFinite).sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    static func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = Int((Double(sorted.count - 1) * fraction).rounded())
        return sorted[min(sorted.count - 1, max(0, index))]
    }

    /// Mittlerer Beatabstand aus erkannten Beats; ohne ausreichende Marker nil.
    static func beatPeriod(_ beats: [Double]) -> Double? {
        guard beats.count >= 4 else { return nil }
        var gaps: [Double] = []
        for index in 1..<beats.count {
            let gap = beats[index] - beats[index - 1]
            if gap.isFinite, gap > 0.2, gap < 2 { gaps.append(gap) }
        }
        return median(gaps)
    }

    /// Tiefe Stimmen: rot bis bernstein, mittlere: rosé bis violett, hohe: eisblau.
    /// Hellere Klangfarbe verschiebt den Ton leicht Richtung kühl.
    static func hue(register: Double, brightness: Double) -> Double {
        let anchors: [Double] = [1.02, 0.95, 0.80, 0.60]
        let scaled = clamp(register) * Double(anchors.count - 1)
        let low = min(anchors.count - 2, Int(scaled))
        let fraction = scaled - Double(low)
        let base = anchors[low] + (anchors[low + 1] - anchors[low]) * fraction
        return wrap(base - (clamp(brightness) - 0.5) * 0.06)
    }

    static func neutralSignature(seed: UInt64) -> ConstellationSignature {
        let register = ConstellationGeometry.unit(seed)
        let tone = hue(register: register, brightness: 0.5)
        return ConstellationSignature(hue: tone, accentHue: wrap(tone - 0.1), flow: 0.5,
                                      dynamics: 0.4, register: register, voiced: false)
    }

    static func layout(words: [ConstellationWord], voices: [ConstellationVoice],
                       beats: [Double], seed: UInt64) -> ConstellationLayout {
        guard !words.isEmpty else {
            return ConstellationLayout(stars: [], bounds: .zero, signature: neutralSignature(seed: seed))
        }
        let measured = voices.count == words.count ? voices : []
        let starts = words.map { Double($0.start) / 1000 }
        var wordGaps: [Double] = []
        for index in 1..<starts.count {
            let gap = starts[index] - starts[index - 1]
            if gap > 0.08, gap < 3 { wordGaps.append(gap) }
        }
        let detected = beatPeriod(beats)
        let period = detected ?? min(1.2, max(0.25, median(wordGaps) ?? 0.5))

        // x: Abstand in Beats; mit erkannten Beats auf halbe Schläge gerastet.
        var xs: [CGFloat] = [0]
        for index in 1..<words.count {
            var steps = max(0, starts[index] - starts[index - 1]) / period
            if detected != nil { steps = max(0.5, (steps * 2).rounded() / 2) }
            var dx = spacing * CGFloat(min(2.8, max(0.55, pow(steps, 0.62))))
            // Neue Zeile beginnt rechts außerhalb der alten, wie im Original.
            if words[index].line != words[index - 1].line { dx += spacing * 0.9 }
            xs.append(xs[index - 1] + dx)
        }

        // Pegel relativ zum Song: lauteste Wörter bilden die hellsten Sterne.
        let energyValues = measured.map(\.energyDb).filter { $0.isFinite && $0 > -100 }.sorted()
        let floorDb = percentile(energyValues, 0.1)
        let ceilingDb = percentile(energyValues, 0.9)
        let energies: [Double] = words.indices.map { index -> Double in
            if !energyValues.isEmpty {
                let value = measured[index].energyDb
                guard value.isFinite, value > -100 else { return 0 }
                return clamp((value - floorDb) / max(3, ceilingDb - floorDb))
            }
            let length = Double(max(0, words[index].end - words[index].start)) / 1000
            return min(1, max(0.15, length / (period * 2)))
        }

        // y: gesungene Tonhöhe in Halbtönen um die Songmitte; ohne sichere
        // Tonhöhe die Klangfarbe; ohne Messung ein Zeilenbogen je Songschlüssel.
        let voicedPitches = measured.filter(isVoiced).map(\.pitchHz)
        let brightnessValues = measured.map(\.brightnessHz).filter { $0.isFinite && $0 > 50 }
        let needed = max(3, words.count / 6)
        let usesPitch = voicedPitches.count >= needed
        let usesBrightness = !usesPitch && brightnessValues.count >= needed
        let pitchCentre = median(voicedPitches) ?? 220
        let brightCentre = median(brightnessValues) ?? 1500
        var lineCount: [Int: Int] = [:]
        for word in words { lineCount[word.line, default: 0] += 1 }
        var lineSeen: [Int: Int] = [:]
        let targets: [Double?] = words.indices.map { index -> Double? in
            let word = words[index]
            let position = lineSeen[word.line, default: 0]
            lineSeen[word.line] = position + 1
            if usesPitch {
                let voice = measured[index]
                return isVoiced(voice) ? min(12, max(-12, 12 * log2(voice.pitchHz / pitchCentre))) : nil
            }
            if usesBrightness {
                let value = measured[index].brightnessHz
                guard value.isFinite, value > 50 else { return nil }
                return min(8, max(-8, 5 * log2(value / brightCentre)))
            }
            let phase = (Double(position) + 0.5) / Double(max(1, lineCount[word.line] ?? 1))
            let lineKey = UInt64(truncatingIfNeeded: word.line)
            let lift = 3 + 5 * ConstellationGeometry.unit(seed &+ lineKey)
            let tilt = (ConstellationGeometry.unit(seed &* 3 &+ lineKey) - 0.5) * 8
            return sin(phase * .pi) * lift + (phase - 0.5) * tilt
        }
        var level = 0.0
        var ys: [CGFloat] = []
        for index in words.indices {
            let fresh = index == 0 || words[index].line != words[index - 1].line
            if let target = targets[index] {
                level += (target - level) * (fresh ? 0.75 : 0.6)
            } else {
                level *= 0.92
            }
            ys.append(CGFloat(-level) * semitone)
        }
        // Zeilenstufe nach Rhythmus: Jede neue Zeile setzt tiefer an, die alte
        // wandert nach links oben. Eine lange Pause (ab vier Beats) beginnt einen
        // neuen Abschnitt wieder oben; nach vier Stufen ebenfalls.
        var baselines: [CGFloat] = []
        var step = 0
        for index in words.indices {
            if index > 0, words[index].line != words[index - 1].line {
                let pause = starts[index] - Double(words[index - 1].end) / 1000
                step = pause >= period * 4 || step >= 3 ? 0 : step + 1
            }
            baselines.append(CGFloat(step) * 52)
        }
        var lineSum: [Int: CGFloat] = [:]
        var lineFirstX: [Int: CGFloat] = [:]
        for index in words.indices {
            lineSum[words[index].line, default: 0] += ys[index] + baselines[index]
            if lineFirstX[words[index].line] == nil { lineFirstX[words[index].line] = xs[index] }
        }

        var stars: [ConstellationStar] = []
        stars.reserveCapacity(words.count)
        var bounds = CGRect.null
        for index in words.indices {
            let line = words[index].line
            let point = CGPoint(x: xs[index], y: ys[index] + baselines[index])
            bounds = bounds.union(CGRect(origin: point, size: .zero))
            stars.append(ConstellationStar(
                point: point,
                cameraY: (lineSum[line] ?? 0) / CGFloat(max(1, lineCount[line] ?? 1)),
                melodyY: ys[index], lineStartX: lineFirstX[line] ?? xs[index],
                energy: energies[index],
                onBeat: nearBeat(starts[index], beats: beats, period: period),
                lineStart: index == 0 || words[index].line != words[index - 1].line))
        }

        let register = usesPitch ? clamp(log2(pitchCentre / 100) / 2) : neutralSignature(seed: seed).register
        let brightness = brightnessValues.isEmpty ? 0.5 : clamp(log2(brightCentre / 600) / 3)
        let tone = hue(register: register, brightness: brightness)
        let signature = ConstellationSignature(
            hue: tone,
            accentHue: wrap(tone - 0.1 + brightness * 0.05),
            flow: clamp((period - 0.33) / 0.42),
            dynamics: energyValues.count >= 3 ? clamp((ceilingDb - floorDb) / 24) : 0.4,
            register: register,
            voiced: usesPitch || usesBrightness)
        return ConstellationLayout(stars: stars, bounds: bounds.insetBy(dx: -24, dy: -24), signature: signature)
    }

    /// Kameraziel für ein Wort: Eine kurze Zeile steht mittig, eine lange hält
    /// das neueste Wort im rechten Drittel – wie im Original.
    static func cameraTarget(layout: ConstellationLayout, index: Int, width: CGFloat) -> CGPoint {
        guard layout.stars.indices.contains(index) else { return .zero }
        let star = layout.stars[index]
        let span = star.point.x - star.lineStartX
        let x = span < width * 0.6 ? (star.lineStartX + star.point.x) / 2 : star.point.x - width * 0.3
        return CGPoint(x: x, y: star.cameraY)
    }

    /// Live-Zustand: Beim Einsatz erscheint der neue Stern, die Linie wird
    /// gezogen und die Kamera gleitet nach. Jede Bewegung endet vor dem nächsten
    /// Einsatz, damit nichts springt.
    static func head(layout: ConstellationLayout, words: [ConstellationWord], milliseconds: Int64,
                     width: CGFloat) -> ConstellationHead {
        guard !layout.stars.isEmpty, layout.stars.count == words.count else {
            return ConstellationHead(index: 0, camera: .zero, draw: 1, appear: 1)
        }
        guard let index = ConstellationTimeline.activeIndex(words: words, milliseconds: milliseconds) else {
            return ConstellationHead(index: 0, camera: cameraTarget(layout: layout, index: 0, width: width),
                                     draw: 0, appear: 0)
        }
        let target = cameraTarget(layout: layout, index: index, width: width)
        let following = index + 1 < words.count ? max(1, words[index + 1].start - words[index].start) : 450
        let elapsed = Double(milliseconds - words[index].start)
        let appear = clamp(elapsed / Double(min(260, following)))
        let draw = clamp(elapsed / Double(min(220, following)))
        guard index > 0 else {
            return ConstellationHead(index: 0, camera: target, draw: draw, appear: appear)
        }
        let previous = cameraTarget(layout: layout, index: index - 1, width: width)
        let t = clamp(elapsed / Double(min(450, following)))
        let eased = CGFloat(t * t * (3 - 2 * t))
        return ConstellationHead(
            index: index,
            camera: CGPoint(x: previous.x + (target.x - previous.x) * eased,
                            y: previous.y + (target.y - previous.y) * eased),
            draw: draw, appear: appear)
    }

    /// Reisekamera: Der Kamerapunkt steht in der Bildmitte, leicht über der Mitte.
    static func journeyOffset(head: ConstellationHead, size: CGSize, scale: CGFloat = 1) -> CGSize {
        CGSize(width: size.width * 0.5 - head.camera.x * scale,
               height: size.height * 0.42 - head.camera.y * scale)
    }

    /// Verlaufskamera: zentriert den gewählten Stern; `drag` folgt dem Finger.
    static func historyOffset(layout: ConstellationLayout, index: Int, drag: CGFloat, size: CGSize) -> CGSize {
        guard layout.stars.indices.contains(index) else { return .zero }
        let star = layout.stars[index]
        return CGSize(width: size.width * 0.5 - star.point.x * historyScale + drag,
                      height: size.height * 0.44 - star.cameraY * historyScale)
    }

    /// Nach dem Loslassen: nächster Stern unter der Bildmitte, höchstens das
    /// aktuelle Wort. Wer über das aktuelle Wort hinaus wischt, kehrt zum Live-Bild zurück (nil).
    static func settledHistory(layout: ConstellationLayout, from index: Int, drag: CGFloat, current: Int) -> Int? {
        guard layout.stars.indices.contains(index), layout.stars.indices.contains(current) else { return nil }
        let target = layout.stars[index].point.x - drag / historyScale
        if target > layout.stars[current].point.x + 70 / historyScale { return nil }
        var low = 0
        var high = current
        while low < high {
            let middle = (low + high) / 2
            if layout.stars[middle].point.x < target { low = middle + 1 } else { high = middle }
        }
        if low > 0, abs(layout.stars[low - 1].point.x - target) <= abs(layout.stars[low].point.x - target) {
            return low - 1
        }
        return low
    }

    /// Schlusskarte: die Reise wird im Schlangenlauf in Zeilen gefaltet. Die Route
    /// läuft ohne Sprung weiter, und jeder Stern passt in den sichtbaren Bereich.
    static func mapPoints(layout: ConstellationLayout, size: CGSize, inset: CGFloat = 34) -> [CGPoint] {
        let stars = layout.stars
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let width = size.width - inset * 2
        let height = size.height - inset * 2
        guard let first = stars.first, let last = stars.last, width > 10, height > 10 else {
            return stars.map { _ in centre }
        }
        let length = max(1, last.point.x - first.point.x)
        let minY = stars.reduce(first.melodyY) { min($0, $1.melodyY) }
        let maxY = stars.reduce(first.melodyY) { max($0, $1.melodyY) }
        let range = max(12, maxY - minY)
        let band = range + 30
        var rows = 1
        var scale: CGFloat = 0
        for candidate in 1...80 {
            let rowLength = length / CGFloat(candidate)
            let fitted = min(width / rowLength, height / (CGFloat(candidate - 1) * band + range))
            if fitted > scale { scale = fitted; rows = candidate }
        }
        scale = min(scale, 1.6)
        let rowLength = length / CGFloat(rows)
        let contentWidth = rowLength * scale
        let contentHeight = (CGFloat(rows - 1) * band + range) * scale
        let left = centre.x - contentWidth / 2
        let top = centre.y - contentHeight / 2
        let middleY = (minY + maxY) / 2
        return stars.map { star in
            let distance = star.point.x - first.point.x
            let row = min(rows - 1, max(0, Int(distance / rowLength)))
            let local = min(rowLength, max(0, distance - CGFloat(row) * rowLength))
            let x = row % 2 == 0 ? local : rowLength - local
            let y = CGFloat(row) * band + (star.melodyY - middleY) + range / 2
            return CGPoint(x: left + x * scale, y: top + min(contentHeight / scale, max(0, y)) * scale)
        }
    }

    /// Schlussablauf ab Eintritt in die letzten zehn Sekunden (Sekunden seit Eintritt).
    static func foldProgress(elapsed: Double) -> Double {
        let t = clamp(elapsed / foldDuration)
        return t * t * (3 - 2 * t)
    }

    /// Blitz von 0 bis 1 in gut einer Sekunde; beschleunigt leicht wie ein Einschlag.
    static func boltProgress(elapsed: Double) -> Double {
        pow(clamp((elapsed - boltDelay) / boltDuration), 1.35)
    }

    /// Kurzes Aufleuchten des ganzen Himmels, wenn der Blitz das letzte Wort erreicht.
    static func flash(elapsed: Double) -> Double {
        let after = elapsed - boltDelay - boltDuration
        guard after.isFinite, after >= 0, after < 0.45 else { return 0 }
        return 1 - after / 0.45
    }

    private static func isVoiced(_ voice: ConstellationVoice) -> Bool {
        voice.pitchConfidence >= 0.55 && voice.pitchHz.isFinite && voice.pitchHz > 50
    }

    private static func nearBeat(_ time: Double, beats: [Double], period: Double) -> Bool {
        guard !beats.isEmpty else { return false }
        var low = 0
        var high = beats.count
        while low < high {
            let middle = (low + high) / 2
            if beats[middle] < time { low = middle + 1 } else { high = middle }
        }
        var best = Double.infinity
        if low < beats.count { best = min(best, abs(beats[low] - time)) }
        if low > 0 { best = min(best, abs(beats[low - 1] - time)) }
        return best < min(0.09, period * 0.18)
    }

    static func clamp(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }

    static func wrap(_ value: Double) -> Double {
        value - floor(value)
    }
}
