import SwiftUI

/// A compact, inspectable representation of the engine's *real* Automix window.
/// This view is read-only: dragging and expanding never change the audio mix.
struct AutomixWeave: View {
    let start: Double
    let end: Double
    let position: Double
    let tier: String?
    let reason: String?
    let isMixing: Bool

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        guard end > start else { return 0 }
        return min(1, max(0, (position - start) / (end - start)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "music.note")
                        .font(.caption.weight(.semibold))
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.14))
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.cyan.opacity(0.85), .purple.opacity(0.95), .pink.opacity(0.85)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                            Circle()
                                .fill(.white)
                                .frame(width: 7, height: 7)
                                .offset(x: max(0, (proxy.size.width - 7) * progress))
                        }
                    }
                    .frame(height: 7)
                    Image(systemName: "music.note")
                        .font(.caption.weight(.semibold))
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.9))
                .frame(minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Automix transition")
            .accessibilityValue(isMixing ? "Mixing" : "Upcoming")
            .accessibilityHint("Show or hide analyzed transition details")

            if expanded {
                VStack(alignment: .leading, spacing: 5) {
                    Label(isMixing ? "Transition in progress" : "Upcoming transition",
                          systemImage: "waveform.path")
                        .font(.caption.weight(.semibold))
                    Text(String(format: "Transition window: %.1f–%.1f s", start, end))
                        .font(.caption.monospacedDigit())
                    if let tier, !tier.isEmpty {
                        Text(tier).font(.caption)
                    }
                    if let reason, !reason.isEmpty {
                        Text(reason).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .contain)
        .background { LiquidLiveCaptureMarker(id: "automix") }
    }
}
