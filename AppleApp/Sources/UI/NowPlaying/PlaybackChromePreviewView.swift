#if DEBUG && os(iOS)
import SwiftUI

/// Dieselben nativen Container und Produktionskomponenten mit lokalen Daten.
/// Kein Netzwerk und kein simulierter Audiozustand.
struct PlaybackChromePreviewView: View {
    @State private var selection = 0
    private let hit = SearchHitDTO(kind: "top", videoId: nil,
        title: "Ein langer Titel für das hervorgehobene Suchergebnis",
        subtitle: "Lokale UI-Prüfdaten", thumbnailUrl: nil, durationText: nil,
        albumName: nil, browseId: nil, browseType: nil, artistId: nil,
        albumId: nil, isVideo: nil, setVideoId: nil)

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selection) {
                Tab("Home", systemImage: "house.fill", value: 0) { results }
                Tab("Explore", systemImage: "square.grid.2x2.fill", value: 1) { results }
                Tab("Library", systemImage: "square.stack.fill", value: 2) { results }
                Tab("Search", systemImage: "magnifyingglass", value: 3, role: .search) {
                    SearchView()
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .modifier(PlaybackPillMount())
        }
    }

    private var results: some View {
        PageStack {
            List {
                Text("UI-Fixture · keine Audiowiedergabe").font(.caption)
                TopResultSection(hit: hit, scope: .all, onGoToAlbum: { _ in })
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                ForEach(0..<50, id: \.self) { index in
                    Text("Lokale Ergebniszeile \(index + 1)").frame(minHeight: 52)
                }
            }
            .listStyle(.plain)
            .modifier(DockScrollDirectionObserver())
            .navigationTitle("Layoutprüfung")
        }
    }
}
#endif
