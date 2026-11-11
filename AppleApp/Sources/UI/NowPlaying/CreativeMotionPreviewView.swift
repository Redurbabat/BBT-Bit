#if DEBUG && os(iOS)
import SwiftUI

/// Verwendet Produktionskomponenten mit offen gekennzeichneten lokalen
/// Prüfdaten. Es wird keine Audioquelle gestartet und kein Erfolg simuliert.
struct CreativeMotionPreviewView: View {
    @State private var showsLyrics = false
    @State private var position: Double = 0
    @State private var chosenTrack = ""
    private let titles = ["Abendlicht", "Farbenspiel", "Horizont", "Weitblick", "Nachtklang", "Morgenrot"]
    private var cards: [ShelfCard] { titles.map { ShelfCard(title: $0, subtitle: "Lokale Prüfdaten") } }
    private var entries: [QueueEntry] {
        titles.enumerated().map { QueueEntry.youtube(videoId: "fixture-\($0.offset)", title: $0.element, artist: "Prüfdaten") }
    }
    private var words: [ConstellationWord] {
        let text = ["Wir", "folgen", "dem", "Licht"]
        return (0..<60).map { index in
            ConstellationWord(text: text[index % 4], start: Int64(index) * 1300,
                              end: Int64(index + 1) * 1300, line: index / 4)
        }
    }

    /// Offen gekennzeichnete Prüfmelodie statt gemessener Stimme: zeigt die
    /// Stimmform ohne Audiowiedergabe.
    private var voices: [ConstellationVoice] {
        let melody: [Double] = [0, 4, 7, 5, 9, 7, 4, 2, 0, -3, 2, 5]
        return words.indices.map { (index: Int) -> ConstellationVoice in
            let loudness: Double = -24 + Double(index % 4) * 4
            let brightness: Double = 1400 + Double(index % 5) * 150
            let semitones: Double = melody[index % melody.count] + Double(index / 12)
            let pitch: Double = 196 * pow(2.0, semitones / 12)
            return ConstellationVoice(energyDb: loudness, brightnessHz: brightness, pitchHz: pitch, pitchConfidence: 0.85)
        }
    }

    var body: some View {
        if showsLyrics {
            VStack(spacing: 0) {
                ConstellationStage(words: words, lineText: "Wir folgen dem Licht",
                    positionMs: Int64(position * 1000), lineStart: 0,
                    immersive: false, trackTitle: "UI-Prüfdaten · keine Audiowiedergabe",
                    onClose: { showsLyrics = false }, onShowList: { showsLyrics = false },
                    duration: 80, audioPosition: position,
                    beatTimes: (0...160).map { Double($0) * 0.5 },
                    lineTexts: Array(repeating: "Wir folgen dem Licht", count: 15),
                    voices: voices)
                HStack {
                    Button("Start") { position = 0 }.frame(minHeight: 44)
                    Button("70 s") { position = 70 }.frame(minHeight: 44).accessibilityIdentifier("red.fixture.finale")
                    Button("75 s") { position = 75 }.frame(minHeight: 44).accessibilityIdentifier("red.fixture.middle")
                    Button("80 s") { position = 80 }.frame(minHeight: 44).accessibilityIdentifier("red.fixture.end")
                }.buttonStyle(.bordered)
                Text("UI-Prüfdaten · keine Audiowiedergabe").font(.caption).padding(8)
            }.background(.black).preferredColorScheme(.dark)
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    Text("UI-Prüfdaten · keine Audiowiedergabe").font(.caption)
                    Button("Sternbild prüfen") { position = 30; showsLyrics = true }
                        .frame(minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("red.fixture.lyrics")
                    Text("Musikgalaxie").font(.title2)
                    MusicCollectionShowcase(items: cards)
                    Text("Plattenregal").font(.title2)
                    MusicCollectionShowcase(items: cards, style: .records)
                    PlaylistCoverFan(entries: entries) { index in chosenTrack = entries[index].title }
                    Text(chosenTrack).accessibilityIdentifier("red.fixture.chosen")
                    Text("Automix-Lichtbrücke").font(.title2)
                    AutomixLightBridge(current: entries.first, next: entries.last, progress: 0.5, isMixing: true)
                    HStack {
                        EclipseMoon(remaining: 1)
                        EclipseMoon(remaining: 0.5)
                        EclipseMoon(remaining: 0)
                    }
                }.padding(20)
            }
        }
    }
}
#endif
