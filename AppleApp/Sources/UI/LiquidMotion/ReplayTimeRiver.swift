import SwiftUI

/// Interactive listening-hour river from local Replay aggregates.
/// All 24 hours come from ListeningStore, not synthetic samples.
struct ReplayTimeRiver: View {
    let hourlyValues: [Double]

    @State private var selectedHour: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maximum: Double { max(1, hourlyValues.max() ?? 1) }
    private var selectedValue: Double {
        guard let selectedHour, hourlyValues.indices.contains(selectedHour) else { return 0 }
        return hourlyValues[selectedHour]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Listening time river", systemImage: "water.waves")
                    .font(.headline)
                Spacer()
                if let selectedHour {
                    Text(String(format: "%02d:00", selectedHour))
                        .font(.caption.monospacedDigit())
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(hourlyValues.enumerated()), id: \.offset) { index, value in
                        Button {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.30, dampingFraction: 0.83)) {
                                selectedHour = index
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Capsule()
                                    .fill(selectedHour == index ? Color.white : Color.cyan.opacity(0.75))
                                    .frame(width: 20, height: max(8, 75 * value / maximum))
                                    .frame(height: 80, alignment: .bottom)
                                Text(index.isMultiple(of: 4) ? String(format: "%02d", index) : " ")
                                    .font(.system(size: 9, design: .monospaced))
                            }
                            .frame(width: 27, minHeight: 104)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Hour \(index)")
                        .accessibilityValue("\(Int(value / 60_000)) minutes")
                        .accessibilityAddTraits(selectedHour == index ? [.isSelected] : [])
                    }
                }
            }
            if let selectedHour {
                Text("Around \(String(format: "%02d:00", selectedHour)): \(ReplayModel.formatListening(selectedValue))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            } else {
                Text("Tap a column to inspect listening time by hour.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .onChange(of: hourlyValues) { _, _ in selectedHour = nil }
    }
}
