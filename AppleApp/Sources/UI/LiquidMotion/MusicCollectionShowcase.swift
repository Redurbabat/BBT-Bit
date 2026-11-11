import SwiftUI

enum CollectionShowcaseStyle { case galaxy, records }

/// Cover aus der bereits geladenen Sammlung. Auswahl und Navigation bleiben getrennt.
struct MusicCollectionShowcase: View {
    let items: [ShelfCard]
    var style: CollectionShowcaseStyle = .galaxy
    var preferTrack = false
    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Fortlaufende Position ohne Umbruch: Platten und Galaxie drehen beim
    /// Wechsel über den Rand weiter, statt quer zurückzuspringen.
    @State private var selectedIndex = 0
    /// 1 = Platte ragt aus der Hülle, 0 = eingeschoben (während des Wechsels).
    @State private var vinylOut: CGFloat = 1
    /// Kurzes Dehnen der Glasbühne in Bewegungsrichtung, wie beim Dock.
    @State private var glassStretch: CGFloat = 0
    /// Finger-Drehung der Galaxie oder Fingerweg im Plattenregal.
    @State private var dragShift: CGFloat = 0

    private var index: Int { MusicMotionGeometry.wrapped(selectedIndex, count: items.count) }
    private var selection: ShelfCard? { items.indices.contains(index) ? items[index] : nil }
    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.84) }

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 12) {
                if reduceMotion || typeSize.isAccessibilitySize {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(items) { ShelfCardView(card: $0, artworkSide: 130, preferTrack: preferTrack) }
                        }.padding(.horizontal, 8)
                    }
                } else {
                    GeometryReader { proxy in
                        ZStack {
                            if style == .galaxy {
                                galaxy(size: proxy.size)
                            } else {
                                records(size: proxy.size)
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture(minimumDistance: 16)
                            .onChanged { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                dragShift = value.translation.width
                            }
                            .onEnded { value in
                                let horizontal = abs(value.translation.width) > abs(value.translation.height) * 1.3
                                let travel = value.translation.width + (value.predictedEndTranslation.width - value.translation.width) * 0.3
                                let unit: CGFloat = style == .galaxy ? 90 : 110
                                var steps = Int((-travel / unit).rounded())
                                if horizontal, steps == 0, abs(value.translation.width) > 30 {
                                    steps = value.translation.width < 0 ? 1 : -1
                                }
                                if horizontal, steps != 0 {
                                    move(max(-3, min(3, steps)))
                                } else {
                                    withAnimation(spring) { dragShift = 0 }
                                }
                            })
                    }
                    .frame(height: style == .galaxy ? 300 : 250)
                    if let selection {
                        VStack(spacing: 4) {
                            Text(selection.title).font(.headline).lineLimit(2).multilineTextAlignment(.center)
                            if let subtitle = selection.subtitle {
                                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        .id(selection.id)
                        .transition(.opacity.combined(with: .offset(y: 6)))
                    }
                    HStack(spacing: 14) {
                        navigationButton("Previous collection", symbol: "chevron.left", step: -1)
                        Text("\(index + 1) / \(items.count)")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .accessibilityLabel("Collection \(index + 1) of \(items.count)")
                        navigationButton("Next collection", symbol: "chevron.right", step: 1)
                    }
                    .padding(.horizontal, 6)
                    .modifier(ShowcaseGlass(shape: Capsule()))
                }
            }
            .onChange(of: items.map(\.id)) { _, _ in selectedIndex = min(index, max(0, items.count - 1)) }
            .accessibilityElement(children: .contain)
        }
    }

    private func navigationButton(_ label: LocalizedStringKey, symbol: String, step: Int) -> some View {
        Button { move(step) } label: {
            Image(systemName: symbol).frame(width: 44, height: 44).contentShape(Circle())
        }
        .buttonStyle(.plain).accessibilityLabel(Text(label)).disabled(items.count < 2)
        .accessibilityIdentifier(step < 0 ? "red.collection.previous" : "red.collection.next")
    }

    /// Wechsel in drei Takten: Platte gleitet in die Hülle, Hüllen und Glasbühne
    /// ziehen weiter, dann rollt die neue Platte wieder heraus.
    private func move(_ step: Int) {
        guard items.count > 1, step != 0 else {
            withAnimation(spring) { dragShift = 0 }
            return
        }
        guard !reduceMotion else {
            selectedIndex += step
            dragShift = 0
            return
        }
        withAnimation(.easeIn(duration: 0.12)) {
            vinylOut = 0
            glassStretch = step > 0 ? 1 : -1
        } completion: {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.76)) {
                vinylOut = 1
                glassStretch = 0
            }
        }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
            selectedIndex += step
            dragShift = 0
        }
    }

    /// Sichtbare Nachbarn ohne doppelte Cover bei kleinen Sammlungen.
    private var recordDeltas: [Int] {
        var seen: Set<Int> = [index]
        return [0] + [1, -1, 2, -2].filter {
            seen.insert(MusicMotionGeometry.wrapped(index + $0, count: items.count)).inserted
        }
    }

    // MARK: Musikgalaxie

    private func galaxy(size: CGSize) -> some View {
        let neighbours = MusicMotionGeometry.neighbours(selected: index, count: items.count)
        let step = 2 * Double.pi / Double(max(1, neighbours.count))
        // Die Scheibe dreht mit der Auswahl und folgt live dem Finger.
        let follow: Double = Double(dragShift) / 90 * step
        let turn: Double = -Double(selectedIndex) * step + follow
        return ZStack {
            GalaxyBackdrop(rotation: turn * 0.6, tint: Theme.accent)
                .accessibilityHidden(true).allowsHitTesting(false)
            ForEach(Array(neighbours.enumerated()), id: \.element) { slot, itemIndex in
                Button {
                    move(slot + 1)
                } label: {
                    ArtworkView(url: items[itemIndex].thumbnailUrl, data: nil, side: 52)
                        .frame(width: 52, height: 52).clipShape(.rect(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.25), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Focus collection: \(items[itemIndex].title)")
                .modifier(OrbitPlacement(angle: orbitAngle(slot: slot, step: step), size: size))
                .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
            if let selection {
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: min(150, size.width * 0.44), height: min(150, size.width * 0.44))
                        .modifier(ShowcaseGlass(shape: Circle()))
                        .scaleEffect(1 + abs(glassStretch) * 0.08)
                    collectionLink(selection, side: min(112, size.width * 0.33))
                }
                .id(selection.id)
                .transition(.asymmetric(insertion: .scale(scale: 0.45).combined(with: .opacity),
                                        removal: .scale(scale: 0.6).combined(with: .opacity)))
                .position(x: size.width / 2, y: size.height / 2)
                .zIndex(5)
            }
        }
    }

    private func orbitAngle(slot: Int, step: Double) -> Double {
        let follow: Double = Double(dragShift) / 90 * step
        return -Double.pi / 2 + Double(slot) * step + follow
    }

    // MARK: Plattenregal

    private func records(size: CGSize) -> some View {
        let side = min(176, size.width * 0.48)
        return ZStack {
            // Glasbühne wie beim Dock: dehnt sich kurz in Bewegungsrichtung.
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.clear)
                .frame(width: stageWidth(size: size, side: side), height: side * 0.42)
                .modifier(ShowcaseGlass(shape: RoundedRectangle(cornerRadius: 30, style: .continuous)))
                .offset(x: glassStretch * side * 0.08, y: side * 0.5)
                .accessibilityHidden(true)
            ForEach(recordDeltas.map { selectedIndex + $0 }, id: \.self) { virtual in
                let itemIndex = MusicMotionGeometry.wrapped(virtual, count: items.count)
                // Ein fester Container je Regalplatz: Er gleitet und dreht sich,
                // während innen nur die Rolle (Link oder Auswahl) überblendet.
                ZStack {
                    if virtual == selectedIndex {
                        collectionLink(items[itemIndex], side: side, vinyl: true)
                    } else {
                        Button { move(virtual - selectedIndex) } label: {
                            ArtworkView(url: items[itemIndex].thumbnailUrl, data: nil, side: side)
                                .frame(width: side, height: side).clipShape(.rect(cornerRadius: 12))
                                .overlay(SleeveSheen().clipShape(.rect(cornerRadius: 12)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Focus collection: \(items[itemIndex].title)")
                    }
                }
                .modifier(RecordPlacement(delta: CGFloat(virtual - selectedIndex) + dragShift / 110, side: side))
                .zIndex(Double(4 - abs(virtual - selectedIndex)))
                .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func stageWidth(size: CGSize, side: CGFloat) -> CGFloat {
        let base: CGFloat = min(size.width - 8, side * 2.1)
        let stretch: CGFloat = 1 + abs(glassStretch) * 0.12
        return base * stretch
    }

    private func collectionLink(_ card: ShelfCard, side: CGFloat, vinyl: Bool = false) -> some View {
        ShelfCardTap(card: card, preferTrack: preferTrack) {
            ZStack {
                if vinyl {
                    VinylRecord(artworkURL: card.thumbnailUrl, side: side * 0.93, isCurrent: recordIsCurrent(card))
                        .rotationEffect(.degrees(Double(1 - vinylOut) * -70))
                        .offset(x: side * 0.27 * vinylOut)
                }
                ArtworkView(url: card.thumbnailUrl, data: nil, side: side)
                    .frame(width: side, height: side).clipShape(.rect(cornerRadius: 14))
                    .overlay(SleeveSheen(phase: glassStretch).clipShape(.rect(cornerRadius: 14)))
                    .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
            }
            .frame(width: side, height: side)
            .accessibilityLabel(card.title)
        }
        .contextMenu { ShelfCardActionButtons(card: card) }
    }

    private func recordIsCurrent(_ card: ShelfCard) -> Bool {
        guard let current = controller.current else { return false }
        if let videoID = card.videoId, videoID == current.videoId { return true }
        return current.albumName == card.title && !current.artist.isEmpty
            && (card.subtitle?.localizedCaseInsensitiveContains(current.artist) ?? false)
    }
}

/// Liquid Glass wie im Dock; ohne iOS 26 Material, bei reduzierter Transparenz deckend.
private struct ShowcaseGlass<S: Shape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(.background.secondary, in: shape)
        } else if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

/// Lage einer Hülle im Regal; `delta` wird von SwiftUI interpoliert, die Hülle
/// dreht sich dabei stufenlos aus der Front in die Seitenlage.
private struct RecordPlacement: ViewModifier, Animatable {
    var delta: CGFloat
    let side: CGFloat

    var animatableData: CGFloat {
        get { delta }
        set { delta = newValue }
    }

    func body(content: Content) -> some View {
        let distance: CGFloat = min(2.4, abs(delta))
        let direction: CGFloat = delta < 0 ? -1 : 1
        let near: CGFloat = min(1, distance)
        let far: CGFloat = max(0, distance - 1)
        let reach: CGFloat = near * side * 0.6 + far * side * 0.32
        let angle: Double = Double(-direction * near * 42)
        let scale: CGFloat = 1 - near * 0.2 - far * 0.12
        let opacity: Double = Double(1 - far * 0.5)
        content
            .rotation3DEffect(.degrees(angle), axis: (0, 1, 0), perspective: 0.6)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: direction * reach, y: near * 8)
    }
}

/// Lichtkante auf der Hülle, die beim Wechsel wie über Glas wandert.
private struct SleeveSheen: View {
    var phase: CGFloat = 0

    var body: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.22), .clear],
                       startPoint: UnitPoint(x: 0.1 + phase * 0.4, y: 0), endPoint: UnitPoint(x: 0.6 + phase * 0.4, y: 1))
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
}

/// Umlaufbahn mit Tiefe: hintere Cover werden kleiner und blasser. Der Winkel
/// wird interpoliert, damit Cover entlang der Bahn wandern statt quer zu springen.
struct OrbitPlacement: ViewModifier, Animatable {
    var angle: Double
    let size: CGSize

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        let orbit = MusicMotionGeometry.tiltedOrbit(angle: angle, size: size)
        let scale = CGFloat(0.72 + orbit.depth * 0.42)
        let opacity: Double = 0.45 + orbit.depth * 0.55
        let shade: Double = 0.25 * orbit.depth
        let layer: Double = orbit.depth > 0.75 ? 6 : orbit.depth
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: .black.opacity(shade), radius: 6, y: 4)
            .position(orbit.point)
            .zIndex(layer)
    }
}

/// Zweiarmige Spiralgalaxie mit Kern; die Drehung ist animierbar.
struct GalaxyBackdrop: View, Animatable {
    var rotation: Double
    let tint: Color

    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            context.fill(Path(ellipseIn: CGRect(x: centre.x - size.width * 0.42, y: centre.y - size.height * 0.30,
                                                width: size.width * 0.84, height: size.height * 0.60)),
                         with: .radialGradient(Gradient(colors: [tint.opacity(0.22), tint.opacity(0.06), .clear]),
                                               center: centre, startRadius: 0, endRadius: size.width * 0.42))
            for index in 0..<260 {
                let particle = MusicMotionGeometry.spiralParticle(index: index, rotation: rotation, size: size)
                let twinkle: Double = MusicMotionGeometry.unit(UInt64(index) &* 7 &+ 3)
                let core: Double = 1 - particle.radius
                let base: Double = 0.5 + twinkle * 1.1 + core * 0.6
                let perspective: Double = 0.7 + particle.depth * 0.5
                let radius = CGFloat(base * perspective)
                let colour: Color = particle.radius < 0.35 ? tint : .primary
                let shine: Double = 0.5 + twinkle * 0.5
                let opacity: Double = 0.12 + 0.38 * particle.depth * shine
                let dot = CGRect(x: particle.point.x - radius, y: particle.point.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: dot), with: .color(colour.opacity(opacity)))
            }
            context.fill(Path(ellipseIn: CGRect(x: centre.x - 26, y: centre.y - 16, width: 52, height: 32)),
                         with: .radialGradient(Gradient(colors: [.white.opacity(0.55), tint.opacity(0.25), .clear]),
                                               center: centre, startRadius: 0, endRadius: 26))
        }
    }
}

private struct VinylRecord: View {
    let artworkURL: String?
    let side: CGFloat
    let isCurrent: Bool
    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !isCurrent || !controller.isPlaying || reduceMotion)) { timeline in
            ZStack {
                Circle().fill(.black)
                ForEach(1..<7) { groove in
                    Circle().stroke(.white.opacity(0.12), lineWidth: 0.5).padding(CGFloat(groove) * side * 0.045)
                }
                // Glanzlicht der Rillen bleibt stehen, während die Platte dreht.
                ArtworkView(url: artworkURL, data: nil, side: side * 0.32).clipShape(Circle())
                Circle().fill(.white.opacity(0.7)).frame(width: 4, height: 4)
            }
            // Pause hält die echte Position; andere Platten übernehmen keinen
            // Fortschritt eines fremden Titels.
            .rotationEffect(.degrees(isCurrent && !reduceMotion ? controller.livePosition(at: timeline.date) * 198 : 0))
            .overlay {
                Circle().fill(AngularGradient(colors: [.clear, .white.opacity(0.16), .clear, .white.opacity(0.10), .clear],
                                              center: .center))
            }
        }
        .frame(width: side, height: side).accessibilityHidden(true).allowsHitTesting(false)
    }
}
