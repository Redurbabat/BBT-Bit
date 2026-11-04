#if os(iOS)
import SwiftUI

/// Decorative motion only. The pulses express play/pause state, not measured
/// audio frequency or beat analysis; no second player/audio tap is created.
struct GlassBloomAtmosphere: View {
    let playing: Bool
    let expanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    private var motionAllowed: Bool {
        playing && !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(playing ? 0.24 : 0.10), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 98
                        )
                    )
                    .frame(width: 186, height: 130)
                    .blur(radius: 14)
                    .offset(x: drifting ? geometry.size.width - 122 : -49, y: -52)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(playing ? 0.25 : 0.10), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 95
                        )
                    )
                    .frame(width: 174, height: 132)
                    .blur(radius: 16)
                    .offset(x: drifting ? -28 : geometry.size.width - 121,
                            y: expanded ? 54 : 4)

                Circle()
                    .fill(.white.opacity(playing ? 0.35 : 0.15))
                    .frame(width: 3, height: 3)
                    .offset(x: drifting ? geometry.size.width - 26 : 30,
                            y: expanded ? 11 : 5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
        .onAppear(perform: updateAnimation)
        .onChange(of: playing) { _, _ in updateAnimation() }
        .onChange(of: reduceMotion) { _, _ in updateAnimation() }
        .animation(
            motionAllowed ? .easeInOut(duration: 3.6).repeatForever(autoreverses: true) : nil,
            value: drifting
        )
    }

    private func updateAnimation() {
        drifting = motionAllowed
    }
}

/// Small, accessible play-state indicator with subtle kinetic bars.
struct GlassBloomSignalBars: View {
    let playing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rising = false

    private let low: [CGFloat] = [5, 8, 5, 7]
    private let high: [CGFloat] = [12, 8, 15, 10]

    private var motionAllowed: Bool {
        playing && !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(playing ? Color.cyan : Color.secondary)
                    .frame(width: 2.7, height: rising ? high[index] : low[index])
            }
        }
        .frame(width: 24, height: 18)
        .accessibilityLabel(playing ? "Musik läuft" : "Musik pausiert")
        .onAppear(perform: updateAnimation)
        .onChange(of: playing) { _, _ in updateAnimation() }
        .onChange(of: reduceMotion) { _, _ in updateAnimation() }
        .animation(
            motionAllowed ? .easeInOut(duration: 0.86).repeatForever(autoreverses: true) : nil,
            value: rising
        )
    }

    private func updateAnimation() {
        rising = motionAllowed
    }
}

/// Distinct visual hierarchy underneath the cover/title:
/// audio status first, then transport controls, then optional deep links.
struct GlassBloomStatusRow: View {
    let playing: Bool

    var body: some View {
        HStack(spacing: 8) {
            GlassBloomSignalBars(playing: playing)
            Text(playing ? "JETZT LÄUFT" : "PAUSIERT")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Image(systemName: "sparkle")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.cyan.opacity(0.78))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct GlassBloomSwipeHint: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.arrow.right")
            Text("Wischen: Titel")
            Spacer()
            Image(systemName: "arrow.up.arrow.down")
            Text("Auf / Zu")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
        .accessibilityLabel("Horizontal wischen wechselt Titel; nach oben ausklappen und nach unten schließen.")
    }
}
#endif
