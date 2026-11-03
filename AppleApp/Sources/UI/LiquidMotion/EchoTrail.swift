import SwiftUI

/// A small trail back to the real previous item in the active queue.
/// It never guesses what played outside the current queue.
struct EchoTrail: View {
    let previous: QueueEntry
    let onReplay: () -> Void

    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onReplay) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.cyan)
                ArtworkView(entry: previous, side: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(previous.title)
                    .lineLimit(1)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(hovering ? 0.24 : 0.10), in: Capsule())
            .offset(x: hovering && !reduceMotion ? -3 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: hovering)
        .accessibilityLabel("Replay earlier queued song: \(previous.title)")
        .background { LiquidLiveCaptureMarker(id: "echo") }
    }
}
