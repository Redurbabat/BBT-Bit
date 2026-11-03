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
                Text(showOriginal ? "Original" : "Translation")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Button {
                flip()
            } label: {
                Text(showOriginal ? original : translation)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                    .contentTransition(.opacity)
                    .id(showOriginal)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showOriginal ? "Original lyric" : "Translated lyric")
            .accessibilityHint("Switch between original and translation")
            .gesture(DragGesture(minimumDistance: 25).onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) + 15 {
                    flip()
                }
            })
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.13)))
    }

    private func flip() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.84)) {
            showOriginal.toggle()
        }
    }
}
