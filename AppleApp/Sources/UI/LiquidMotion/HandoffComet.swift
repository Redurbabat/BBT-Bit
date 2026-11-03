import SwiftUI
import Observation

/// Shared short-lived UI notice for an *accepted* Handoff request.
/// The core PlaybackHandoff implementation remains the authority on success.
@MainActor @Observable
final class HandoffNoticeCenter {
    static let shared = HandoffNoticeCenter()
    private(set) var title: String?
    private var generation = 0

    func received(_ title: String) {
        generation += 1
        let ticket = generation
        withAnimation(.easeOut(duration: 0.25)) { self.title = title }
        Task {
            try? await Task.sleep(for: .seconds(3))
            guard generation == ticket else { return }
            withAnimation(.easeOut(duration: 0.2)) { self.title = nil }
        }
    }
}

/// One arrival pulse. No continuous renderer, no fabricated device detection.
struct HandoffComet: View {
    let title: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(.cyan)
                .symbolEffect(.bounce, value: reduceMotion ? "" : title)
            VStack(alignment: .leading, spacing: 1) {
                Text("Handoff received").font(.caption.weight(.semibold))
                Text(title).font(.caption2).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.cyan.opacity(0.4), lineWidth: 1))
        .shadow(color: .cyan.opacity(0.2), radius: 12, y: 3)
        .accessibilityElement(children: .combine)
    }
}
