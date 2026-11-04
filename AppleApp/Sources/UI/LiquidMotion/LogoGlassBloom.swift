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
    @State private var bloom = LogoGlassBloomCoordinator.shared

    private var isSpark: Bool { bloom.phase == .spark }
    private var isExpanded: Bool { bloom.phase == .expanded }
    private var width: CGFloat { isSpark ? 46 : (isExpanded ? 292 : 252) }
    private var radius: CGFloat { isSpark ? 23 : 25 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if isExpanded {
                transport
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, isSpark ? 8 : 12)
        .padding(.vertical, isSpark ? 11 : 10)
        .frame(width: width, alignment: .leading)
        .frame(minHeight: 46)
        .background { glassSurface }
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.32), .cyan.opacity(0.32), .purple.opacity(0.16)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        }
        .overlay(alignment: .topLeading) {
            if isSpark {
                Circle()
                    .stroke(.cyan.opacity(0.55), lineWidth: 1.5)
                    .padding(-4)
                    .allowsHitTesting(false)
            }
        }
        .shadow(color: .purple.opacity(0.12), radius: 24, y: 9)
        .shadow(color: .black.opacity(0.21), radius: 12, y: 6)
        .fixedSize(horizontal: true, vertical: true)
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
                    .foregroundStyle(.cyan)
                    .accessibilityHidden(true)
            } else {
                Button {
                    if isExpanded { bloom.dismiss() }
                    else { bloom.expand() }
                } label: {
                    ArtworkView(entry: controller.current, side: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Glass Bloom schließen" : "Music Island erweitern")
                VStack(alignment: .leading, spacing: 3) {
                    Text(controller.current?.title ?? "Musik")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(controller.current?.artist ?? "")
                        .font(.caption2)
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
                            .foregroundStyle(.cyan)
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
        if #available(iOS 26.0, *) {
            shape
                .fill(Color.black.opacity(0.10))
                .glassEffect(.regular, in: shape)
        } else {
            shape.fill(.ultraThinMaterial)
        }
    }
}
#endif
