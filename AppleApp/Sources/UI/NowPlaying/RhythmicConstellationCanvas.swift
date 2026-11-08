import SwiftUI

/// Eine durchgängige Songroute aus den tatsächlichen Zeitmarken. Die Übersicht
/// und die Nahansicht verwenden dieselben Punkte und denselben Verlauf.
struct RhythmicConstellationCanvas: View {
    let words: [ConstellationWord]
    let positionMs: Int64
    let audioPosition: Double
    let duration: Double
    let beats: [Double]
    let historyIndex: Int?
    let overview: Bool
    let finale: Double?
    let reduced: Bool

    var body: some View {
        GeometryReader { proxy in
            layer(size: proxy.size)
                .animation(reduced ? nil : .easeInOut(duration: 0.55), value: overview)
                .animation(reduced ? nil : .spring(response: 0.45, dampingFraction: 0.9), value: historyIndex)
        }
    }

    private func layer(size: CGSize) -> ConstellationMapLayer {
        let span = max(1, ConstellationGeometry.milliseconds(position: duration, offset: 0), words.last?.end ?? 1)
        let points = words.map { ConstellationTimeline.point(word: $0, span: span, size: size) }
        let current = ConstellationTimeline.activeIndex(words: words, milliseconds: positionMs) ?? 0
        let shown = min(max(0, historyIndex ?? current), max(0, words.count - 1))
        let scale: CGFloat = overview || reduced ? 1 : 4
        var target = points.indices.contains(shown) ? points[shown] : CGPoint(x: size.width / 2, y: size.height * 0.47)
        if historyIndex == nil, !overview, !reduced, shown > 0 {
            let limit = shown + 1 < words.count ? words[shown + 1].start - words[shown].start : 260
            let t = min(1, max(0, Double(positionMs - words[shown].start) / Double(max(1, min(260, limit)))))
            let eased = t * t * (3 - 2 * t)
            target = CGPoint(x: points[shown - 1].x + (target.x - points[shown - 1].x) * eased,
                             y: points[shown - 1].y + (target.y - points[shown - 1].y) * eased)
        }
        let offset = overview || reduced ? CGSize.zero : CGSize(width: size.width * 0.62 - target.x * scale,
                                                               height: size.height * 0.47 - target.y * scale)
        let pulse = beats.isEmpty
            ? ConstellationTimeline.pulse(position: Double(positionMs) / 1000, markers: words.map { Double($0.start) / 1000 })
            : ConstellationTimeline.pulse(position: audioPosition, markers: beats)
        return ConstellationMapLayer(words: words, points: points, current: current, shown: shown,
            overview: overview, finale: finale, pulse: pulse, reduced: reduced, scale: scale, offset: offset)
    }
}

/// SwiftUI interpoliert die Kamera unabhängig vom Audio-Tick. Auch bei Pause
/// bleiben das manuelle Zurückblättern und die Übersicht beweglich.
private struct ConstellationMapLayer: View, Animatable {
    let words: [ConstellationWord]
    let points: [CGPoint]
    let current: Int
    let shown: Int
    let overview: Bool
    let finale: Double?
    let pulse: Double
    let reduced: Bool
    var scale: CGFloat
    var offset: CGSize

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(scale, AnimatablePair(offset.width, offset.height)) }
        set { scale = newValue.first; offset = CGSize(width: newValue.second.first, height: newValue.second.second) }
    }

    var body: some View {
        Canvas { context, size in
            let visible = points.map { CGPoint(x: $0.x * scale + offset.width, y: $0.y * scale + offset.height) }
            guard !visible.isEmpty else { return }
            var route = Path()
            route.move(to: visible[0])
            for point in visible.dropFirst() { route.addLine(to: point) }
            if overview { context.stroke(route, with: .color(.white.opacity(0.16)), lineWidth: 0.7) }
            let travel = finale.map { $0 * Double(max(0, visible.count - 1)) } ?? Double(min(current, visible.count - 1))
            let end = min(visible.count - 1, max(0, Int(travel)))
            var lit = Path()
            lit.move(to: visible[0])
            if end > 0 { for index in 1...end { lit.addLine(to: visible[index]) } }
            var head = visible[end]
            if end + 1 < visible.count {
                let fraction = travel - Double(end)
                head = CGPoint(x: head.x + (visible[end + 1].x - head.x) * fraction,
                               y: head.y + (visible[end + 1].y - head.y) * fraction)
                lit.addLine(to: head)
            }
            if finale != nil { context.stroke(lit, with: .color(.red.opacity(0.20 + pulse * 0.20)), lineWidth: 6) }
            context.stroke(lit, with: .color(.white.opacity(0.5 + pulse * 0.35)), lineWidth: finale == nil ? 0.8 : 1.8)
            let viewport = CGRect(origin: .zero, size: size).insetBy(dx: -20, dy: -20)
            var previousLabel: CGRect = .zero
            for index in visible.indices where viewport.contains(visible[index]) {
                guard overview || index <= current else { continue }
                let point = visible[index]
                let radius: CGFloat = index <= end ? 1.8 : 1
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(.white.opacity(index <= end ? 0.8 : 0.20)))
                if overview {
                    let lineStart = index == 0 || words[index - 1].line != words[index].line
                    let rect = CGRect(x: point.x - 36, y: point.y + 5, width: 72, height: 15)
                    if lineStart, !previousLabel.intersects(rect) {
                        context.draw(context.resolve(Text(words[index].text).font(.system(size: 11, design: .serif))
                            .foregroundStyle(.white.opacity(0.5))), in: rect)
                        previousLabel = rect
                    }
                } else if index != shown {
                    context.draw(Text(words[index].text).font(.system(size: 11, design: .serif))
                        .foregroundStyle(.white.opacity(0.35)), at: CGPoint(x: point.x, y: point.y + 13))
                }
            }
            if !overview, visible.indices.contains(shown) {
                let point = visible[shown]
                context.fill(Path(ellipseIn: CGRect(x: point.x - 28, y: point.y - 28, width: 56, height: 56)),
                    with: .radialGradient(Gradient(colors: [.white.opacity(0.10 + pulse * 0.24), .clear]),
                                         center: point, startRadius: 0, endRadius: 28))
                context.draw(context.resolve(Text(words[shown].text)
                    .font(.system(size: words[shown].text.count > 22 ? 22 : 30, design: .serif)).foregroundStyle(.white)),
                    in: CGRect(x: point.x - 110, y: point.y - 76, width: 220, height: 64))
            }
            if finale != nil, !reduced {
                context.fill(Path(ellipseIn: CGRect(x: head.x - 4, y: head.y - 4, width: 8, height: 8)), with: .color(.white))
                context.fill(Path(ellipseIn: CGRect(x: head.x - 17, y: head.y - 17, width: 34, height: 34)),
                    with: .radialGradient(Gradient(colors: [.white.opacity(0.6 + pulse * 0.3), .clear]),
                                         center: head, startRadius: 0, endRadius: 17))
            }
        }
    }
}
