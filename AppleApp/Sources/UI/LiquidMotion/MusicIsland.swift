import SwiftUI

/// An in-app music island. This is not the hardware Dynamic Island or a
/// Live Activity; all content comes from the existing PlaybackController.
struct MusicIsland: View {
    @Environment(PlaybackController.self) private var controller
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var level = 1 // 0: dot, 1: capsule, 2: controls

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.85)) {
                        level = min(2, level + 1)
                    }
                } label: {
                    HStack(spacing: 9) {
                        ArtworkView(entry: controller.current, side: level == 0 ? 24 : 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        if level > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(controller.current?.title ?? "Not Playing")
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(controller.current?.artist ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: controller.isPlaying ? "waveform" : "pause.fill")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Music Island: \(controller.current?.title ?? "Not Playing")")
                .accessibilityHint("Expand the in-app music controls")

                if level > 0 {
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.88)) {
                            level = 0
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Minimize music island to a dot")
                }
            }
            if level == 2 {
                HStack(spacing: 28) {
                    Button { controller.previous() } label: {
                        Image(systemName: "backward.fill")
                    }
                    .disabled(!controller.canPlayPrevious)
                    Button { controller.togglePlayPause() } label: {
                        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    }
                    Button { controller.next() } label: {
                        Image(systemName: "forward.fill")
                    }
                    .disabled(!controller.canPlayNext)
                    #if os(iOS)
                    Button {
                        appModel.nowPlayingPresented = true
                        level = 1
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .accessibilityLabel("Open full music player")
                    #endif
                }
                .font(.headline)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, level == 0 ? 8 : 12)
        .padding(.vertical, 7)
        .frame(width: level == 0 ? 43 : (level == 2 ? 286 : 220))
        .chromeGlass(in: RoundedRectangle(cornerRadius: level == 0 ? 22 : 21, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > 70, abs(dx) > abs(dy), !PartyStore.shared.state.controlsLocked {
                    if dx < 0, controller.canPlayNext { controller.next() }
                    if dx > 0, controller.canPlayPrevious { controller.previous() }
                } else if dy > 65 {
                    #if os(iOS)
                    appModel.nowPlayingPresented = true
                    #else
                    withAnimation(reduceMotion ? nil : .spring()) { level = 2 }
                    #endif
                }
            }
        )
        .accessibilityElement(children: .contain)
        .background { LiquidLiveCaptureMarker(id: "island") }
        .onChange(of: level) { _, _ in
            LiquidLiveCaptureMarker.refresh("island")
        }
    }
}
