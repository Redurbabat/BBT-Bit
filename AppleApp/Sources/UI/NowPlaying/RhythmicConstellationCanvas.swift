import SwiftUI

/// Sternbild als Reise: Jedes gesungene Wort wird ein Stern. Der Abstand folgt
/// dem Rhythmus, die Höhe der Stimme, Größe und Glanz dem Pegel. Links liegt
/// der Verlauf; in den letzten zehn Sekunden faltet sich die Route zur Karte und
/// ein Blitz läuft in gut einer Sekunde durch alle Sterne.
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
        let head = ConstellationVoiceLayout.head(layout: layout, words: words, milliseconds: positionMs)
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
        return ConstellationScene(words: words, layout: layout, head: head, positionMs: positionMs,
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
    let positionMs: Int64
    let historyIndex: Int?
    let elapsed: Double?
    let pulse: Double
    let reduced: Bool
    var scale: CGFloat
    var offset: CGSize
    var mapBlend: CGFloat

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
        guard !stars.isEmpty, stars.count == words.count else { return }
        let signature = layout.signature
        let tint = Color(hue: signature.hue, saturation: 0.6, brightness: 1)
        let soft = Color(hue: signature.hue, saturation: 0.22, brightness: 1)
        let accent = Color(hue: signature.accentHue, saturation: 0.7, brightness: 1)
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
        var headPoint = CGPoint(x: head.point.x * scale + offset.width, y: head.point.y * scale + offset.height)
        if map.count == stars.count {
            headPoint = CGPoint(x: headPoint.x + (map[current].x - headPoint.x) * blend,
                                y: headPoint.y + (map[current].y - headPoint.y) * blend)
        }
        let bolt = elapsed.map { ConstellationVoiceLayout.boltProgress(elapsed: $0) }
        // Bis wohin die Route leuchtet: live bis zum Kopf, im Schluss bis zum Blitz.
        let travel = bolt.map { $0 * Double(stars.count - 1) } ?? Double(current)
        let showsAll = elapsed != nil || blend > 0.5
        let lastShown = showsAll ? stars.count - 1 : current

        drawSky(in: &context, size: size, tint: tint, centre: showsAll ? CGPoint(x: size.width / 2, y: size.height / 2) : headPoint)
        drawRoute(in: &context, points: points, lastShown: lastShown, travel: travel,
                  head: elapsed == nil && blend < 0.5 ? headPoint : nil, tint: tint, soft: soft,
                  flow: signature.flow, live: elapsed == nil)
        drawStars(in: &context, size: size, points: points, lastShown: lastShown, travel: travel,
                  current: current, tint: tint, soft: soft, signature: signature)
        if let elapsed, let bolt, !reduced {
            drawBolt(in: &context, points: points, progress: bolt, elapsed: elapsed, accent: accent)
            let flash = ConstellationVoiceLayout.flash(elapsed: elapsed) * 0.22 + (bolt > 0 && bolt < 1 ? 0.05 : 0)
            if flash > 0 {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash)))
            }
        }
        if blend > 0.5 || elapsed != nil {
            drawMapLabels(in: &context, points: points, current: current, travel: travel)
        } else if let historyIndex {
            drawHistoryLabels(in: &context, size: size, points: points, current: current, selected: historyIndex)
        } else {
            drawLiveLabels(in: &context, size: size, points: points, current: current, headPoint: headPoint, tint: tint)
        }
    }

    /// Nebel in Songfarbe und ein Sternfeld, das sich langsamer als die Route bewegt.
    private func drawSky(in context: inout GraphicsContext, size: CGSize, tint: Color, centre: CGPoint) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
            Gradient(colors: [tint.opacity(0.16 + pulse * 0.08), tint.opacity(0.04), .clear]),
            center: centre, startRadius: 0, endRadius: max(size.width, size.height) * 0.75))
        guard size.width > 0, size.height > 0 else { return }
        let seed = UInt64(layout.signature.hue * 10_000)
        for index in 0..<70 {
            let key = seed &+ UInt64(index) &* 0x9E37_79B9
            var x: CGFloat = CGFloat(ConstellationGeometry.unit(key)) * size.width + offset.width * 0.12
            x = x.truncatingRemainder(dividingBy: size.width)
            if x < 0 { x += size.width }
            var y: CGFloat = CGFloat(ConstellationGeometry.unit(key &+ 1)) * size.height + offset.height * 0.08
            y = y.truncatingRemainder(dividingBy: size.height)
            if y < 0 { y += size.height }
            let glow: Double = 0.06 + ConstellationGeometry.unit(key &+ 2) * 0.22
            let radius: CGFloat = 0.4 + CGFloat(ConstellationGeometry.unit(key &+ 3)) * 0.8
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                         with: .color(.white.opacity(glow)))
        }
    }

    private func drawRoute(in context: inout GraphicsContext, points: [CGPoint], lastShown: Int, travel: Double,
                           head: CGPoint?, tint: Color, soft: Color, flow: Double, live: Bool) {
        let tension = CGFloat(0.08 + 0.12 * flow)
        if lastShown > 0 {
            context.stroke(smoothPath(Array(points[0...lastShown]), tension: tension),
                           with: .color(soft.opacity(live ? 0.10 : 0.16)), lineWidth: 0.7)
        }
        let end = min(lastShown, max(0, Int(travel)))
        var lit = Array(points[0...end])
        if let head {
            lit.append(head)
        } else if end + 1 < points.count, travel > Double(end) {
            let fraction = CGFloat(travel - Double(end))
            lit.append(CGPoint(x: points[end].x + (points[end + 1].x - points[end].x) * fraction,
                               y: points[end].y + (points[end + 1].y - points[end].y) * fraction))
        }
        guard lit.count > 1 else { return }
        let route = smoothPath(lit, tension: tension)
        context.stroke(route, with: .color(tint.opacity(0.14 + pulse * 0.10)), lineWidth: 5)
        context.stroke(route, with: .color(tint.opacity(0.55 + pulse * 0.25)), lineWidth: 1.1)
        // Die jüngsten Schritte leuchten heller: der Verlauf klingt nach links aus.
        if live, lit.count > 2 {
            let recent = Array(lit.suffix(7))
            context.stroke(smoothPath(recent, tension: tension), with: .color(.white.opacity(0.65)), lineWidth: 1.3)
        }
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize, points: [CGPoint], lastShown: Int,
                           travel: Double, current: Int, tint: Color, soft: Color, signature: ConstellationSignature) {
        let viewport = CGRect(origin: .zero, size: size).insetBy(dx: -40, dy: -40)
        let afterglow = elapsed.map { $0 > ConstellationVoiceLayout.boltDelay + ConstellationVoiceLayout.boltDuration } ?? false
        for index in 0...lastShown where viewport.contains(points[index]) {
            let star = layout.stars[index]
            let point = points[index]
            let lit = Double(index) <= travel
            var radius = CGFloat(1.2 + star.energy * (1.4 + 2.6 * signature.dynamics))
            var alpha: Double
            if elapsed != nil {
                alpha = lit ? 0.85 : 0.18
                if afterglow, !reduced, let elapsed {
                    alpha = 0.7 + 0.3 * sin(elapsed * 2.4 + Double(index) * 1.3)
                }
            } else if lit {
                alpha = historyIndex == nil ? max(0.3, 1 - Double(current - index) / 40) : 0.85
            } else {
                alpha = 0.18
            }
            if index == current, elapsed == nil { radius += CGFloat(pulse) * 2 }
            if lit, star.onBeat {
                let ring = radius + 3 + CGFloat(pulse) * 2
                context.stroke(Path(ellipseIn: CGRect(x: point.x - ring, y: point.y - ring, width: ring * 2, height: ring * 2)),
                               with: .color(tint.opacity(0.28 * alpha)), lineWidth: 0.6)
            }
            if let elapsed, lit, !reduced, elapsed <= ConstellationVoiceLayout.boltDelay + ConstellationVoiceLayout.boltDuration + 0.4 {
                // Blitz streift den Stern: kurzes, abklingendes Aufleuchten.
                let flare = CGFloat(exp(-(travel - Double(index)) / 5))
                let glow = 6 + 14 * flare
                context.fill(Path(ellipseIn: CGRect(x: point.x - glow, y: point.y - glow, width: glow * 2, height: glow * 2)),
                             with: .radialGradient(Gradient(colors: [.white.opacity(0.7 * Double(flare)), .clear]),
                                                   center: point, startRadius: 0, endRadius: glow))
            }
            context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                         with: .color((lit ? soft : Color.white).opacity(alpha)))
        }
        if elapsed == nil, historyIndex == nil, points.indices.contains(current) {
            let point = points[current]
            let glow = CGFloat(18 + pulse * 16 + layout.stars[current].energy * 10)
            context.fill(Path(ellipseIn: CGRect(x: point.x - glow, y: point.y - glow, width: glow * 2, height: glow * 2)),
                         with: .radialGradient(Gradient(colors: [tint.opacity(0.35 + pulse * 0.3), .clear]),
                                               center: point, startRadius: 0, endRadius: glow))
        }
        if afterglow, points.indices.contains(current) {
            let point = points[current]
            context.stroke(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)),
                           with: .color(.white.opacity(0.8)), lineWidth: 1)
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
            layer.stroke(bolt, with: .color(accent.opacity(0.75)), lineWidth: 8)
        }
        context.stroke(branches, with: .color(.white.opacity(0.55)), lineWidth: 0.8)
        context.stroke(bolt, with: .color(accent.opacity(0.9)), lineWidth: 3)
        context.stroke(bolt, with: .color(.white), lineWidth: 1.4)
        context.fill(Path(ellipseIn: CGRect(x: tip.x - 26, y: tip.y - 26, width: 52, height: 52)),
                     with: .radialGradient(Gradient(colors: [.white.opacity(0.9), accent.opacity(0.35), .clear]),
                                           center: tip, startRadius: 0, endRadius: 26))
    }

    // MARK: Beschriftung

    /// Live: das aktuelle Wort groß, die letzten Wörter als ausklingender Verlauf.
    private func drawLiveLabels(in context: inout GraphicsContext, size: CGSize, points: [CGPoint],
                                current: Int, headPoint: CGPoint, tint: Color) {
        var previous = CGRect.null
        for index in max(0, current - 10)..<current {
            let age = Double(current - index)
            let point = points[index]
            let above = index > 0 && point.y < points[index - 1].y
            let label = context.resolve(Text(words[index].text).font(.system(size: 11, design: .serif))
                .foregroundStyle(.white.opacity(0.55 * (1 - age / 11))))
            let measured = label.measure(in: CGSize(width: 160, height: 30))
            let anchor = CGPoint(x: point.x, y: above ? point.y - 9 : point.y + 9)
            let rect = CGRect(x: anchor.x - measured.width / 2, y: above ? anchor.y - measured.height : anchor.y,
                              width: measured.width, height: measured.height)
            guard !rect.intersects(previous) else { continue }
            context.draw(label, in: rect)
            previous = rect
        }
        guard words.indices.contains(current) else { return }
        let word = words[current]
        let appear = ConstellationVoiceLayout.clamp(Double(positionMs - word.start) / 180)
        let eased = appear * appear * (3 - 2 * appear)
        let fontSize: CGFloat = word.text.count > 22 ? 22 : 30
        var label = context.resolve(Text(word.text).font(.system(size: fontSize, design: .serif)).foregroundStyle(.white))
        let measured = label.measure(in: CGSize(width: size.width - 40, height: 80))
        let point = points[current]
        let x = min(size.width - 20 - measured.width / 2, max(20 + measured.width / 2, point.x))
        let lift = CGFloat(10 * (1 - eased))
        label.shading = .color(.white.opacity(0.35 + 0.65 * eased))
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: tint.opacity(0.9), radius: 12))
            layer.draw(label, in: CGRect(x: x - measured.width / 2, y: point.y - 26 - measured.height + lift,
                                        width: measured.width, height: measured.height))
        }
        context.fill(Path(ellipseIn: CGRect(x: headPoint.x - 2.5, y: headPoint.y - 2.5, width: 5, height: 5)),
                     with: .color(.white))
    }

    /// Verlauf: alle bisher gesungenen Wörter; die gewählte Zeile tritt hervor.
    private func drawHistoryLabels(in context: inout GraphicsContext, size: CGSize, points: [CGPoint],
                                   current: Int, selected: Int) {
        let line = words.indices.contains(selected) ? words[selected].line : -1
        let viewport = CGRect(origin: .zero, size: size).insetBy(dx: -30, dy: 0)
        var previous = CGRect.null
        for index in 0...current where viewport.contains(points[index]) {
            let chosen = words[index].line == line
            let label = context.resolve(Text(words[index].text)
                .font(.system(size: chosen ? 13 : 10, weight: chosen ? .semibold : .regular, design: .serif))
                .foregroundStyle(.white.opacity(chosen ? 0.95 : 0.42)))
            let measured = label.measure(in: CGSize(width: 160, height: 30))
            let rect = CGRect(x: points[index].x - measured.width / 2, y: points[index].y + 7,
                              width: measured.width, height: measured.height)
            guard chosen || !rect.intersects(previous) else { continue }
            context.draw(label, in: rect)
            previous = rect
        }
        if points.indices.contains(selected) {
            let point = points[selected]
            context.stroke(Path(ellipseIn: CGRect(x: point.x - 9, y: point.y - 9, width: 18, height: 18)),
                           with: .color(.white.opacity(0.8)), lineWidth: 1)
        }
    }

    /// Karte: Zeilenanfänge als ruhige Beschriftung ohne Überlappung.
    private func drawMapLabels(in context: inout GraphicsContext, points: [CGPoint], current: Int, travel: Double) {
        var drawn: [CGRect] = []
        for index in points.indices where layout.stars[index].lineStart {
            let lit = Double(index) <= travel
            let label = context.resolve(Text(words[index].text).font(.system(size: 10, design: .serif))
                .foregroundStyle(.white.opacity(lit ? 0.5 : 0.25)))
            let measured = label.measure(in: CGSize(width: 90, height: 20))
            let rect = CGRect(x: points[index].x - measured.width / 2, y: points[index].y + 5,
                              width: measured.width, height: measured.height)
            guard !drawn.suffix(6).contains(where: { $0.intersects(rect) }) else { continue }
            context.draw(label, in: rect)
            drawn.append(rect)
        }
    }

    /// Weiche Catmull-Rom-Kurve; ruhige Songs bekommen weitere Bögen.
    private func smoothPath(_ points: [CGPoint], tension: CGFloat) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        for index in 0..<(points.count - 1) {
            let p0 = points[max(0, index - 1)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(points.count - 1, index + 2)]
            path.addCurve(to: p2,
                          control1: CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension),
                          control2: CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension))
        }
        return path
    }
}
