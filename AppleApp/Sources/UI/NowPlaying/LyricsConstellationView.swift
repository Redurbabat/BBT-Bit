import SwiftUI
import BitChordShared

/// Lyrics als Sternbild.
///
/// Jedes Wort der gerade gesungenen Zeile ist ein Stern auf einer Linie. Gesungene
/// Wörter bleiben klein und verbunden, das aktuelle Wort blüht groß auf. Die Ansicht
/// ist ein zusätzlicher Darstellungsmodus: Sie liest dieselben Zeilen, Wortzeiten und
/// denselben Versatz wie `LyricsPane`, ändert weder Lyrics noch Zeitmodell und lässt
/// die Liste unverändert. Zeilen ohne Wortzeiten verteilen ihre Wörter gleichmäßig
/// über die Dauer der Zeile.
struct LyricsConstellationView: View {
    let lines: [LyricLineDto]
    /// Transportposition in Sekunden, wie bei `LyricsPane`.
    let position: Double
    /// Versatz der Lyrics in Millisekunden; positiv zeigt die Lyrics später.
    var offsetMs: Int32 = 0
    var onClose: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Der Modus braucht zeitlich synchronisierte Lyrics; sonst bleibt die Liste.
    static func isAvailable(lines: [LyricLineDto]) -> Bool {
        !lines.isEmpty && LyricFocus.shared.isSynced(lines: lines)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
            Canvas { context, size in
                draw(&context, size: size)
            }
            .accessibilityHidden(true)
            if let text = currentLineText {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    .accessibilityLabel(text)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "text.quote")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(10)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(12)
            .accessibilityLabel("Lyrics")
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: Zeitmodell (wie LyricsPane)

    private var adjustedMs: Swift.Int64 {
        max(0, Swift.Int64(position * 1000) - Swift.Int64(offsetMs))
    }

    private var leadIndex: Int? {
        guard !lines.isEmpty else { return nil }
        let lead = LyricFocus.shared.leadRow(lines: lines, positionMs: adjustedMs)
        return lead < 0 ? 0 : min(Int(lead), lines.count - 1)
    }

    private var currentLineText: String? {
        guard let index = leadIndex else { return nil }
        let text = lines[index].text.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    private struct StarWord {
        let text: String
        let start: Swift.Int64
        let end: Swift.Int64
    }

    /// Wörter der Zeile mit Zeiten. Ohne Wortzeiten gleichmäßig über die Zeilendauer.
    private func starWords(for index: Int) -> [StarWord] {
        let line = lines[index]
        let timed = line.words.filter { word in
            let text = word.text.trimmingCharacters(in: .whitespaces)
            return !text.isEmpty && !text.contains("(") && !text.contains(")")
                && (word.startMs > 0 || word.endMs > 0)
        }
        if !timed.isEmpty {
            return timed.map {
                StarWord(text: $0.text.trimmingCharacters(in: .whitespaces), start: $0.startMs, end: max($0.startMs, $0.endMs))
            }
        }
        let parts = line.text.split(separator: " ").map(String.init).filter { !$0.isEmpty && $0 != "♪" }
        guard !parts.isEmpty else { return [] }
        let start = line.timeMs
        let nextStart: Swift.Int64 = index + 1 < lines.count ? lines[index + 1].timeMs : start + 4000
        let span = max(nextStart - start, Swift.Int64(parts.count) * 250)
        let step = span / Swift.Int64(parts.count)
        return parts.enumerated().map { offset, text in
            let begin = start + step * Swift.Int64(offset)
            return StarWord(text: text, start: begin, end: begin + step)
        }
    }

    // MARK: Zeichnen

    private func draw(_ context: inout GraphicsContext, size: CGSize) {
        drawBackgroundStars(&context, size: size)
        guard let index = leadIndex else { return }
        let words = starWords(for: index)
        guard !words.isEmpty else { return }

        let lineStart = lines[index].timeMs
        let ms = adjustedMs
        let fadeIn = reduceMotion ? 1.0 : min(1.0, max(0.0, Double(ms - lineStart) / 300.0))
        let started = words.indices.filter { ms >= words[$0].start }
        guard let current = started.last else { return }

        let points: [CGPoint] = words.indices.map { point(for: $0, count: words.count, seed: lineStart, size: size) }

        var path = Path()
        path.move(to: points[0])
        if current >= 1 {
            for i in 1...current {
                path.addLine(to: points[i])
            }
        }
        context.stroke(path, with: .color(Color.white.opacity(0.32 * fadeIn)), lineWidth: 1)

        for i in started where i < current {
            let p = points[i]
            let dot = CGRect(x: p.x - 2.2, y: p.y - 2.2, width: 4.4, height: 4.4)
            context.fill(Path(ellipseIn: dot), with: .color(Color.white.opacity(0.6 * fadeIn)))
            context.draw(
                Text(words[i].text)
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.5 * fadeIn)),
                at: CGPoint(x: p.x, y: p.y + 13)
            )
        }

        let p = points[current]
        let appear = reduceMotion ? 1.0 : min(1.0, max(0.0, Double(ms - words[current].start) / 220.0))
        let glow = CGRect(x: p.x - 38, y: p.y - 38, width: 76, height: 76)
        context.fill(
            Path(ellipseIn: glow),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.38 * appear * fadeIn), Color.white.opacity(0)]),
                center: p, startRadius: 0, endRadius: 38
            )
        )
        drawSpark(&context, at: p, scale: 0.6 + 0.4 * appear, alpha: appear * fadeIn)
        context.draw(
            Text(words[current].text)
                .font(.system(size: 30 * (0.86 + 0.14 * appear), weight: .regular, design: .serif))
                .foregroundStyle(Color.white.opacity(appear * fadeIn)),
            at: CGPoint(x: p.x, y: p.y - 28)
        )
    }

    /// Vierzackiger Stern aus zwei schmalen Rauten.
    private func drawSpark(_ context: inout GraphicsContext, at p: CGPoint, scale: Double, alpha: Double) {
        let long = 10.0 * scale
        let short = 1.8 * scale
        var vertical = Path()
        vertical.move(to: CGPoint(x: p.x, y: p.y - long))
        vertical.addLine(to: CGPoint(x: p.x + short, y: p.y))
        vertical.addLine(to: CGPoint(x: p.x, y: p.y + long))
        vertical.addLine(to: CGPoint(x: p.x - short, y: p.y))
        vertical.closeSubpath()
        var horizontal = Path()
        horizontal.move(to: CGPoint(x: p.x - long, y: p.y))
        horizontal.addLine(to: CGPoint(x: p.x, y: p.y - short))
        horizontal.addLine(to: CGPoint(x: p.x + long, y: p.y))
        horizontal.addLine(to: CGPoint(x: p.x, y: p.y + short))
        horizontal.closeSubpath()
        context.fill(vertical, with: .color(Color.white.opacity(alpha)))
        context.fill(horizontal, with: .color(Color.white.opacity(alpha)))
    }

    /// Feststehender Sternenhimmel, damit der Raum nicht leer wirkt.
    private func drawBackgroundStars(_ context: inout GraphicsContext, size: CGSize) {
        for i in 0..<26 {
            let x = Self.unit(UInt64(i) &* 2 &+ 11) * size.width
            let y = Self.unit(UInt64(i) &* 2 &+ 12) * size.height
            let alpha = 0.10 + 0.22 * Self.unit(UInt64(i) &+ 500)
            let r = 0.6 + 0.9 * Self.unit(UInt64(i) &+ 900)
            context.fill(
                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                with: .color(Color.white.opacity(alpha))
            )
        }
    }

    /// Stabile Lage pro Zeile und Wort: von links nach rechts, in der Höhe unruhig.
    private func point(for index: Int, count: Int, seed: Swift.Int64, size: CGSize) -> CGPoint {
        let t = count <= 1 ? 0.5 : Double(index) / Double(count - 1)
        let key = UInt64(truncatingIfNeeded: seed) &* 31 &+ UInt64(index)
        let x = size.width * (0.14 + 0.72 * t)
        let y = size.height * (0.30 + 0.36 * Self.unit(key))
        return CGPoint(x: x, y: y)
    }

    /// Deterministische Zahl in 0..<1 (SplitMix64), damit Sterne nicht springen.
    private static func unit(_ seed: UInt64) -> Double {
        var z = seed &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / 9_007_199_254_740_992.0
    }
}
