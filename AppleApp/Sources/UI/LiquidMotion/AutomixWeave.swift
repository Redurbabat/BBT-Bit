import SwiftUI

/// Kompakter Status für das tatsächlich von der Engine geplante Automix-Fenster.
///
/// Im Hauptplayer keine zweite, wie ein Seek-Regler wirkende Leiste: Der
/// Fortschritt ist nur während eines laufenden Mixes eine Zahl. Die Details
/// liegen in einer eigenen Ansicht und verändern nicht die Höhe des Decks.
/// Diese View liest ausschließlich Engine-Werte und verändert keine Mischung.
struct AutomixWeave: View {
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
            HStack(spacing: 9) {
                Image(systemName: "waveform.path")
                    .font(.caption.weight(.semibold))
                Text(isMixing ? "Automix · Übergang läuft" : "Automix · Übergang geplant")
                    .lineLimit(1)
                Spacer(minLength: 4)
                if isMixing {
                    Text("\(Int((progress * 100).rounded())) %")
                        .monospacedDigit()
                }
                Image(systemName: "info.circle")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
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
        .accessibilityLabel(isMixing ? "Automix Übergang läuft" : "Automix Übergang geplant")
        .accessibilityValue(isMixing ? "\(Int((progress * 100).rounded())) Prozent" : "Übergang geplant")
        .accessibilityHint("Öffnet Details zum echten Automix-Übergangsfenster")
        .sheet(isPresented: $showsDetails) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        isMixing ? "Übergang läuft" : "Nächster Übergang",
                        systemImage: "waveform.path"
                    )
                    .font(.headline)

                    LabeledContent("Zeitfenster", value: String(format: "%.1f–%.1f s", start, end))
                    if isMixing {
                        LabeledContent("Fortschritt", value: "\(Int((progress * 100).rounded())) %")
                    }
                    if let tier, !tier.isEmpty {
                        LabeledContent("Analyse", value: tier)
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
                        Button("Fertig") { showsDetails = false }
                    }
                }
            }
            #if os(iOS)
            .presentationDetents([.height(280), .medium])
            #else
            .frame(minWidth: 340, minHeight: 280)
            #endif
        }
        .background { LiquidLiveCaptureMarker(id: "automix") }
    }
}
