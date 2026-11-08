import SwiftUI

/// Kategorien behalten ihre vollständigen Browse-Parameter und ihren bisherigen Zieltyp.
struct MoodGalaxy: View {
    let categories: [MoodGenre]

    var body: some View {
        if !categories.isEmpty {
            VStack(spacing: 10) {
                Text("Discover your music universe").font(.title2.bold())
                GeometryReader { proxy in
                    ZStack {
                        Ellipse().stroke(.primary.opacity(0.12), lineWidth: 0.5).padding(30)
                            .accessibilityHidden(true)
                        Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        let visible = Array(categories.prefix(8))
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, category in
                            NativeCardZoomLink(id: category.id) {
                                MoodGenrePlaylistsView(category: category)
                            } label: {
                                VStack(spacing: 3) {
                                    ArtworkView(url: category.thumbnailUrl, data: nil, side: 48)
                                        .frame(width: 48, height: 48).clipShape(Circle())
                                    Text(category.title).font(.caption2).lineLimit(1).frame(width: 78)
                                }.frame(minWidth: 48, minHeight: 64)
                            }
                            .accessibilityLabel(category.title)
                            .position(MusicMotionGeometry.orbit(index: index, count: visible.count, size: proxy.size))
                        }
                    }
                }.frame(height: 300)
            }
        }
    }
}
