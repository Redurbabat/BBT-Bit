import SwiftUI

/// An optional original/translated line mirror. The actual synced lyrics,
/// word timing, playback position and share selection remain untouched.
struct LyricsMirror: View {
    let original: String
    let translation: String

    @State private var showOriginal = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("LYRICS MIRROR")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text(showOriginal ? LocalizedStringKey("Original") : LocalizedStringKey("Translation"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Button {
                flip()
            } label: {
                ZStack(alignment: .leading) {
                    Text(showOriginal ? original : translation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                        .id(showOriginal)
                        .transition(reduceMotion ? .opacity : mirrorFlip)
                }
                .clipped()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(showOriginal ? LocalizedStringKey("Original lyric") : LocalizedStringKey("Translated lyric")))
            .accessibilityIdentifier("red.lyrics.mirror.toggle")
            .accessibilityValue(Text(showOriginal ? original : translation))
            .accessibilityHint("Switch between original and translation")
            .gesture(DragGesture(minimumDistance: 25).onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) + 15 {
                    flip()
                }
            })
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.13)))
        .background { LiquidLiveCaptureMarker(id: "lyrics") }
    }

    /// Die Zeile klappt wie ein Spiegel um die waagrechte Achse: die alte kippt
    /// nach oben weg, die neue kommt von unten herein.
    private var mirrorFlip: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: MirrorTilt(angle: 75, opacity: 0), identity: MirrorTilt(angle: 0, opacity: 1)),
            removal: .modifier(active: MirrorTilt(angle: -75, opacity: 0), identity: MirrorTilt(angle: 0, opacity: 1)))
    }

    private func flip() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.84)) {
            showOriginal.toggle()
        }
    }
}

private struct MirrorTilt: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.5)
            .opacity(opacity)
    }
}
