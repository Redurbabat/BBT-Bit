#if DEBUG && os(iOS)
import SwiftUI

/// Ausschließlich über den XCUITest-Startparameter erreichbar; keine vorgetäuschte Wiedergabe.
struct VideoReferencePreviewView: View {
    @State private var showConstellation = false
    @State private var started = Date()
    private let caption = "Wir folgen dem Licht"
    private let words = ["Wir", "folgen", "dem", "Licht"].enumerated().map {
        ConstellationWord(text: $0.element, start: Int64($0.offset) * 1500, end: Int64($0.offset + 1) * 1500)
    }
    private let shelf = FeedShelf(title: "Singles & EPs", items:
        ["Abendlicht", "Farbenspiel", "Horizont", "Weitblick", "Nachtklang", "Morgenrot"].map {
            ShelfCard(title: $0, subtitle: "Single · UI-Fixture")
        })

    var body: some View {
        Group {
            if showConstellation {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let elapsed = Int64(context.date.timeIntervalSince(started) * 1000) % 6500
                    ConstellationStage(words: words, lineText: caption, positionMs: max(0, elapsed), lineStart: 0,
                        immersive: true, trackTitle: "UI-Fixture · keine Audiowiedergabe",
                        onClose: { showConstellation = false },
                        onShowList: { showConstellation = false })
                }
                .ignoresSafeArea()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("UI-Fixture · keine Audiowiedergabe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ShelfCarousel(shelf: shelf, rail: true)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("bbt.video.artist.rail")
                        Text("Bogensteuerung")
                            .font(.headline)
                        ArcPlaybackDeck(onLyrics: openConstellation, onQueue: {}, more: Image(systemName: "ellipsis"))
                            .padding(.horizontal, 8)
                        Button("Sternbild öffnen", action: openConstellation)
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("bbt.video.constellation.open")
                        VStack(alignment: .leading) {
                            Text("Liste")
                            Text(caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .accessibilityIdentifier("bbt.video.lyrics.list")
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(.black)
        .preferredColorScheme(.dark)
    }

    private func openConstellation() {
        started = Date()
        showConstellation = true
    }
}
#endif
