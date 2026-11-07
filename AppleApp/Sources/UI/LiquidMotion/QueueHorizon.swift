import SwiftUI

/// Dreidimensionales Queue-Karussell; verwendet ausschließlich die bestehende Queue.
struct QueueHorizon: View {
    let entries: [QueueEntry]
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focusedIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 154
    private let cardHeight: CGFloat = 190
    private let step: CGFloat = 126

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ON THE HORIZON")
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 4)

            if !entries.isEmpty {
                if reduceMotion {
                    accessibleStrip
                } else {
                    carousel
                }
            }
        }
        .background { LiquidLiveCaptureMarker(id: "queue") }
        .onChange(of: entries.count) { _, count in
            focusedIndex = min(focusedIndex, max(0, count - 1))
        }
    }

    private var accessibleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    card(entry, index: index)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var carousel: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let visibleStep = min(step, max(76, (availableWidth - cardWidth) * 0.44))
            ZStack {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    let relative = CGFloat(relativeIndex(index, count: entries.count)) + dragOffset / visibleStep
                    let distance = abs(relative)
                    if distance < 2.6 {
                        card(entry, index: index)
                            .scaleEffect(max(0.74, 1 - distance * 0.14))
                            .rotation3DEffect(.degrees(Double(-relative * 32)),
                                              axis: (x: 0, y: 1, z: 0),
                                              perspective: 0.55)
                            .offset(x: relative * visibleStep, y: distance * 8)
                            .opacity(max(0.12, 1 - distance * 0.30))
                            .zIndex(10 - Double(distance))
                    }
                }
            }
            .frame(width: availableWidth, height: geometry.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let projected = value.predictedEndTranslation.width
                        let shift = Int((projected / visibleStep).rounded())
                        guard shift != 0 else { return }
                        focus(focusedIndex - shift)
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Nächste Titel")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: focus(focusedIndex + 1)
                case .decrement: focus(focusedIndex - 1)
                @unknown default: break
                }
            }
        }
        .frame(height: cardHeight + 24)
    }

    private func card(_ entry: QueueEntry, index: Int) -> some View {
        Button {
            if !reduceMotion && focusedIndex != index {
                focus(index)
            } else {
                onSelect(index)
            }
        } label: {
            VStack(spacing: 9) {
                ArtworkView(entry: entry, side: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(.white)
            }
            .padding(10)
            .frame(width: cardWidth, height: cardHeight)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.20), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title), \(entry.artist)")
        .accessibilityHint("Titel auswählen oder abspielen")
    }

    private func focus(_ index: Int) {
        guard !entries.isEmpty else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.84)) {
            focusedIndex = wrapped(index, count: entries.count)
        }
    }

    private func relativeIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let forward = wrapped(index - focusedIndex, count: count)
        return forward > count / 2 ? forward - count : forward
    }

    private func wrapped(_ index: Int, count: Int) -> Int {
        ((index % count) + count) % count
    }
}
