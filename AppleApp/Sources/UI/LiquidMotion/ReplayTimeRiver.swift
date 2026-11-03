import SwiftUI

/// Interactive listening-hour river from local Replay aggregates.
/// All 24 hours come from ListeningStore, not synthetic samples.
struct ReplayTimeRiver: View {
    let hourlyValues: [Double]

    @State private var selectedHour: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maximum: Double { max(1, hourlyValues.max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            hourColumns
            selectedHourDetail
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .onChange(of: hourlyValues) { _, _ in selectedHour = nil }
        .background { LiquidLiveCaptureMarker(id: "replay") }
    }

    private var header: some View {
        HStack {
            Label("Listening time river", systemImage: "water.waves")
                .font(.headline)
            Spacer()
            if let selectedHour {
                Text(String(format: "%02d:00", selectedHour))
                    .font(.caption.monospacedDigit())
            }
        }
    }

    private var hourColumns: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(hourlyValues.indices, id: \.self) { index in
                    ReplayHourBar(
                        index: index,
                        milliseconds: hourlyValues[index],
                        maximum: maximum,
                        selected: selectedHour == index
                    ) {
                        let animation: Animation? = reduceMotion
                            ? nil
                            : .spring(response: 0.30, dampingFraction: 0.83)
                        withAnimation(animation) {
                            selectedHour = index
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectedHourDetail: some View {
        if let selectedHour, hourlyValues.indices.contains(selectedHour) {
            Text("Around \(String(format: "%02d:00", selectedHour)): \(ReplayModel.formatListening(hourlyValues[selectedHour]))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
        } else {
            Text("Tap a column to inspect listening time by hour.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

/// Separating each bar from the parent ViewBuilder prevents the release
/// compiler from type-checking an entire 24-item layout as one expression.
private struct ReplayHourBar: View {
    let index: Int
    let milliseconds: Double
    let maximum: Double
    let selected: Bool
    let onSelect: () -> Void

    private var barHeight: CGFloat {
        CGFloat(max(8, 75 * milliseconds / max(1, maximum)))
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Capsule()
                    .fill(selected ? Color.white : Color.cyan.opacity(0.75))
                    .frame(width: 20, height: barHeight)
                    .frame(height: 80, alignment: .bottom)
                Text(index.isMultiple(of: 4) ? String(format: "%02d", index) : " ")
                    .font(.system(size: 9, design: .monospaced))
            }
            .frame(width: 27)
            .frame(minHeight: 104)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hour \(index)")
        .accessibilityValue("\(Int(milliseconds / 60_000)) minutes")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
