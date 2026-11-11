import SwiftUI

/// Sternbild wie in der Nutzerreferenz: Schwarz, jede Liedzeile ein eigenes
/// Sternbild aus geraden Linien, kleine Beschriftung unter jedem Stern, das
/// gesungene Wort groß in Serifenschrift mit weichem Leuchten über einem
/// Funkelstern. Abstand nach Rhythmus, Höhe nach Stimme. Nach links wischen
/// zeigt den Verlauf; in den letzten zehn Sekunden faltet sich alles zur Karte
/// und ein Blitz läuft in gut einer Sekunde durch alle Sterne.
struct RhythmicConstellationCanvas: View {
    let words: [ConstellationWord]
    let layout: ConstellationLayout
    let positionMs: Int64
    let audioPosition: Double
    let beats: [Double]
    let historyIndex: Int?
    /// Fingerweg im Verlauf; der Inhalt folgt dem Finger.
    var historyDrag: CGFloat = 0
    /// 0…1 beim Ziehen nach links im Live-Bild: die Kamera zoomt schon auf.
    var peek: CGFloat = 0
    let overview: Bool
    let finale: Double?
    var finaleStart: Date? = nil
    let reduced: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: finale == nil || reduced)) { timeline in
            GeometryReader { proxy in
                scene(size: proxy.size, now: timeline.date)
            }
        }
    }

    private func scene(size: CGSize, now: Date) -> ConstellationScene {
        let head = ConstellationVoiceLayout.head(layout: layout, words: words, milliseconds: positionMs, width: size.width)
        var scale: CGFloat = 1
        var offset = ConstellationVoiceLayout.journeyOffset(head: head, size: size)
        if let historyIndex {
            scale = ConstellationVoiceLayout.historyScale
            offset = ConstellationVoiceLayout.historyOffset(layout: layout, index: historyIndex,
                                                            drag: historyDrag, size: size)
        } else if peek > 0 {
            scale = 1 - (1 - ConstellationVoiceLayout.historyScale) * min(1, peek)
            offset = ConstellationVoiceLayout.journeyOffset(head: head, size: size, scale: scale)
        }
        var elapsed: Double? = nil
        if finale != nil {
            elapsed = reduced ? 10 : max(0, now.timeIntervalSince(finaleStart ?? now))
        }
        let pulse = beats.isEmpty
            ? ConstellationTimeline.pulse(position: Double(positionMs) / 1000, markers: words.map { Double($0.start) / 1000 })
            : ConstellationTimeline.pulse(position: audioPosition, markers: beats)
        return ConstellationScene(words: words, layout: layout, head: head,
            historyIndex: historyIndex, elapsed: elapsed, pulse: pulse, reduced: reduced,
            scale: scale, offset: offset, mapBlend: overview || reduced ? 1 : 0)
    }
}

/// SwiftUI interpoliert Kamera und Kartenfaltung unabhängig vom Audio-Tick;
/// Blättern, Kartenwechsel und Rückkehr bleiben auch bei Pause flüssig.
private struct ConstellationScene: View, Animatable {
    let words: [ConstellationWord]
    let layout: ConstellationLayout
    let head: ConstellationHead
    let historyIndex: Int?
    let elapsed: Double?
    let pulse: Double
    let reduced: Bool
    var scale: CGFloat
    var offset: CGSize
    var mapBlend: CGFloat

    private static let bigSize: CGFloat = 32
    private static let labelSize: CGFloat = 9.5

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(scale, mapBlend), AnimatablePair(offset.width, offset.height)) }
        set {
            scale = newValue.first.first
            mapBlend = newValue.first.second
            offset = CGSize(width: newValue.second.first, height: newValue.second.second)
        }
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
    }

    // MARK: Zeichnen

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let stars = layout.stars
        drawDust(in: &context, size: size)
        guard !stars.isEmpty, stars.count == words.count else { return }
        // Nur ein Hauch Songfarbe im Leuchten; Sterne und Linien bleiben weiß.
        let glow = Color(hue: layout.signature.hue, saturation: 0.12, brightness: 1)
        let accent = Color(hue: layout.signature.accentHue, saturation: 0.35, brightness: 1)
        let fold = CGFloat(elapsed.map { ConstellationVoiceLayout.foldProgress(elapsed: $0) } ?? 0)
        let blend = min(1, max(mapBlend, fold))
        let map = blend > 0.001 ? ConstellationVoiceLayout.mapPoints(layout: layout, size: size) : []
        let points: [CGPoint] = stars.indices.map { index in
            let star = stars[index].point
            let journey = CGPoint(x: star.x * scale + offset.width, y: star.y * scale + offset.height)
            guard map.count == stars.count else { return journey }
            return CGPoint(x: journey.x + (map[index].x - journey.x) * blend,
                           y: journey.y + (map[index].y - journey.y) * blend)
        }
        let current = min(head.index, stars.count - 1)
        let bolt = elapsed.map { ConstellationVoiceLayout.boltProgress(elapsed: $0) }
        let mapMode = elapsed != nil || blend > 0.5
        if mapMode {
            let travel = bolt.map { $0 * Double(stars.count - 1) } ?? Double(current)
            drawMap(in: &context, size: size, points: points, current: current, travel: travel)
            if let elapsed, let bolt, !reduced {
                drawBolt(in: &context, points: points, progress: bolt, elapsed: elapsed, accent: accent)
                let flash = ConstellationVoiceLayout.flash(elapsed: elapsed) * 0.2 + (bolt > 0 && bolt < 1 ? 0.04 : 0)
                if flash > 0 {
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash)))
                }
            }
        } else {
            drawJourney(in: &context, size: size, points: points, current: current, glow: glow)
        }
    }

    /// Kaum sichtbarer Sternstaub wie im Original; bewegt sich langsamer als die Route.
    private func drawDust(in context: inout GraphicsContext, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        for index in 0..<80 {
            let key = UInt64(index) &* 0x9E37_79B9 &+ 17
            var x: CGFloat = CGFloat(ConstellationGeometry.unit(key)) * size.width + offset.width * 0.1
            x = x.truncatingRemainder(dividingBy: size.width)
            if x < 0 { x += size.width }
            var y: CGFloat = CGFloat(ConstellationGeometry.unit(key &+ 1)) * size.height + offset.height * 0.1
            y = y.truncatingRemainder(dividingBy: size.height)
            if y < 0 { y += size.height }
            let alpha: Double = 0.03 + ConstellationGeometry.unit(key &+ 2) * 0.09
            let radius: CGFloat = 0.3 + CGFloat(ConstellationGeometry.unit(key &+ 3)) * 0.5
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                         with: .color(.white.opacity(alpha)))
        }
    }

    // MARK: Live und Verlauf

    private func drawJourney(in context: inout GraphicsContext, size: CGSize, points: [CGPoint],
                             current: Int, glow: Color) {
        let viewport = CGRect(origin: .zero, size: size).insetBy(dx: -60, dy: -60)
        let currentLine = words[current].line
        let selectedLine = historyIndex.flatMap { words.indices.contains($0) ? words[$0].line : nil }
        let live = historyIndex == nil
        // Linien nur innerhalb einer Zeile, wie im Original.
        for index in 1...max(1, current) where index <= current && words[index].line == words[index - 1].line {
            let from = points[index - 1]
            var to = points[index]
            guard viewport.contains(from) || viewport.contains(to) else { continue }
            let alpha = lineAlpha(words[index].line, current: currentLine, selected: selectedLine, live: live)
            if live, index == current {
                let progress = CGFloat(head.draw)
                to = CGPoint(x: from.x + (to.x - from.x) * progress, y: from.y + (to.y - from.y) * progress)
            }
            var segment = Path()
            segment.move(to: from)
            segment.addLine(to: to)
            context.stroke(segment, with: .color(.white.opacity(alpha * 0.85)), lineWidth: 0.7)
        }
        for index in 0...current where viewport.contains(points[index]) {
            let point = points[index]
            let alpha = lineAlpha(words[index].line, current: currentLine, selected: selectedLine, live: live)
            let star = layout.stars[index]
            if live, index == current { continue }
            if star.onBeat, words[index].line == currentLine || !live {
                // Wörter auf dem Beat funkeln leicht: Der Rhythmus wird sichtbar.
                sparkle(in: &context, at: point, size: 4 + CGFloat(star.energy) * 2, alpha: alpha)
            } else {
                let radius = 1.3 + CGFloat(star.energy) * 1.1
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(.white.opacity(alpha)))
            }
        }
        // Kleine Beschriftungen unter den Sternen.
        var previous = CGRect.null
        for index in 0...current where viewport.contains(points[index]) {
            if live, index == current { continue }
            if live, index == current - 1, head.appear < 1 { continue }
            let chosen = selectedLine == words[index].line
            let alpha = lineAlpha(words[index].line, current: currentLine, selected: selectedLine, live: live)
            let emphasis: Double = chosen ? 1 : 0.7
            let labelAlpha: Double = min(0.95, alpha * emphasis)
            let fontSize: CGFloat = chosen ? 11 : Self.labelSize
            let weight: Font.Weight = chosen ? .semibold : .medium
            let label = context.resolve(Text(words[index].text)
                .font(.system(size: fontSize, weight: weight))
                .foregroundStyle(.white.opacity(labelAlpha)))
            let measured = label.measure(in: CGSize(width: 160, height: 30))
            let rect = CGRect(x: points[index].x + 3, y: points[index].y + 5, width: measured.width, height: measured.height)
            guard chosen || words[index].line == currentLine || !rect.intersects(previous) else { continue }
            context.draw(label, in: rect)
            previous = rect
        }
        if let historyIndex, points.indices.contains(historyIndex) {
            let point = points[historyIndex]
            context.stroke(Path(ellipseIn: CGRect(x: point.x - 9, y: point.y - 9, width: 18, height: 18)),
                           with: .color(.white.opacity(0.8)), lineWidth: 0.8)
        }
        guard live else { return }
        drawCurrentWord(in: &context, size: size, points: points, current: current, glow: glow)
    }

    private func lineAlpha(_ line: Int, current: Int, selected: Int?, live: Bool) -> Double {
        if let selected { return line == selected ? 0.95 : 0.4 }
        if line == current || !live { return 0.85 }
        let age = Double(max(0, current - line - 1))
        return max(0.08, 0.3 - age * 0.08)
    }

    /// Das gesungene Wort groß mit weichem Leuchten über einem Funkelstern; das
    /// vorige Wort schrumpft gleichzeitig in seine kleine Beschriftung.
    private func drawCurrentWord(in context: inout GraphicsContext, size: CGSize, points: [CGPoint],
                                 current: Int, glow: Color) {
        let appear = head.appear * head.appear * (3 - 2 * head.appear)
        let point = points[current]
        let word = words[current]
        let fontSize: CGFloat = word.text.count > 18 ? 24 : Self.bigSize
        let big = context.resolve(Text(word.text).font(.system(size: fontSize, design: .serif)).foregroundStyle(.white))
        let measured = big.measure(in: CGSize(width: size.width - 40, height: 90))
        let half: CGFloat = measured.width / 2
        let preferred: CGFloat = point.x - measured.width * 0.12
        let centreX: CGFloat = min(size.width - 20 - half, max(20 + half, preferred))
        let rise = CGFloat(8 * (1 - appear))
        let textRect = CGRect(x: centreX - measured.width / 2, y: point.y - 10 - measured.height + rise,
                              width: measured.width, height: measured.height)
        let halo = CGPoint(x: (textRect.midX + point.x) / 2, y: (textRect.midY + point.y) / 2)
        let haloRadius = min(120, max(70, measured.width * 0.75)) + CGFloat(pulse) * 10
        context.fill(Path(ellipseIn: CGRect(x: halo.x - haloRadius, y: halo.y - haloRadius,
                                            width: haloRadius * 2, height: haloRadius * 2)),
                     with: .radialGradient(Gradient(colors: [glow.opacity((0.13 + pulse * 0.06) * appear), .clear]),
                                           center: halo, startRadius: 0, endRadius: haloRadius))
        if current > 0, appear < 1 {
            drawShrinkingWord(in: &context, points: points, index: current - 1, progress: appear,
                              currentLine: word.line)
        }
        let energy = CGFloat(layout.stars[current].energy)
        let beat = CGFloat(pulse) * 5
        let starSize: CGFloat = (9 + 6 * energy + beat) * CGFloat(appear)
        sparkle(in: &context, at: point, size: starSize, alpha: 1)
        context.drawLayer { layer in
            layer.opacity = appear
            layer.addFilter(.shadow(color: .white.opacity(0.45), radius: 9))
            layer.draw(big, in: textRect)
        }
    }

    private func drawShrinkingWord(in context: inout GraphicsContext, points: [CGPoint], index: Int,
                                   progress: Double, currentLine: Int) {
        let point = points[index]
        let word = words[index]
        let fromSize: CGFloat = word.text.count > 18 ? 24 : Self.bigSize
        let fontSize = fromSize + (Self.labelSize - fromSize) * CGFloat(progress)
        let restAlpha = word.line == currentLine ? 0.6 : 0.25
        let text = context.resolve(Text(word.text).font(.system(size: fontSize, design: .serif))
            .foregroundStyle(.white.opacity(1 + (restAlpha - 1) * progress)))
        let measured = text.measure(in: CGSize(width: 360, height: 90))
        let bigOrigin = CGPoint(x: point.x - measured.width * 0.62, y: point.y - 10 - measured.height)
        let labelOrigin = CGPoint(x: point.x + 3, y: point.y + 5)
        let t = CGFloat(progress)
        let x: CGFloat = bigOrigin.x + (labelOrigin.x - bigOrigin.x) * t
        let y: CGFloat = bigOrigin.y + (labelOrigin.y - bigOrigin.y) * t
        context.draw(text, in: CGRect(x: x, y: y, width: measured.width, height: measured.height))
    }

    /// Vierstrahliger Funkelstern; der senkrechte Strahl ist länger.
    private func sparkle(in context: inout GraphicsContext, at point: CGPoint, size: CGFloat, alpha: Double) {
        guard size > 0.5 else { return }
        let long = size
        let short = size * 0.68
        let width = max(0.5, size * 0.07)
        var rays = Path()
        rays.move(to: CGPoint(x: point.x, y: point.y - long))
        rays.addLine(to: CGPoint(x: point.x + width, y: point.y))
        rays.addLine(to: CGPoint(x: point.x, y: point.y + long))
        rays.addLine(to: CGPoint(x: point.x - width, y: point.y))
        rays.closeSubpath()
        rays.move(to: CGPoint(x: point.x - short, y: point.y))
        rays.addLine(to: CGPoint(x: point.x, y: point.y - width))
        rays.addLine(to: CGPoint(x: point.x + short, y: point.y))
        rays.addLine(to: CGPoint(x: point.x, y: point.y + width))
        rays.closeSubpath()
        context.fill(rays, with: .color(.white.opacity(alpha)))
        let core = max(1.2, size * 0.16)
        context.fill(Path(ellipseIn: CGRect(x: point.x - core, y: point.y - core, width: core * 2, height: core * 2)),
                     with: .color(.white.opacity(alpha)))
        if size > 6 {
            let bloom = size * 1.1
            context.fill(Path(ellipseIn: CGRect(x: point.x - bloom, y: point.y - bloom, width: bloom * 2, height: bloom * 2)),
                         with: .radialGradient(Gradient(colors: [.white.opacity(0.35 * alpha), .clear]),
                                               center: point, startRadius: 0, endRadius: bloom))
        }
    }

    // MARK: Karte und Schlussblitz

    private func drawMap(in context: inout GraphicsContext, size: CGSize, points: [CGPoint], current: Int, travel: Double) {
        let afterglow = elapsed.map { $0 > ConstellationVoiceLayout.boltDelay + ConstellationVoiceLayout.boltDuration } ?? false
        var segments = Path()
        var lit = Path()
        for index in 1..<max(1, points.count) where words[index].line == words[index - 1].line {
            if Double(index) <= travel {
                lit.move(to: points[index - 1])
                lit.addLine(to: points[index])
            } else {
                segments.move(to: points[index - 1])
                segments.addLine(to: points[index])
            }
        }
        context.stroke(segments, with: .color(.white.opacity(0.12)), lineWidth: 0.6)
        context.stroke(lit, with: .color(.white.opacity(0.5 + pulse * 0.25)), lineWidth: 0.7)
        for index in points.indices {
            let point = points[index]
            let star = layout.stars[index]
            let isLit = Double(index) <= travel
            var alpha = isLit ? 0.85 : 0.2
            if afterglow, !reduced, let elapsed {
                alpha = 0.65 + 0.35 * sin(elapsed * 2.4 + Double(index) * 1.3)
            }
            if let elapsed, isLit, !reduced, !afterglow, elapsed > ConstellationVoiceLayout.boltDelay {
                // Der Blitz streift den Stern: kurzes, abklingendes Aufleuchten.
                let flare = exp(-(travel - Double(index)) / 5)
                sparkle(in: &context, at: point, size: CGFloat(3 + 8 * flare), alpha: min(1, alpha + flare * 0.3))
                continue
            }
            let radius = 0.9 + CGFloat(star.energy) * 0.9
            context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                         with: .color(.white.opacity(alpha)))
        }
        var drawn: [CGRect] = []
        for index in points.indices where layout.stars[index].lineStart {
            let label = context.resolve(Text(words[index].text).font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(Double(index) <= travel ? 0.5 : 0.22)))
            let measured = label.measure(in: CGSize(width: 90, height: 20))
            let rect = CGRect(x: points[index].x + 3, y: points[index].y + 4, width: measured.width, height: measured.height)
            guard !drawn.suffix(6).contains(where: { $0.intersects(rect) }) else { continue }
            context.draw(label, in: rect)
            drawn.append(rect)
        }
        if afterglow || elapsed == nil, points.indices.contains(current) {
            sparkle(in: &context, at: points[current], size: 9 + CGFloat(pulse) * 4, alpha: 1)
        }
    }

    /// Gezackter Blitz mit Verästelungen; die Zacken flackern mit 40 Hz.
    private func drawBolt(in context: inout GraphicsContext, points: [CGPoint], progress: Double,
                          elapsed: Double, accent: Color) {
        guard progress > 0, progress < 1, points.count > 1 else { return }
        let travel = progress * Double(points.count - 1)
        let end = min(points.count - 2, Int(travel))
        let fraction = CGFloat(travel - Double(end))
        let tip = CGPoint(x: points[end].x + (points[end + 1].x - points[end].x) * fraction,
                          y: points[end].y + (points[end + 1].y - points[end].y) * fraction)
        let bucket = UInt64(max(0, elapsed * 40))
        let first = max(0, end - 14)
        var anchors = Array(points[first...end])
        anchors.append(tip)
        var bolt = Path()
        var branches = Path()
        bolt.move(to: anchors[0])
        for index in 1..<anchors.count {
            let from = anchors[index - 1]
            let to = anchors[index]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let length = max(1, hypot(dx, dy))
            let normal = CGPoint(x: -dy / length, y: dx / length)
            let amplitude = min(9, length * 0.25)
            for step in 1...3 {
                let t = CGFloat(step) / 3
                let key = bucket &* 977 &+ UInt64(first + index) &* 31 &+ UInt64(step)
                let jitter = step == 3 ? 0 : (CGFloat(ConstellationGeometry.unit(key)) - 0.5) * 2 * amplitude
                bolt.addLine(to: CGPoint(x: from.x + dx * t + normal.x * jitter, y: from.y + dy * t + normal.y * jitter))
            }
            if (first + index) % 4 == 0 {
                let key = bucket &+ UInt64(first + index) &* 7919
                let angle = ConstellationGeometry.unit(key) * 2 * Double.pi
                let reach = 14 + 16 * CGFloat(ConstellationGeometry.unit(key &+ 1))
                let middle = CGPoint(x: to.x + CGFloat(cos(angle)) * reach * 0.5 + normal.x * 4,
                                     y: to.y + CGFloat(sin(angle)) * reach * 0.5 + normal.y * 4)
                branches.move(to: to)
                branches.addLine(to: middle)
                branches.addLine(to: CGPoint(x: to.x + CGFloat(cos(angle)) * reach, y: to.y + CGFloat(sin(angle)) * reach))
            }
        }
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.stroke(bolt, with: .color(accent.opacity(0.7)), lineWidth: 8)
        }
        context.stroke(branches, with: .color(.white.opacity(0.55)), lineWidth: 0.8)
        context.stroke(bolt, with: .color(accent.opacity(0.85)), lineWidth: 2.6)
        context.stroke(bolt, with: .color(.white), lineWidth: 1.2)
        context.fill(Path(ellipseIn: CGRect(x: tip.x - 26, y: tip.y - 26, width: 52, height: 52)),
                     with: .radialGradient(Gradient(colors: [.white.opacity(0.9), accent.opacity(0.3), .clear]),
                                           center: tip, startRadius: 0, endRadius: 26))
    }
}
