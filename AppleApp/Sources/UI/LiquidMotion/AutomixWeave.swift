import SwiftUI

/// Kompakter Status für das tatsächlich von der Engine geplante Automix-Fenster.
///
/// Im Hauptplayer keine zweite, wie ein Seek-Regler wirkende Leiste: Der
/// Fortschritt ist nur während eines laufenden Mixes eine Zahl. Die Details
/// liegen in einer eigenen Ansicht und verändern nicht die Höhe des Decks.
/// Diese View liest ausschließlich Engine-Werte und verändert keine Mischung.
struct AutomixWeave: View {
    @Environment(PlaybackController.self) private var controller
    let start: Double
    let end: Double
    let position: Double
    let tier: String?
    let reason: String?
    let isMixing: Bool

    @State private var showsDetails = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var progress: Double {
        guard end > start else { return 0 }
        return min(1, max(0, (position - start) / (end - start)))
    }

    var body: some View {
        Button {
            showsDetails = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
                // Der Status muss neben zwei Zeitangaben auch bei großer
                // Schrift passen. Das native Fitting wählt bei Platzmangel
                // eine kurze, aber weiterhin echte Fortschrittsangabe.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        Text(isMixing ? "Automix running" : "Automix")
                            .fixedSize(horizontal: true, vertical: false)
                        if isMixing {
                            Text("\(Int((progress * 100).rounded())) %")
                                .monospacedDigit()
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    Text(isMixing ? "\(Int((progress * 100).rounded())) %" : "Mix")
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(Color.black.opacity(reduceTransparency ? 0.92 : 0.72))
                    .background {
                        if !reduceTransparency {
                            Capsule().fill(.ultraThinMaterial)
                        }
                    }
            }
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMixing ? Text("Automix transition running") : Text("Automix transition planned"))
        .accessibilityValue(isMixing ? Text("\(Int((progress * 100).rounded())) %") : Text("Planned transition"))
        .accessibilityHint("Open real Automix transition details")
        .accessibilityIdentifier("bbt.automix.status")
        .sheet(isPresented: $showsDetails) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        isMixing ? "Transition running" : "Next transition",
                        systemImage: "waveform.path"
                    )
                    .font(.headline)

                    AutomixLightBridge(current: controller.current,
                        next: controller.queue.indices.contains(controller.playingIndex + 1)
                            ? controller.queue[controller.playingIndex + 1] : nil,
                        progress: progress, isMixing: isMixing)

                    LabeledContent("Time window", value: String(format: "%.1f–%.1f s", start, end))
                    if isMixing {
                        LabeledContent("Progress", value: "\(Int((progress * 100).rounded())) %")
                    }
                    if let tier, !tier.isEmpty {
                        LabeledContent("Analysis", value: tier)
                    }
                    if let reason, !reason.isEmpty {
                        Text(reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(24)
                .navigationTitle("Automix")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showsDetails = false }
                            .accessibilityIdentifier("bbt.automix.details.done")
                    }
                }
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #else
            .frame(minWidth: 340, minHeight: 280)
            #endif
        }
        .background { LiquidLiveCaptureMarker(id: "automix") }
    }
}
