import SwiftUI

/// An output indicator that reacts only when the *reported* audio route changes.
struct OutputHaloGlyph: View {
    let routeName: String
    let spatialEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [Color.cyan.opacity(0.2), Color.cyan.opacity(0.85), Color.purple.opacity(0.6), Color.cyan.opacity(0.2)],
                        center: .center
                    ),
                    lineWidth: 1.8
                )
                .frame(width: 36, height: 36)
            if spatialEnabled {
                Circle()
                    .strokeBorder(.cyan.opacity(0.5), lineWidth: 1)
                    .frame(width: 42, height: 42)
            }
            Image(systemName: "headphones")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .symbolEffect(.pulse, value: reduceMotion ? "" : routeName)
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}
