import SwiftUI

/// Karussell-Bewegung für die Regale der Künstlerseite.
///
/// Karten kippen im Raum, schrumpfen zum Rand hin und verzerren sich leicht in
/// Scrollrichtung. Reihenfolge, Inhalt und Navigation der Regale bleiben
/// unverändert; bei „Bewegung reduzieren“ bleibt die Karte unverändert.
struct HorizonRailMotion: ViewModifier {
    var enabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if enabled && !reduceMotion {
            content.scrollTransition(.interactive, axis: .horizontal) { view, phase in
                view
                    .rotation3DEffect(
                        .degrees(Double(phase.value) * -28),
                        axis: (0, 1, 0),
                        perspective: 0.7
                    )
                    .distortionEffect(
                        ShaderLibrary.horizonRailBend(.boundingRect, .float(Float(phase.value))),
                        maxSampleOffset: CGSize(width: 12, height: 13)
                    )
                    .scaleEffect(x: 1 + abs(phase.value) * 0.06, y: 1 - abs(phase.value) * 0.04)
                    .opacity(1 - abs(phase.value) * 0.12)
            }
        } else {
            content
        }
    }
}

/// Seitenanzeige unter einem Regal: kleine Punkte, der aktive ist eine Kapsel.
struct HorizonRailDots: View {
    let count: Int
    let active: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(Color.primary.opacity(index == active ? 0.85 : 0.28))
                    .frame(width: index == active ? 22 : 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: active)
        .accessibilityHidden(true)
    }
}
