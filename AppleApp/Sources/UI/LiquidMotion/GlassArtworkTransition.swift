import SwiftUI

/// Der Vollplayer hält genau ein vorheriges Cover über den titelgebundenen
/// Neuaufbau seiner Videoansicht hinweg. Kein globaler Playback-Zustand.
@MainActor final class ArtworkTransitionHistory {
    var displayed: QueueEntry?
}

private struct ArtworkTransitionHistoryKey: EnvironmentKey {
    static let defaultValue: ArtworkTransitionHistory? = nil
}

extension EnvironmentValues {
    var artworkTransitionHistory: ArtworkTransitionHistory? {
        get { self[ArtworkTransitionHistoryKey.self] }
        set { self[ArtworkTransitionHistoryKey.self] = newValue }
    }
}

/// Ruhiger Coverwechsel ohne Kreisvergrößerung oder Shader-Verzerrung.
/// Die native Zoom-Navigation zwischen Mini- und Vollplayer bleibt unverändert.
struct GlassArtworkTransition: View {
    let entry: QueueEntry?
    let side: CGFloat
    @State private var displayed: QueueEntry?
    @State private var previous: QueueEntry?
    @State private var incomingOpacity: Double = 1
    @Environment(\.artworkTransitionHistory) private var history
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            if let previous, !reduceMotion, !reduceTransparency {
                ArtworkView(entry: previous, side: side)
            }
            ArtworkView(entry: entry, side: side)
                .opacity(incomingOpacity)
        }
        .frame(width: side, height: side)
        .clipped()
        .task(id: entry?.id) {
            let last = history?.displayed ?? displayed
            guard last?.id != entry?.id else { return }
            previous = last
            displayed = entry
            history?.displayed = entry
            guard previous != nil, !reduceMotion, !reduceTransparency else {
                incomingOpacity = 1
                previous = nil
                return
            }

            incomingOpacity = 0
            // Erst den alten Frame zeigen, dann nur die Deckkraft überblenden.
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                incomingOpacity = 1
            }
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            previous = nil
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
