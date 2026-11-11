import SwiftUI

/// Kategorien behalten ihre vollständigen Browse-Parameter und ihren bisherigen Zieltyp.
/// Die Galaxie lässt sich mit dem Finger drehen; Kategorien wandern auf einer
/// geneigten Bahn nach vorn (größer) oder hinten (kleiner).
struct MoodGalaxy: View {
    let categories: [MoodGenre]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var spin: Double = 0
    @State private var dragTurn: Double = 0

    var body: some View {
        if !categories.isEmpty {
            VStack(spacing: 10) {
                Text("Discover your music universe").font(.title2.bold())
                GeometryReader { proxy in
                    let visible = Array(categories.prefix(8))
                    let step = 2 * Double.pi / Double(max(1, visible.count))
                    let turn = spin + dragTurn
                    ZStack {
                        GalaxyBackdrop(rotation: turn * 0.7, tint: Theme.accent)
                            .accessibilityHidden(true).allowsHitTesting(false)
                        core
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, category in
                            NativeCardZoomLink(id: category.id) {
                                MoodGenrePlaylistsView(category: category)
                            } label: {
                                VStack(spacing: 3) {
                                    ArtworkView(url: category.thumbnailUrl, data: nil, side: 48)
                                        .frame(width: 48, height: 48).clipShape(Circle())
                                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
                                    Text(category.title).font(.caption2).lineLimit(1).frame(width: 78)
                                }.frame(minWidth: 48, minHeight: 64)
                            }
                            .accessibilityLabel(category.title)
                            .modifier(OrbitPlacement(angle: -Double.pi / 2 + Double(index) * step + turn, size: proxy.size))
                        }
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 16)
                            .onChanged { value in
                                guard !reduceMotion, abs(value.translation.width) > abs(value.translation.height) else { return }
                                dragTurn = Double(value.translation.width) / 110
                            }
                            .onEnded { value in
                                guard !reduceMotion else { return }
                                // Schwung des Fingers dreht weiter und rastet auf eine Kategorie ein.
                                let flung = spin + Double(value.predictedEndTranslation.width) / 110
                                let settled = (flung / step).rounded() * step
                                withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                                    spin = settled
                                    dragTurn = 0
                                }
                            }
                    )
                }.frame(height: 300)
            }
        }
    }

    /// Leuchtender Kern unter Glas, statt eines einzelnen Symbols.
    private var core: some View {
        Image(systemName: "sparkles")
            .font(.title)
            .foregroundStyle(Theme.accent)
            .frame(width: 66, height: 66)
            .background {
                if reduceTransparency {
                    Circle().fill(.background.secondary)
                } else if #available(iOS 26.0, macOS 26.0, *) {
                    Circle().fill(.clear).glassEffect(.regular, in: Circle())
                } else {
                    Circle().fill(.ultraThinMaterial)
                }
            }
            .accessibilityHidden(true)
    }
}
