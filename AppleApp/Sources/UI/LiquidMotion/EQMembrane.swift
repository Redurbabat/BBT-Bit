import SwiftUI

/// A tactile overview of the existing seven-band manual EQ. Dragging a point
/// edits the same band bindings used by the original sliders and persistence.
struct EQMembrane: View {
    @Binding var bands: [Double]
    let enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EQ MEMBRANE · drag to shape")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            GeometryReader { geometry in
                Canvas { context, size in
                    guard bands.count == 7 else { return }
                    let step = size.width / CGFloat(max(1, bands.count - 1))
                    var line = Path()
                    for index in bands.indices {
                        let point = CGPoint(
                            x: CGFloat(index) * step,
                            y: size.height * (0.5 - CGFloat(bands[index] / 24))
                        )
                        if index == 0 { line.move(to: point) }
                        else { line.addLine(to: point) }
                    }
                    context.stroke(line, with: .color(.cyan), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    for index in bands.indices {
                        let point = CGPoint(
                            x: CGFloat(index) * step,
                            y: size.height * (0.5 - CGFloat(bands[index] / 24))
                        )
                        let dot = Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
                        context.fill(dot, with: .color(.white))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        guard enabled, bands.count == 7, geometry.size.width > 0, geometry.size.height > 0 else { return }
                        let fraction = min(1, max(0, value.location.x / geometry.size.width))
                        let index = min(6, max(0, Int((fraction * 6).rounded())))
                        let gain = 12 - Double(min(1, max(0, value.location.y / geometry.size.height))) * 24
                        let snapped = (gain * 2).rounded() / 2
                        if bands[index] != snapped {
                            bands[index] = snapped
                        }
                    }
                )
            }
            .frame(height: 110)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            Text("The original sliders remain available for precise and accessible adjustments.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Seven band EQ curve. Use the sliders below for VoiceOver and keyboard editing.")
    }
}
