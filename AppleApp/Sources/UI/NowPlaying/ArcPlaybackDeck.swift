import SwiftUI

/// Bogensteuerung aus der Referenz, direkt an dieselbe Wiedergabesitzung gebunden.
struct ArcPlaybackDeck<More: View>: View {
    var onLyrics: () -> Void
    var onQueue: () -> Void
    let more: More
    @Environment(PlaybackController.self) private var controller
    @Environment(PartyStore.self) private var party
    @Environment(AuthController.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragProgress: Double? = nil

    private var progress: Double {
        if let dragProgress { return dragProgress }
        guard controller.duration.isFinite, controller.duration > 0 else { return 0 }
        return ArcPlaybackGeometry.clamp(controller.position / controller.duration)
    }

    var body: some View {
        GeometryReader { proxy in
            let geometry = ArcPlaybackGeometry(size: proxy.size)
            ZStack {
                Canvas { context, _ in draw(&context, geometry: geometry) }
                    .accessibilityHidden(true)
                ArcSeekBand()
                    .fill(.clear)
                    .contentShape(ArcSeekBand())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($dragProgress) { value, state, _ in
                                guard !party.state.controlsLocked, controller.duration.isFinite,
                                      controller.duration > 0 else { return }
                                state = geometry.progress(at: value.location)
                            }
                            .onEnded { value in seek(geometry.progress(at: value.location)) }
                    )
                    .accessibilityElement()
                    .accessibilityLabel("Playback position")
                    .accessibilityValue(NowPlayingView.timestamp(controller.position))
                    .accessibilityAdjustableAction { direction in
                        let delta: Double
                        switch direction {
                        case .increment: delta = 5
                        case .decrement: delta = -5
                        @unknown default: return
                        }
                        guard controller.duration > 0 else { return }
                        seek((controller.position + delta) / controller.duration)
                    }
                    .accessibilityIdentifier("bbt.player.arc.seek")

                control("shuffle", label: "Shuffle", selected: controller.shuffleEnabled, changesPlayback: true) {
                    controller.toggleShuffle()
                }.position(controlPoint(0, geometry))
                control(controller.isLiked ? "heart.fill" : "heart", label: "Like",
                        selected: controller.isLiked,
                        enabled: auth.signedIn && controller.current?.videoId != nil) {
                    controller.toggleLike()
                }
                .modifier(FavoriteStarConfirmation(videoID: controller.current?.videoId))
                .position(controlPoint(1, geometry))
                control("quote.bubble", label: "Lyrics", action: onLyrics)
                    .position(controlPoint(2, geometry))
                control(controller.isPlaying ? "pause.fill" : "play.fill", label: controller.isPlaying ? "Pause" : "Play",
                        enabled: controller.current != nil || controller.isBuffering, changesPlayback: true) {
                    controller.togglePlayPause()
                }
                .accessibilityIdentifier("bbt.nowPlaying.play")
                .position(controlPoint(3, geometry))
                control("list.bullet", label: "Queue", action: onQueue)
                    .position(controlPoint(4, geometry))
                control(controller.repeatMode == .one ? "repeat.1" : "repeat", label: "Repeat",
                        selected: controller.repeatMode != .off, changesPlayback: true) {
                    controller.cycleRepeat()
                }.position(controlPoint(5, geometry))
                more.position(controlPoint(6, geometry))

                control("backward.end.fill", label: "Previous track", enabled: controller.canPlayPrevious, changesPlayback: true) {
                    controller.previous()
                }
                .background(.thinMaterial, in: Circle())
                .position(x: proxy.size.width * 0.27, y: geometry.center.y - 13)
                Text(NowPlayingView.timestamp(dragProgress == nil ? controller.position : progress * controller.duration))
                    .font(.system(.body, design: .serif).monospacedDigit())
                    .foregroundStyle(.white)
                    .position(x: geometry.center.x, y: geometry.center.y - 13)
                    .accessibilityHidden(true)
                control("forward.end.fill", label: "Next track", enabled: controller.canPlayNext, changesPlayback: true) {
                    controller.next()
                }
                .background(.thinMaterial, in: Circle())
                .position(x: proxy.size.width * 0.73, y: geometry.center.y - 13)
                if controller.automixEnabled, controller.smartTransitionWindow != nil || controller.smartMixInProgress {
                    let window = controller.smartTransitionWindow ?? TransitionWindow(start: 0, end: 0)
                    AutomixWeave(start: window.start, end: window.end,
                        position: controller.position, tier: controller.analysisTier,
                        reason: controller.transitionReason, isMixing: controller.smartMixInProgress)
                        .frame(maxWidth: 170)
                        .position(x: geometry.center.x, y: geometry.center.y + 16)
                }
            }
        }
        .aspectRatio(1.48, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bbt.player.arc")
    }

    private func seek(_ progress: Double) {
        guard !party.state.controlsLocked,
              let seconds = ArcPlaybackGeometry.seconds(progress: progress, duration: controller.duration) else { return }
        controller.seek(to: seconds)
    }

    private func control(_ symbol: String, label: String, selected: Bool = false,
                         enabled: Bool = true, changesPlayback: Bool = false,
                         action: @escaping () -> Void) -> some View {
        Button {
            guard !changesPlayback || !party.state.controlsLocked else { return }
            Haptics.play(.tap)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(selected ? Theme.accent : .white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled || (changesPlayback && party.state.controlsLocked))
        .accessibilityLabel(Text(LocalizedStringKey(label)))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func controlPoint(_ index: Int, _ geometry: ArcPlaybackGeometry) -> CGPoint {
        geometry.point(progress: (Double(index) * 20 + 10) / 140, radius: geometry.controlsRadius)
    }

    private func draw(_ context: inout GraphicsContext, geometry: ArcPlaybackGeometry) {
        var band = Path()
        band.addArc(center: geometry.center, radius: geometry.controlsRadius + 22,
                    startAngle: .degrees(-160), endAngle: .degrees(-20), clockwise: false)
        band.addArc(center: geometry.center, radius: geometry.controlsRadius - 22,
                    startAngle: .degrees(-20), endAngle: .degrees(-160), clockwise: true)
        band.closeSubpath()
        context.fill(band, with: .color(.white.opacity(0.035)))
        context.stroke(band, with: .color(.white.opacity(0.22)), lineWidth: 0.7)
        for index in 1..<7 {
            let value = Double(index) / 7
            var divider = Path()
            divider.move(to: geometry.point(progress: value, radius: geometry.controlsRadius - 22))
            divider.addLine(to: geometry.point(progress: value, radius: geometry.controlsRadius + 22))
            context.stroke(divider, with: .color(.white.opacity(0.16)), lineWidth: 0.7)
        }
        for index in 0...70 {
            let value = Double(index) / 70
            // RED-Morph-Sound-Ribbon: nur während des Ziehens am echten Zeitwert.
            let focus = ScrubFocusGeometry.emphasis(at: value, focus: progress,
                scrubbing: dragProgress != nil, reducedMotion: reduceMotion)
            let length = (index.isMultiple(of: 5) ? 10.0 : 4.0) + 12 * focus
            var tick = Path()
            tick.move(to: geometry.point(progress: value, radius: geometry.radius))
            tick.addLine(to: geometry.point(progress: value, radius: geometry.radius - CGFloat(length)))
            context.stroke(tick, with: .color(.white.opacity(max(value <= progress ? 0.65 : 0.22, focus * 0.9))),
                           lineWidth: CGFloat(1 + focus))
        }
        var needle = Path()
        needle.move(to: geometry.point(progress: progress, radius: geometry.radius - 25))
        needle.addLine(to: geometry.point(progress: progress, radius: geometry.radius + 6))
        context.stroke(needle, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

private struct ArcSeekBand: Shape {
    func path(in rect: CGRect) -> Path {
        let geometry = ArcPlaybackGeometry(size: rect.size)
        var path = Path()
        path.addArc(center: geometry.center, radius: geometry.radius + 17,
                    startAngle: .degrees(-160), endAngle: .degrees(-20), clockwise: false)
        path.addArc(center: geometry.center, radius: max(1, geometry.radius - 27),
                    startAngle: .degrees(-20), endAngle: .degrees(-160), clockwise: true)
        path.closeSubpath()
        return path
    }
}
