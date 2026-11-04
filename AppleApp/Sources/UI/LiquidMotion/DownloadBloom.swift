import SwiftUI

/// A lightweight download status bloom using real job counts.
/// There is no invented percentage: incomplete jobs remain indeterminate.
struct DownloadBloom: View {
    let active: Int
    let finished: Int
    let failed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(.cyan.opacity(0.3), lineWidth: 3)
                    .frame(width: 46, height: 46)
                Image(systemName: active > 0 ? "arrow.down.circle.fill" : "sparkle")
                    .font(.title2)
                    .foregroundStyle(failed > 0 ? .orange : .cyan)
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : finished)
                if active > 0 {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.cyan)
                        .offset(x: 23, y: 23)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(active > 0 ? "Downloads in motion" : "Downloads settled")
                    .font(.headline)
                Text("\(active) active · \(finished) finished · \(failed) failed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(active) active downloads, \(finished) finished, \(failed) failed")
        .background { LiquidLiveCaptureMarker(id: "downloads") }
    }
}
