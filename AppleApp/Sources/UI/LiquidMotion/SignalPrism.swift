import SwiftUI

/// An expandable map of the real signal path. The values come from
/// AudioPipelineSheet's engine readout rather than simulated measurements.
struct SignalPrism: View {
    let source: String
    let decoder: String
    let processing: String
    let output: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    private var stages: [(String, String, String)] {
        [
            ("Source", "doc.text", source),
            ("Decoder", "waveform", decoder),
            ("Processing", "slider.horizontal.3", processing),
            ("Output", "headphones", output)
        ]
    }

    var body: some View {
        VStack(spacing: 11) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    ForEach(0..<stages.count, id: \.self) { index in
                        if index > 0 {
                            Rectangle()
                                .fill(.cyan.opacity(0.65))
                                .frame(height: 2)
                                .frame(maxWidth: 18)
                        }
                        Image(systemName: stages[index].1)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Audio signal prism")
            .accessibilityHint("Show actual source, decoder, processing and output details")
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<stages.count, id: \.self) { index in
                        HStack(alignment: .firstTextBaseline) {
                            Text(stages[index].0)
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer(minLength: 12)
                            Text(stages[index].2)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.caption)
                    }
                }
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.15)))
    }
}
