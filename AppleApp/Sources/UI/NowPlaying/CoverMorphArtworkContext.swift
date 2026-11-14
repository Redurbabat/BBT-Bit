#if os(iOS)
import SwiftUI
import RedBitShared
import UIKit

/// A single color sampling path for the mini-player and its full-screen
/// destination. Uses the existing artwork cache instead of fetching artwork
/// every frame, and never invents an audio-progress value.
@MainActor
private enum CoverMorphArtwork {
    static func colors(for entry: QueueEntry?) -> ArtworkPalette.PageTint {
        ArtworkPalette.pageTint(
            from: entry?.artworkData,
            seed: entry?.id.hashValue ?? 0
        )
    }

    static func artworkBytes(for entry: QueueEntry?) async -> Data? {
        guard let entry else { return nil }
        if let bytes = entry.artworkData { return bytes }
        guard let url = entry.thumbnailUrl else { return nil }
        let sized = SharedArtwork.sized(url, 120) ?? url
        guard let image = await ArtworkCache.shared.load(sized) else { return nil }
        return image.jpegData(compressionQuality: 0.60)
    }
}

/// The reference video keeps the current cover's colour under the bottom
/// player even in the Explore tab. The real iOS tab accessory supplies its
/// outer glass; this supplies only a subtle artwork-linked *inner* tint.
///
/// Native sheet zoom remains owned by NowPlayingZoomSource. This is never
/// a second player and does not change transport or video decoding.
struct CoverMorphMiniSurface: View {
    let entry: QueueEntry?
    let isPlaying: Bool
    let inline: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tint = ArtworkPalette.PageTint(
        wash: Color(red: 0.12, green: 0.10, blue: 0.20),
        accent: .cyan,
        elevated: Color(red: 0.14, green: 0.12, blue: 0.22)
    )
    @State private var drift = false

    private var motionEnabled: Bool {
        entry != nil && isPlaying && !reduceMotion &&
            !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            let shape = RoundedRectangle(cornerRadius: inline ? 23 : 27, style: .continuous)
            ZStack {
                if entry != nil && !reduceTransparency {
                    shape.fill(
                        LinearGradient(
                            colors: [
                                tint.wash.opacity(0.98),
                                tint.accent.opacity(0.44),
                                tint.wash.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    Ellipse()
                        .fill(tint.accent.opacity(motionEnabled ? 0.48 : 0.24))
                        .frame(width: max(90, geometry.size.width * 0.60), height: 90)
                        .blur(radius: 23)
                        .offset(
                            x: drift ? geometry.size.width * 0.35 : -geometry.size.width * 0.26,
                            y: drift ? 10 : -21
                        )
                        .allowsHitTesting(false)

                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.37),
                                    tint.accent.opacity(0.25),
                                    .white.opacity(0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                } else {
                    // Accessibility and no-track states are predictable.
                    shape.fill(Color(uiColor: .secondarySystemBackground).opacity(0.72))
                }
            }
            .clipShape(shape)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: entry?.id) {
            guard let entry else {
                tint = CoverMorphArtwork.colors(for: nil)
                return
            }
            tint = CoverMorphArtwork.colors(for: entry)
            let bytes = await CoverMorphArtwork.artworkBytes(for: entry)
            guard !Task.isCancelled, let bytes else { return }
            let sampled = ArtworkPalette.pageTint(from: bytes, seed: entry.id.hashValue)
            if reduceMotion {
                tint = sampled
            } else {
                withAnimation(.easeInOut(duration: 0.46)) { tint = sampled }
            }
        }
        .onAppear { updateDrift() }
        .onChange(of: motionEnabled) { _, _ in updateDrift() }
        .animation(
            motionEnabled ? .easeInOut(duration: 3.7).repeatForever(autoreverses: true) : nil,
            value: drift
        )
    }

    private func updateDrift() {
        drift = motionEnabled
    }
}

/// The expanded player must receive the *same actual artwork palette* as the
/// mini-player. Existing MeshBackdrop handles the full-page motion and allows
/// the native zoom to morph between two visually related surfaces.
struct CoverMorphFullBackdrop: View {
    let entry: QueueEntry?
    @State private var artwork: Data?

    var body: some View {
        MeshBackdrop(
            seed: entry?.id.hashValue ?? 0,
            artwork: artwork ?? entry?.artworkData
        )
        .task(id: entry?.id) {
            artwork = nil
            guard let bytes = await CoverMorphArtwork.artworkBytes(for: entry) else { return }
            guard !Task.isCancelled else { return }
            artwork = bytes
        }
    }
}
#endif
