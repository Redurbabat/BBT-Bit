#if os(iOS)
import SwiftUI
import Observation
import UIKit

/// A transient, logo-origin music surface. The app's *real* playback
/// controller owns audio state; this object owns only the presentation.
/// A second instance of PlaybackController is never created.
enum LogoGlassBloomPhase: Equatable {
    case idle
    case spark
    case compact
    case expanded
}

@MainActor
@Observable
final class LogoGlassBloomCoordinator {
    static let shared = LogoGlassBloomCoordinator()

    private(set) var phase: LogoGlassBloomPhase = .idle
    private var revealTask: Task<Void, Never>?
    private var hideTask: Task<Void, Never>?

    var isVisible: Bool { phase != .idle }

    private init() {}

    func playbackStartedOrTrackChanged() {
        present(expanded: false)
    }

    func logoTapped() {
        switch phase {
        case .idle:
            present(expanded: false)
        case .spark, .compact:
            present(expanded: true)
        case .expanded:
            dismiss()
        }
    }

    func logoHeld() {
        present(expanded: true)
    }

    func expand() {
        present(expanded: true)
    }

    func collapse() {
        guard isVisible else { return }
        revealTask?.cancel()
        withAnimation(motion(.spring(response: 0.42, dampingFraction: 0.86))) {
            phase = .compact
        }
        scheduleHide()
    }

    func keepOpenBriefly() {
        guard isVisible else { return }
        scheduleHide()
    }

    func dismiss() {
        revealTask?.cancel()
        hideTask?.cancel()
        withAnimation(motion(.spring(response: 0.40, dampingFraction: 0.87))) {
            phase = .idle
        }
    }

    private func present(expanded: Bool) {
        revealTask?.cancel()
        hideTask?.cancel()
        if phase == .idle {
            withAnimation(motion(.easeOut(duration: 0.16))) {
                phase = .spark
            }
            revealTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }
                withAnimation(motion(.spring(response: 0.52, dampingFraction: 0.76))) {
                    phase = expanded ? .expanded : .compact
                }
                scheduleHide()
            }
        } else {
            withAnimation(motion(.spring(response: 0.48, dampingFraction: 0.82))) {
                phase = expanded ? .expanded : .compact
            }
            scheduleHide()
        }
    }

    private func motion(_ animation: Animation) -> Animation {
        UIAccessibility.isReduceMotionEnabled ? .easeOut(duration: 0.12) : animation
    }

    private func scheduleHide() {
        hideTask?.cancel()
        let duration: Duration = phase == .expanded ? .seconds(8) : .seconds(4)
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }
}

/// Position this at the very same top-leading screen anchor as the native
/// BBT-Bit toolbar logo. Scale from that point; do not overlay the center
/// of the screen or leave a second always-visible player there.
struct LogoGlassBloomIsland: View {
    @Environment(PlaybackController.self) private var controller
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var bloom = LogoGlassBloomCoordinator.shared

    private var reduceBlur: Bool {
        // Follow the same user preference as the native mini-player.
        UserDefaults.standard.bool(forKey: "reduce_dynamic_blur")
    }

    private var isSpark: Bool { bloom.phase == .spark }
    private var isExpanded: Bool { bloom.phase == .expanded }
    private var width: CGFloat { isSpark ? 46 : (isExpanded ? 292 : 252) }
    private var radius: CGFloat { isSpark ? 23 : 25 }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 10 : 6) {
            header
            if isExpanded {
                GlassBloomStatusRow(playing: controller.isPlaying)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                Rectangle()
                    .fill(.white.opacity(0.13))
                    .frame(height: 0.5)
                    .accessibilityHidden(true)
                transport
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                quickRoutes
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                GlassBloomSwipeHint()
                    .padding(.top, 1)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, isSpark ? 8 : 12)
        .padding(.vertical, isSpark ? 11 : 10)
        .frame(width: width, alignment: .leading)
        .frame(minHeight: 46)
        // The glass itself supplies highlights and edge treatment.
        // Cover colors and animated cyan/purple overlays obscured that layer.
        .background { glassSurface }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .fixedSize(horizontal: true, vertical: true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 32)
                .onEnded { handleSwipe($0.translation) }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bbt.logoGlassBloom")
        .background { LiquidLiveCaptureMarker(id: "island") }
        .onChange(of: bloom.phase) { _, newPhase in
            if newPhase == .expanded {
                LiquidLiveCaptureMarker.refresh("island")
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                #endif
            }
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            if isSpark {
                Image(.bchLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 29, height: 22)
                    .frame(width: 30, height: 24)
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
            } else {
                Button {
                    if isExpanded { bloom.dismiss() }
                    else { bloom.expand() }
                } label: {
                    ArtworkView(entry: controller.current, side: 38)
                        .id(controller.current?.id)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Glass Bloom schließen" : "Music Island erweitern")
                VStack(alignment: .leading, spacing: 3) {
                    Text(controller.current?.title ?? "Musik")
                        .font(.caption.weight(.semibold))
                        .contentTransition(.opacity)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(controller.current?.artist ?? "")
                        .font(.caption2)
                        .contentTransition(.opacity)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isExpanded {
                    Button { bloom.collapse() } label: {
                        Image(systemName: "chevron.up")
                            .frame(width: 30, height: 38)
                    }
                    .accessibilityLabel("Glass Bloom einklappen")
                } else {
                    Button {
                        controller.togglePlayPause()
                        bloom.keepOpenBriefly()
                    } label: {
                        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(.primary)
                            .frame(width: 33, height: 40)
                    }
                    .accessibilityLabel(controller.isPlaying ? "Pause" : "Wiedergabe")
                }
            }
        }
        .frame(minHeight: isSpark ? 24 : 40)
        .contentShape(Rectangle())
    }

    private var transport: some View {
        HStack(spacing: 0) {
            playbackControl("backward.fill", label: "Vorheriger Titel",
                            enabled: controller.canPlayPrevious) {
                controller.previous()
            }
            playbackControl(controller.isPlaying ? "pause.fill" : "play.fill",
                            label: controller.isPlaying ? "Pause" : "Wiedergabe",
                            enabled: true) {
                controller.togglePlayPause()
            }
            playbackControl("forward.fill", label: "Nächster Titel",
                            enabled: controller.canPlayNext) {
                controller.next()
            }
            playbackControl("arrow.up.left.and.arrow.down.right", label: "Vollbild-Player öffnen",
                            enabled: true) {
                bloom.dismiss()
                appModel.nowPlayingPresented = true
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, 3)
    }

    private var quickRoutes: some View {
        HStack(spacing: 9) {
            Button {
                openQuickPane(lyrics: true)
            } label: {
                Label("Lyrics", systemImage: "text.quote")
                    .frame(maxWidth: .infinity, minHeight: 34)
            }
            .accessibilityIdentifier("bbt.glassBloom.lyrics")
            Button {
                openQuickPane(lyrics: false)
            } label: {
                Label("Queue", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity, minHeight: 34)
            }
            .accessibilityIdentifier("bbt.glassBloom.queue")
        }
        .font(.caption.weight(.medium))
        .buttonStyle(.plain)
        .padding(.top, 2)

    }

    private func openQuickPane(lyrics: Bool) {
        bloom.dismiss()
        appModel.nowPlayingPresented = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            if lyrics {
                appModel.lyricsRevealRequested = true
            } else {
                appModel.queueRevealRequested = true
            }
        }
    }

    private func handleSwipe(_ translation: CGSize) {
        let horizontal = abs(translation.width) > abs(translation.height) * 1.3
        if horizontal && abs(translation.width) > 60 && !PartyStore.shared.state.controlsLocked {
            if translation.width < 0 && controller.canPlayNext {
                controller.next()
                bloom.keepOpenBriefly()
            } else if translation.width > 0 && controller.canPlayPrevious {
                controller.previous()
                bloom.keepOpenBriefly()
            }
        } else if translation.height < -55 {
            bloom.expand()
        } else if translation.height > 55 {
            if isExpanded {
                bloom.collapse()
            } else {
                bloom.dismiss()
            }
        }
    }

    private func playbackControl(
        _ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            if label != "Vollbild-Player öffnen" {
                bloom.keepOpenBriefly()
            }
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var glassSurface: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if reduceTransparency || reduceBlur {
            shape.fill(Theme.Materials.opaque)
        } else if #available(iOS 26.0, *) {
            shape.fill(.clear).glassEffect(.regular, in: shape)
        } else {
            shape.fill(.regularMaterial)
        }
    }
}
#endif
