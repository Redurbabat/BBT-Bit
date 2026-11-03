import SwiftUI

/// Three-level *secondary* action shelf. It does not replace BBT-Bit's
/// native TabView, and every gesture has a visible button alternative.
struct InfinityDock: View {
    let automixEnabled: Bool
    let onLyrics: () -> Void
    let onQueue: () -> Void
    let onOutput: () -> Void
    let onEqualizer: () -> Void
    let onPipeline: () -> Void
    let onAutomix: () -> Void

    @State private var level = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 7) {
            if level >= 2 {
                HStack(spacing: 7) {
                    action("EQ", icon: "slider.horizontal.3", onEqualizer)
                    action("Pipeline", icon: "waveform.path", onPipeline)
                    action(automixEnabled ? "Automix On" : "Automix Off",
                           icon: "arrow.triangle.2.circlepath", onAutomix)
                }
                .transition(transition)
            }
            if level >= 1 {
                HStack(spacing: 7) {
                    action("Lyrics", icon: "text.quote", onLyrics)
                    action("Queue", icon: "list.bullet", onQueue)
                    action("Output", icon: "headphones", onOutput)
                }
                .transition(transition)
            }
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(.cyan)
                Text("Infinity Dock")
                    .font(.caption.weight(.semibold))
                Spacer()
                Button {
                    setLevel((level + 1) % 3)
                } label: {
                    Label(level == 2 ? "Collapse" : "Lift tools",
                          systemImage: level == 2 ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(level == 2 ? "Collapse all tool shelves" : "Expand the next tool shelf")
            }
            .foregroundStyle(.white)
            .frame(minHeight: 32)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(.white.opacity(0.16)))
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                if value.translation.height < -32 { setLevel(min(2, level + 1)) }
                if value.translation.height > 32 { setLevel(max(0, level - 1)) }
            }
        )
        .accessibilityElement(children: .contain)
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    private func setLevel(_ value: Int) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) {
            level = value
        }
    }

    private func action(_ title: String, icon: String, _ callback: @escaping () -> Void) -> some View {
        Button(action: callback) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.body)
                Text(title).font(.system(size: 10, weight: .medium)).lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
