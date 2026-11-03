import SwiftUI

/// A compact visual preview of the *existing* upcoming queue. Tapping a card
/// plays its actual queue index; it does not maintain a competing queue.
struct QueueHorizon: View {
    let entries: [QueueEntry]
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveringIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ON THE HORIZON")
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.65))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                        Button { onSelect(index) } label: {
                            VStack(spacing: 6) {
                                ArtworkView(entry: entry, side: 68)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .rotation3DEffect(
                                        .degrees(reduceMotion ? 0 : (hoveringIndex == index ? 0 : Double(index - 1) * 7)),
                                        axis: (0, 1, 0)
                                    )
                                Text(entry.title)
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 98)
                            .padding(8)
                            .background(.white.opacity(hoveringIndex == index ? 0.2 : 0.08),
                                        in: RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.plain)
                        .onHover { hoveringIndex = $0 ? index : nil }
                        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.85),
                                   value: hoveringIndex)
                        .accessibilityLabel("Play next: \(entry.title) by \(entry.artist)")
                    }
                }
            }
        }
    }
}
