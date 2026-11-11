import SwiftUI

/// Dreidimensionales Queue-Karussell; verwendet ausschließlich die bestehende Queue.
struct QueueHorizon: View {
    let entries: [QueueEntry]
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PartyStore.self) private var party
    /// Fortlaufende Fokusposition ohne Umbruch. Daraus entsteht je Karte eine
    /// „Runde“; wechselt sie, blendet die Karte am anderen Rand neu ein, statt
    /// quer durch das Karussell zu fliegen (vor allem bei kurzen Queues sichtbar).
    @State private var focusVirtual = 0
    @GestureState private var dragOffset: CGFloat = 0

    private var focusedIndex: Int { entries.isEmpty ? 0 : wrapped(focusVirtual, count: entries.count) }

    private struct Slot: Hashable {
        let index: Int
        let lap: Int
    }

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
                    HStack(spacing: 14) {
                        Button { focus(focusedIndex - 1) } label: {
                            Image(systemName: "chevron.left").frame(width: 44, height: 44)
                        }.accessibilityLabel("Previous track")
                        Button("Play selected track") {
                            guard entries.indices.contains(focusedIndex) else { return }
                            onSelect(focusedIndex)
                        }.frame(minHeight: 44).disabled(party.state.controlsLocked)
                        Button { focus(focusedIndex + 1) } label: {
                            Image(systemName: "chevron.right").frame(width: 44, height: 44)
                        }.accessibilityLabel("Next track")
                    }.buttonStyle(.plain).frame(maxWidth: .infinity)
                }
            }
        }
        .background { LiquidLiveCaptureMarker(id: "queue") }
        .onChange(of: entries.count) { _, count in
            focusVirtual = min(focusedIndex, max(0, count - 1))
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
                ForEach(slots, id: \.self) { slot in
                    carouselItem(index: slot.index, visibleStep: visibleStep)
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
        .frame(height: cardHeight + 80)
    }

    /// Keep the SwiftUI type-checker away from a nested ForEach + 3D transform.
    @ViewBuilder
    private func carouselItem(index: Int, visibleStep: CGFloat) -> some View {
        let relative: CGFloat = CGFloat(relativeIndex(index, count: entries.count))
            + dragOffset / visibleStep
        let distance: CGFloat = abs(relative)
        if distance < 2.6 {
            let scale: CGFloat = max(0.74, 1 - distance * 0.14)
            let angle: Angle = .degrees(Double(-relative * 32))
            let theta = Double(relative) * 24 * .pi / 180
            let radius = max(visibleStep * 2.1, 150)
            let xOffset: CGFloat = sin(theta) * radius
            let yOffset: CGFloat = (1 - cos(theta)) * radius
            let alpha: Double = Double(max(0.12, 1 - distance * 0.30))
            card(entries[index], index: index)
                .scaleEffect(scale)
                .rotation3DEffect(angle, axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                .rotationEffect(.degrees(Double(relative) * 9))
                .offset(x: xOffset, y: yOffset)
                .opacity(alpha)
                .zIndex(10 - Double(distance))
        }
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
        .disabled(party.state.controlsLocked)
        .accessibilityLabel("\(entry.title), \(entry.artist)")
        .accessibilityHint(
            reduceMotion || focusedIndex == index
                ? "Doppeltippen, um den Titel abzuspielen"
                : "Doppeltippen, um diesen Titel im Karussell zu fokussieren"
        )
    }

    private func focus(_ index: Int) {
        guard !entries.isEmpty else { return }
        let target = wrapped(index, count: entries.count)
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.84)) {
            focusVirtual += relativeIndex(target, count: entries.count)
        }
    }

    private var slots: [Slot] {
        let count = entries.count
        guard count > 0 else { return [] }
        return entries.indices.map { index in
            let position = focusVirtual + relativeIndex(index, count: count)
            return Slot(index: index, lap: (position - index) / count)
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
