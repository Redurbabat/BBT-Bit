import SwiftUI

/// Native 3D cylinder for the existing playback queue. No duplicate queue state.
struct QueueHorizon: View {
    let entries: [QueueEntry]
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focusedIndex = 0
    @State private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 112
    private let cardHeight: CGFloat = 132
    private let gap: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ON THE HORIZON")
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.65))

            if entries.isEmpty {
                EmptyView()
            } else if reduceMotion {
                accessibleStrip
            } else {
                cylinder
            }
        }
        .background { LiquidLiveCaptureMarker(id: "queue") }
        .onChange(of: entries.count) { _, count in
            focusedIndex = min(focusedIndex, max(0, count - 1))
        }
    }

    private var accessibleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    card(entry, index: index)
                }
            }
        }
    }

    private var cylinder: some View {
        GeometryReader { geometry in
            let count = max(entries.count, 1)
            let step = 360.0 / Double(count)
            let pitch = Double(cardWidth + gap)
            let chord = pitch / (2 * sin(.pi / Double(max(count, 3))))
            let arc = Double(max(count, 3)) * pitch / (2 * .pi)
            let radius = max(arc, chord, Double(cardWidth) * 0.6)
            let rotation = -Double(focusedIndex) * step + Double(dragOffset) / radius * (180 / .pi)

            ZStack {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    let angle = (Double(index) * step + rotation) * .pi / 180
                    let depth = cos(angle)
                    let visible = depth > -0.65
                    let scale = CGFloat(0.70 + 0.30 * max(0, depth))
                    card(entry, index: index)
                        .scaleEffect(scale)
                        .rotation3DEffect(.degrees(-sin(angle) * 76 - 5), axis: (0, 1, 0), perspective: 0.7)
                        .offset(x: CGFloat(sin(angle) * radius) * 0.9)
                        .opacity(visible ? 0.25 + 0.75 * max(0, depth) : 0)
                        .zIndex(depth)
                        .allowsHitTesting(visible)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { dragOffset = $0.translation.width }
                    .onEnded { value in
                        let stride = cardWidth + gap
                        let projected = value.predictedEndTranslation.width
                        let shift = Int((projected / stride).rounded())
                        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                            focusedIndex = wrapped(focusedIndex - shift, count: count)
                            dragOffset = 0
                        }
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
        .frame(height: cardHeight + 30)
        .clipped()
    }

    private func card(_ entry: QueueEntry, index: Int) -> some View {
        Button {
            if !reduceMotion && focusedIndex != index {
                focus(index)
            } else {
                onSelect(index)
            }
        } label: {
            VStack(spacing: 7) {
                ArtworkView(entry: entry, side: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                Text(entry.title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title), \(entry.artist)")
        .accessibilityHint("Titel auswählen oder abspielen")
    }

    private func focus(_ index: Int) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.82)) {
            focusedIndex = wrapped(index, count: max(entries.count, 1))
        }
    }

    private func wrapped(_ index: Int, count: Int) -> Int {
        ((index % count) + count) % count
    }
}
