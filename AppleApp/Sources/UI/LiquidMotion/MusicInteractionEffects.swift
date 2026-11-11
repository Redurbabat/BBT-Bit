import SwiftUI
import Observation

/// Ein gemeinsamer, bestätigter Speichermarker; keine optimistische Erfolgsanimation.
@MainActor @Observable final class MusicConfirmation {
    static let shared = MusicConfirmation()
    private(set) var videoID: String?
    private(set) var revision = 0
    func savedFavorite(_ id: String) { videoID = id; revision &+= 1 }
}

struct FavoriteStarConfirmation: ViewModifier {
    let videoID: String?
    @State private var confirmation = MusicConfirmation.shared
    @State private var expanded = false
    @State private var burstRevision = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if expanded {
                ZStack {
                    ForEach(0..<8) { index in
                        let angle = Double(index) * .pi / 4
                        Image(systemName: "sparkle").font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .offset(x: cos(angle) * 30, y: sin(angle) * 30)
                    }
                }
                .transition(reduceMotion ? .opacity : .scale(scale: 0.35).combined(with: .opacity))
                .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .onChange(of: confirmation.revision) { _, revision in
            if let videoID, confirmation.videoID == videoID { burstRevision = revision }
        }
        .task(id: burstRevision) {
            guard burstRevision > 0 else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) { expanded = true }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) { expanded = false }
        }
    }
}

/// Zoom bleibt Teil der vorhandenen Navigation und bewahrt deren Rückweg.
struct NativeCardZoomLink<Destination: View, Label: View>: View {
    let id: String
    @ViewBuilder var destination: Destination
    @ViewBuilder var label: Label
    @Namespace private var zoom
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        #if os(iOS)
        PushLink {
            if reduceMotion { destination }
            else { destination.navigationTransition(.zoom(sourceID: id, in: zoom)) }
        } label: {
            label.matchedTransitionSource(id: id, in: zoom)
        }.buttonStyle(.plain)
        #else
        PushLink(destination: destination) { label }.buttonStyle(.plain)
        #endif
    }
}

/// Die Cover fächern sich aus dem Stapel auf: Stapel und Reihe teilen dieselbe
/// Identität je Cover, daher fliegt jedes Cover an seinen Platz, statt umzuspringen.
struct PlaylistCoverFan: View {
    let entries: [QueueEntry]
    let onSelect: (Int) -> Void
    @State private var expanded = false
    @Namespace private var fan
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PartyStore.self) private var party

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(expanded ? "Close cover fan" : "Explore playlist covers")
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "rectangle.stack")
                        .contentTransition(.symbolEffect(.replace))
                }.frame(minHeight: 44)
            }.buttonStyle(.plain).accessibilityIdentifier("red.playlist.fan.toggle")
            if expanded {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(entries.prefix(8).enumerated()), id: \.offset) { index, entry in
                            Button { onSelect(index) } label: {
                                VStack(spacing: 8) {
                                    ArtworkView(entry: entry, side: 100).clipShape(.rect(cornerRadius: 12))
                                        .matchedGeometryEffect(id: index, in: fan)
                                        .rotationEffect(reduceMotion ? .zero : .degrees(fanTilt(index)))
                                        .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
                                    Text(entry.title).font(.caption).lineLimit(2).frame(width: 100)
                                }.padding(.vertical, 8)
                            }.buttonStyle(.plain).disabled(party.state.controlsLocked)
                                .accessibilityLabel("Play track: \(entry.title)")
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }.padding(.horizontal, 8)
                }
            } else if !entries.isEmpty {
                // Echte Layoutabstände statt Versatz, damit der Flug am richtigen Ort beginnt.
                HStack(spacing: -62) {
                    ForEach(Array(entries.prefix(4).enumerated()), id: \.offset) { index, entry in
                        ArtworkView(entry: entry, side: 82).clipShape(.rect(cornerRadius: 10))
                            .matchedGeometryEffect(id: index, in: fan)
                            .rotationEffect(reduceMotion ? .zero : .degrees(stackTilt(index)))
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                            .zIndex(Double(-index))
                    }
                }.frame(height: 105).accessibilityHidden(true).allowsHitTesting(false)
            }
        }.padding(.horizontal, 24)
    }

    private func stackTilt(_ index: Int) -> Double { Double(index - 1) * 10 }
    private func fanTilt(_ index: Int) -> Double { Double(index % 3 - 1) * 5 }
}

/// Das Licht folgt dem gemeldeten Mix-Fenster. Geplante Übergänge bleiben statisch.
/// Während des Mischens tritt das alte Cover zurück, das neue nach vorn, und die
/// Lichtpunkte laufen auf den tatsächlichen Fäden hinüber.
struct AutomixLightBridge: View {
    let current: QueueEntry?
    let next: QueueEntry?
    let progress: Double
    let isMixing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var phase: Double { isMixing ? MusicMotionGeometry.progress(progress) : 0 }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    drawThreads(in: &context, size: size)
                }.accessibilityHidden(true)
                HStack {
                    ArtworkView(entry: current, side: 64).clipShape(.rect(cornerRadius: 12))
                        .scaleEffect(CGFloat(1 - 0.12 * phase))
                        .opacity(1 - 0.45 * phase)
                    Spacer()
                    ArtworkView(entry: next, side: 64).clipShape(.rect(cornerRadius: 12))
                        .scaleEffect(CGFloat(0.88 + 0.12 * phase))
                        .opacity(isMixing ? 0.55 + 0.45 * phase : 1)
                }
                VStack {
                    Spacer()
                    Text(isMixing ? "Crossfade in progress" : "Transition planned")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: 156).accessibilityElement(children: .combine)
    }

    private func drawThreads(in context: inout GraphicsContext, size: CGSize) {
        let a = CGPoint(x: 42, y: size.height / 2)
        let b = CGPoint(x: size.width - 42, y: size.height / 2)
        let swell: Double = 1 + 0.35 * sin(phase * .pi)
        let outgoing: Double = 0.15 + 0.45 * (1 - phase)
        let incoming: Double = 0.25 + 0.5 * phase
        let gradient = Gradient(colors: [Theme.accent.opacity(outgoing), .orange.opacity(incoming)])
        for index in 0..<18 {
            let spread: Double = Double(index - 9) * 5 * swell
            let c1 = CGPoint(x: size.width * 0.35, y: size.height / 2 + spread)
            let c2 = CGPoint(x: size.width * 0.65, y: size.height / 2 - spread)
            var path = Path()
            path.move(to: a)
            path.addCurve(to: b, control1: c1, control2: c2)
            let width: CGFloat = index.isMultiple(of: 3) ? 1.5 : 0.6
            context.stroke(path, with: .linearGradient(gradient, startPoint: a, endPoint: b), lineWidth: width)
            guard isMixing, !reduceMotion else { continue }
            let point = bezier(a, c1, c2, b, t: CGFloat(phase))
            let glow: Double = 0.45 + 0.4 * sin(phase * .pi)
            context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)),
                         with: .color(.primary.opacity(glow)))
        }
    }

    /// Punkt auf einer kubischen Bézierkurve; die Lichtpunkte folgen damit exakt dem Faden.
    private func bezier(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, t: CGFloat) -> CGPoint {
        let u: CGFloat = 1 - t
        let w0: CGFloat = u * u * u
        let w1: CGFloat = 3 * u * u * t
        let w2: CGFloat = 3 * u * t * t
        let w3: CGFloat = t * t * t
        let x: CGFloat = w0 * p0.x + w1 * p1.x + w2 * p2.x + w3 * p3.x
        let y: CGFloat = w0 * p0.y + w1 * p1.y + w2 * p2.y + w3 * p3.y
        return CGPoint(x: x, y: y)
    }
}

struct DownloadTransferScene: View {
    @State private var store = DownloadStore.shared
    @State private var known: Set<String> = []
    @State private var ready = false
    @State private var saved: QueueEntry?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var completed: Set<String> { Set(store.jobs.filter { $0.status == .done }.map(\.id)) }
    private var active: Int { store.jobs.filter { $0.status == .running || $0.status == .queued }.count }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 18) {
                if let saved {
                    ArtworkView(entry: saved, side: 48).clipShape(.rect(cornerRadius: 10))
                        .id(saved.id)
                        .transition(reduceMotion ? .opacity : .offset(x: -45).combined(with: .opacity))
                } else {
                    Image(systemName: "arrow.down").frame(width: 48, height: 48).foregroundStyle(.secondary)
                }
                Image(systemName: "arrow.right").foregroundStyle(.secondary).accessibilityHidden(true)
                Image(systemName: "square.stack.fill").font(.title).foregroundStyle(Theme.accent)
            }.frame(height: 64).accessibilityHidden(true)
            if let saved {
                Label("Available offline: \(saved.title)", systemImage: "checkmark.circle.fill")
                    .font(.callout).lineLimit(2)
            } else {
                Text("Your offline collection").font(.headline)
            }
            if active > 0 {
                HStack { ProgressView().controlSize(.small); Text("\(active) downloads active").font(.caption) }
            }
        }
        .frame(maxWidth: .infinity).padding(16)
        .onAppear { known = completed; ready = true }
        .task(id: completed) {
            guard ready else { return }
            let newIDs = completed.subtracting(known)
            known = completed
            guard let job = store.jobs.last(where: { newIDs.contains($0.id) }) else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.85)) { saved = job.entry }
        }
    }
}

struct SleepEclipseView: View {
    @Environment(PlaybackController.self) private var controller
    private var remaining: Double {
        if controller.sleepAfterTrack {
            return 1 - MusicMotionGeometry.progress(controller.position / max(1, controller.duration))
        }
        guard let total = controller.sleepDurationSeconds, total > 0 else { return 0 }
        return MusicMotionGeometry.progress(Double(controller.sleepSecondsRemaining ?? 0) / total)
    }

    var body: some View {
        if controller.sleepTimerStatus != nil {
            HStack(spacing: 12) {
                EclipseMoon(remaining: remaining)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sleep timer").font(.caption)
                    Text(controller.sleepAfterTrack ? AppLanguage.localized("After this song") : controller.sleepTimerStatus ?? "")
                        .font(.callout.monospacedDigit())
                }
                Spacer()
                Button("Cancel timer") { controller.cancelSleep() }.frame(minHeight: 44)
            }
            .padding(.horizontal, 24).padding(.vertical, 6)
            .accessibilityElement(children: .contain)
        }
    }
}

struct EclipseMoon: View {
    let remaining: Double
    var body: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.85))
            Circle().fill(.black).offset(x: 44 * MusicMotionGeometry.progress(remaining))
        }.frame(width: 44, height: 44).clipShape(Circle()).accessibilityHidden(true)
    }
}
