import SwiftUI

/// Eigene Cover-Linse. Videoflächen und deren Transport werden nicht verändert.
struct GlassArtworkTransition: View {
    let entry: QueueEntry?
    let side: CGFloat
    @State private var displayed: QueueEntry?
    @State private var previous: QueueEntry?
    @State private var reveal: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            if let previous, reveal < 1, !reduceMotion {
                ArtworkView(entry: previous, side: side)
            }
            if reduceMotion || reduceTransparency || previous == nil {
                ArtworkView(entry: entry, side: side)
            } else {
                ArtworkView(entry: entry, side: side)
                    .distortionEffect(ShaderLibrary.coverLensRefraction(.float(Float(reveal)), .float2(Float(side), Float(side))),
                                      maxSampleOffset: CGSize(width: 16, height: 16))
                    .mask { Circle().frame(width: side * 1.5 * reveal, height: side * 1.5 * reveal) }
                Circle().stroke(.white.opacity((1 - reveal) * 0.55), lineWidth: 2)
                    .frame(width: side * 1.5 * reveal, height: side * 1.5 * reveal)
            }
        }
        .frame(width: side, height: side).clipped()
        .task(id: entry?.id) {
            guard displayed?.id != entry?.id else { return }
            previous = displayed
            displayed = entry
            guard previous != nil, !reduceMotion, !reduceTransparency else { reveal = 1; return }
            reveal = 0
            withAnimation(.easeInOut(duration: 0.6)) { reveal = 1 }
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            previous = nil
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
