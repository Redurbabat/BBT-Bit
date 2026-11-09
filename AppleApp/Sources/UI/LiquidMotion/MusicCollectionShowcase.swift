import SwiftUI

enum CollectionShowcaseStyle { case galaxy, records }

/// Cover aus der bereits geladenen Sammlung. Auswahl und Navigation bleiben getrennt.
struct MusicCollectionShowcase: View {
    let items: [ShelfCard]
    var style: CollectionShowcaseStyle = .galaxy
    var preferTrack = false
    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selectedIndex = 0

    private var index: Int { MusicMotionGeometry.wrapped(selectedIndex, count: items.count) }
    private var selection: ShelfCard? { items.indices.contains(index) ? items[index] : nil }
    private var recordOffsets: [Int] {
        var seen: Set<Int> = [index]
        return [-1, 1, -2, 2].filter {
            seen.insert(MusicMotionGeometry.wrapped(index + $0, count: items.count)).inserted
        }.sorted()
    }

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 12) {
                if reduceMotion || typeSize.isAccessibilitySize {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(items) { ShelfCardView(card: $0, artworkSide: 130, preferTrack: preferTrack) }
                        }.padding(.horizontal, 8)
                    }
                } else {
                    GeometryReader { proxy in
                        ZStack {
                            if style == .galaxy {
                                galaxy(size: proxy.size)
                            } else {
                                records(size: proxy.size)
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.3 else { return }
                            move(value.translation.width < 0 ? 1 : -1)
                        })
                    }
                    .frame(height: style == .galaxy ? 300 : 235)
                    if let selection {
                        Text(selection.title).font(.headline).lineLimit(2).multilineTextAlignment(.center)
                        if let subtitle = selection.subtitle {
                            Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    HStack(spacing: 20) {
                        navigationButton("Previous collection", symbol: "chevron.left", step: -1)
                        Text("\(index + 1) / \(items.count)")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            .accessibilityLabel("Collection \(index + 1) of \(items.count)")
                        navigationButton("Next collection", symbol: "chevron.right", step: 1)
                    }
                }
            }
            .onChange(of: items.map(\.id)) { _, _ in selectedIndex = min(index, max(0, items.count - 1)) }
            .accessibilityElement(children: .contain)
        }
    }

    private func navigationButton(_ label: LocalizedStringKey, symbol: String, step: Int) -> some View {
        Button { move(step) } label: {
            Image(systemName: symbol).frame(width: 44, height: 44).contentShape(Circle())
        }
        .buttonStyle(.plain).accessibilityLabel(Text(label)).disabled(items.count < 2)
        .accessibilityIdentifier(step < 0 ? "red.collection.previous" : "red.collection.next")
    }

    private func move(_ step: Int) {
        guard items.count > 1 else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.86)) {
            selectedIndex = MusicMotionGeometry.wrapped(index + step, count: items.count)
        }
    }

    private func galaxy(size: CGSize) -> some View {
        ZStack {
            Canvas { context, canvasSize in
                for star in 0..<54 {
                    let x = ConstellationGeometry.unit(UInt64(star * 2 + 1)) * canvasSize.width
                    let y = ConstellationGeometry.unit(UInt64(star * 2 + 2)) * canvasSize.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                                 with: .color(.primary.opacity(0.16)))
                }
                context.stroke(Path(ellipseIn: CGRect(x: 30, y: 28, width: max(0, canvasSize.width - 60),
                                                     height: max(0, canvasSize.height - 56))),
                               with: .color(.primary.opacity(0.10)), lineWidth: 0.5)
            }.accessibilityHidden(true).allowsHitTesting(false)
            let neighbours = MusicMotionGeometry.neighbours(selected: index, count: items.count)
            ForEach(Array(neighbours.enumerated()), id: \.element) { slot, itemIndex in
                Button {
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) { selectedIndex = itemIndex }
                } label: {
                    ArtworkView(url: items[itemIndex].thumbnailUrl, data: nil, side: 48)
                        .frame(width: 48, height: 48).clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Focus collection: \(items[itemIndex].title)")
                .position(MusicMotionGeometry.orbit(index: slot, count: neighbours.count, size: size))
            }
            if let selection {
                collectionLink(selection, side: min(116, size.width * 0.34))
                    .position(x: size.width / 2, y: size.height / 2)
            }
        }
    }

    private func records(size: CGSize) -> some View {
        ZStack {
            ForEach(recordOffsets, id: \.self) { delta in
                let neighbour = MusicMotionGeometry.wrapped(index + delta, count: items.count)
                    Button { move(delta) } label: {
                        ArtworkView(url: items[neighbour].thumbnailUrl, data: nil, side: min(154, size.width * 0.42))
                            .aspectRatio(1, contentMode: .fit).clipShape(.rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .rotation3DEffect(.degrees(Double(delta) * -18), axis: (0, 1, 0))
                    .rotationEffect(.degrees(Double(delta) * 5))
                    .scaleEffect(1 - CGFloat(abs(delta)) * 0.10)
                    .opacity(abs(delta) == 2 ? 0.55 : 0.8)
                    .offset(x: CGFloat(delta) * min(70, size.width * 0.19), y: CGFloat(abs(delta)) * 6)
                    .accessibilityLabel("Focus collection: \(items[neighbour].title)")
                    .zIndex(Double(3 - abs(delta)))
            }
            if let selection {
                collectionLink(selection, side: min(178, size.width * 0.49), vinyl: true)
                    .zIndex(4)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func collectionLink(_ card: ShelfCard, side: CGFloat, vinyl: Bool = false) -> some View {
        ShelfCardTap(card: card, preferTrack: preferTrack) {
            ZStack {
                if vinyl {
                    VinylRecord(artworkURL: card.thumbnailUrl, side: side * 0.93, isCurrent: recordIsCurrent(card))
                        .offset(x: side * 0.25)
                }
                ArtworkView(url: card.thumbnailUrl, data: nil, side: side)
                    .frame(width: side, height: side).clipShape(.rect(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.20), radius: 12, y: 6)
            }
            .frame(width: side, height: side)
            .accessibilityLabel(card.title)
        }
        .contextMenu { ShelfCardActionButtons(card: card) }
    }

    private func recordIsCurrent(_ card: ShelfCard) -> Bool {
        guard let current = controller.current else { return false }
        if let videoID = card.videoId, videoID == current.videoId { return true }
        return current.albumName == card.title && !current.artist.isEmpty
            && (card.subtitle?.localizedCaseInsensitiveContains(current.artist) ?? false)
    }
}

private struct VinylRecord: View {
    let artworkURL: String?
    let side: CGFloat
    let isCurrent: Bool
    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !isCurrent || !controller.isPlaying || reduceMotion)) { timeline in
            ZStack {
                Circle().fill(.black)
                ForEach(1..<7) { groove in
                    Circle().stroke(.white.opacity(0.12), lineWidth: 0.5).padding(CGFloat(groove) * side * 0.045)
                }
                ArtworkView(url: artworkURL, data: nil, side: side * 0.32).clipShape(Circle())
                Circle().fill(.white.opacity(0.7)).frame(width: 4, height: 4)
            }
            // Pause hält die echte Position; andere Platten übernehmen keinen
            // Fortschritt eines fremden Titels.
            .rotationEffect(.degrees(isCurrent && !reduceMotion ? controller.livePosition(at: timeline.date) * 198 : 0))
        }
        .frame(width: side, height: side).accessibilityHidden(true).allowsHitTesting(false)
    }
}
