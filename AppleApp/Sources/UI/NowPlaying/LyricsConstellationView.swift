import SwiftUI
import BitChordShared

/// Zusätzliche Lyrics-Darstellung; Zeitbasis, Versatz und Daten bleiben mit der Liste geteilt.
struct LyricsConstellationView: View {
    let lines: [LyricLineDto]
    let position: Double
    var offsetMs: Int32 = 0
    var onClose: () -> Void = {}
    var immersive = false
    var trackTitle = ""
    var sourceLabel: String? = nil
    var onShowList: (() -> Void)? = nil

    static func isAvailable(lines: [LyricLineDto]) -> Bool {
        !lines.isEmpty && LyricFocus.shared.isSynced(lines: lines)
    }

    private var adjustedMs: Swift.Int64 {
        ConstellationGeometry.milliseconds(position: position, offset: offsetMs)
    }

    private var leadIndex: Int? {
        guard !lines.isEmpty else { return nil }
        let lead = LyricFocus.shared.leadRow(lines: lines, positionMs: adjustedMs)
        return lead < 0 ? 0 : min(Int(lead), lines.count - 1)
    }

    var body: some View {
        ConstellationStage(
            words: leadIndex.map(starWords(for:)) ?? [],
            lineText: leadIndex.map { lines[$0].text } ?? "",
            positionMs: adjustedMs,
            lineStart: leadIndex.map { min(Swift.Int64.max / 2, max(0, lines[$0].timeMs)) } ?? 0,
            immersive: immersive,
            trackTitle: trackTitle,
            sourceLabel: sourceLabel,
            onClose: onClose,
            onShowList: onShowList
        )
    }

    /// Echte Wortzeiten haben Vorrang. Zeilenzeiten bleiben eine gleichmäßig verteilte Annäherung.
    private func starWords(for index: Int) -> [ConstellationWord] {
        let line = lines[index]
        let timed = line.words.filter {
            !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && ($0.startMs > 0 || $0.endMs > 0)
        }
        if !timed.isEmpty {
            return timed.map {
                ConstellationWord(text: $0.text.trimmingCharacters(in: .whitespaces),
                                  start: max(0, $0.startMs), end: max(0, max($0.startMs, $0.endMs)))
            }
        }
        let parts = line.text.split(separator: " ").map(String.init).filter { $0 != "♪" }
        guard !parts.isEmpty else { return [] }
        let start = min(Swift.Int64.max / 2, max(0, line.timeMs))
        let next = index + 1 < lines.count ? lines[index + 1].timeMs : start + 4000
        let span = max(max(0, next) - start, Swift.Int64(parts.count) * 250)
        let step = span / Swift.Int64(parts.count)
        return parts.enumerated().map { index, text in
            let begin = start + step * Swift.Int64(index)
            return ConstellationWord(text: text, start: begin, end: begin + step)
        }
    }
}

/// Dieselbe native Zeichenfläche wird in der echten Ansicht und im gekennzeichneten UI-Fixture verwendet.
struct ConstellationStage: View {
    let words: [ConstellationWord]
    let lineText: String
    let positionMs: Swift.Int64
    let lineStart: Swift.Int64
    var immersive = false
    var trackTitle = ""
    var sourceLabel: String? = nil
    var onClose: () -> Void = {}
    var onShowList: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.opacity(immersive ? 1 : 0.65)
            Canvas { context, size in draw(&context, size: size) }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                Text(lineText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("bbt.lyrics.constellation.line")
                if let sourceLabel, !sourceLabel.isEmpty {
                    Text("Lyrics source: \(sourceLabel)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, immersive ? 58 : 20)
        }
        .overlay(alignment: .top) { header }
        .clipShape(RoundedRectangle(cornerRadius: immersive ? 0 : 22, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                guard immersive, value.translation.height > 100,
                      value.translation.height > abs(value.translation.width) * 1.3 else { return }
                onClose()
            }
        )
        .accessibilityIdentifier("bbt.lyrics.constellation")
    }

    private var header: some View {
        VStack(spacing: 8) {
            Button(action: onClose) {
                Capsule().fill(.white.opacity(0.35)).frame(width: 36, height: 4)
                    .frame(width: 60, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to player")
            .accessibilityIdentifier("bbt.lyrics.constellation.close")
            HStack {
                Text(trackTitle.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(action: onShowList ?? onClose) {
                    Label("List", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show lyrics list")
                .accessibilityIdentifier("bbt.lyrics.constellation.list")
            }
            .padding(.horizontal, 22)
        }
        .padding(.top, immersive ? 44 : 0)
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize) {
        for index in 0..<48 {
            let x = ConstellationGeometry.unit(UInt64(index) * 2 + 11) * size.width
            let y = ConstellationGeometry.unit(UInt64(index) * 2 + 12) * size.height
            let alpha = 0.035 + 0.12 * ConstellationGeometry.unit(UInt64(index) + 500)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(alpha)))
        }
        guard let current = words.indices.last(where: { words[$0].start <= positionMs }) else { return }
        let points = words.indices.map {
            ConstellationGeometry.point(index: $0, count: words.count, seed: lineStart, size: size, reduced: reduceMotion)
        }
        let nextStart = current + 1 < words.count ? words[current + 1].start : words[current].end
        // Die Kamera erreicht auch bei kurzen Silben ihr Ziel vor dem nächsten Wort.
        let cameraDuration = min(260, max(1, nextStart - words[current].start))
        let camera = ConstellationGeometry.camera(points: points, current: current,
            elapsed: positionMs - words[current].start, size: size, reduced: reduceMotion,
            duration: cameraDuration)
        let visible = points.map { CGPoint(x: $0.x + camera.width, y: $0.y + camera.height) }
        let fade = reduceMotion ? 1 : min(1, max(0, Double(positionMs - lineStart) / 260))
        var path = Path()
        path.move(to: visible[0])
        if current > 0 {
            for index in 1...current { path.addLine(to: visible[index]) }
        }
        context.stroke(path, with: .color(.white.opacity(0.36 * fade)), lineWidth: 0.8)
        for index in 0..<current {
            let point = visible[index]
            spark(&context, point: point, scale: 0.23, alpha: 0.5 * fade)
            context.draw(Text(words[index].text).font(.system(size: 11, design: .serif))
                .foregroundStyle(.white.opacity(0.34 * fade)),
                at: CGPoint(x: point.x, y: point.y + 14))
        }
        let point = visible[current]
        let appear = reduceMotion ? 1 : min(1, max(0, Double(positionMs - words[current].start) / 180))
        let glow = CGRect(x: point.x - 40, y: point.y - 40, width: 80, height: 80)
        context.fill(Path(ellipseIn: glow), with: .radialGradient(
            Gradient(colors: [.white.opacity(0.24 * appear), .clear]), center: point, startRadius: 0, endRadius: 40))
        spark(&context, point: point, scale: 0.6 + 0.4 * appear, alpha: appear * fade)
        context.draw(Text(words[current].text)
            .font(.system(size: 30 * (0.9 + 0.1 * appear), design: .serif))
            .foregroundStyle(.white.opacity(appear * fade)),
            at: CGPoint(x: point.x, y: point.y - 28))
    }

    private func spark(_ context: inout GraphicsContext, point: CGPoint, scale: Double, alpha: Double) {
        for horizontal in [false, true] {
            let long = 10 * scale
            let short = 1.2 * scale
            let dx = horizontal ? long : short
            let dy = horizontal ? short : long
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y - dy))
            path.addLine(to: CGPoint(x: point.x + dx, y: point.y))
            path.addLine(to: CGPoint(x: point.x, y: point.y + dy))
            path.addLine(to: CGPoint(x: point.x - dx, y: point.y))
            path.closeSubpath()
            context.fill(path, with: .color(.white.opacity(alpha)))
        }
    }
}
