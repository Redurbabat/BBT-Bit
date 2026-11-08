import SwiftUI

/// Kompakter Zugang zu sekundären Player-Werkzeugen.
///
/// Das frühere mehrstufige Dock veränderte beim Aufklappen die Höhe des
/// Playback-Decks. Ein natives Menü behält dagegen seine feste Größe und
/// lässt Songtitel, Seek-Regler und Transport an ihrer Position.
/// Die Aktionen bleiben Eigentum der aufrufenden NowPlayingView.
struct InfinityDock: View {
    let automixEnabled: Bool
    let onLyrics: () -> Void
    let onQueue: () -> Void
    let onOutput: () -> Void
    let onEqualizer: () -> Void
    let onPipeline: () -> Void
    let onAutomix: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Menu {
                Section("Musik") {
                    Button(action: onLyrics) {
                        Label("Songtexte", systemImage: "text.quote")
                    }
                    Button(action: onQueue) {
                        Label("Warteschlange", systemImage: "list.bullet")
                    }
                }
                Section("Audio") {
                    Button(action: onOutput) {
                        Label("Audioausgabe", systemImage: "headphones")
                    }
                    Button(action: onEqualizer) {
                        Label("Equalizer", systemImage: "slider.horizontal.3")
                    }
                    Button(action: onPipeline) {
                        Label("Audio-Pipeline", systemImage: "waveform.path")
                    }
                    Button(action: onAutomix) {
                        Label(automixEnabled ? "Automix ausschalten" : "Automix einschalten",
                              systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            } label: {
                Label("Werkzeuge", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .modifier(InfinityGlassSurface(reduceTransparency: reduceTransparency))
                    .contentShape(Capsule())
            }
            .accessibilityLabel("Player-Werkzeuge")
            .accessibilityHint("Öffnet Songtexte, Warteschlange und Audio-Werkzeuge")
        }
        .accessibilityElement(children: .contain)
        .background { LiquidLiveCaptureMarker(id: "dock") }
    }
}

private struct InfinityGlassSurface: ViewModifier {
    let reduceTransparency: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(.black.opacity(0.82), in: Capsule())
        } else if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.background(.ultraThinMaterial, in: Capsule())
        }
    }
}
