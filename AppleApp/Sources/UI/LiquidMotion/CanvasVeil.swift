import SwiftUI

/// A controllable curtain over the already available motion canvas.
/// It uses exactly one CanvasPlayer and never changes the audio transport.
struct CanvasVeil: View {
    let url: URL
    let fallbackURL: URL?
    let isPlaying: Bool
    let side: CGFloat

    @State private var reveal: Double = 1
    @State private var controlsOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if reveal > 0.001 {
                CanvasPlayer(url: url, fallbackURL: fallbackURL, isPlaying: isPlaying)
                    .frame(width: side, height: side)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: side * CGFloat(reveal))
                    }
                    .allowsHitTesting(false)
            }
            VStack(alignment: .trailing, spacing: 7) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.88)) {
                        controlsOpen.toggle()
                    }
                } label: {
                    Image(systemName: "square.on.square.dashed")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reveal motion canvas")
                .accessibilityHint("Show slider for album cover and motion canvas")
                if controlsOpen {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Cover ↔ Canvas").font(.caption2.weight(.semibold))
                        Slider(value: $reveal, in: 0...1)
                            .tint(.cyan)
                            .accessibilityLabel("Motion canvas reveal")
                            .accessibilityValue("\(Int(reveal * 100)) percent")
                    }
                    .padding(10)
                    .frame(width: min(190, max(100, side * 0.8)))
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity)
                }
            }
            .padding(7)
        }
        .frame(width: side, height: side)
    }
}
