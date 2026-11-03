import SwiftUI

/// A shared-geometry portal from a small queue button to a glass preview.
struct GlassQueuePortal: View {
    let onOpenQueue: () -> Void

    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var portal
    @State private var expanded = false

    private var upcomingIndices: [Int] {
        Array(controller.queue.indices.filter { $0 > controller.playingIndex }.prefix(4))
    }

    var body: some View {
        Group {
            if expanded {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("QUEUE PORTAL")
                            .font(.caption.weight(.bold))
                        Spacer()
                        Button {
                            change(false)
                        } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close queue portal")
                    }
                    if upcomingIndices.isEmpty {
                        Text("No upcoming tracks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView {
                            VStack(spacing: 5) {
                                ForEach(upcomingIndices, id: \.self) { index in
                                    Button {
                                        controller.playQueueItem(at: index)
                                        change(false)
                                    } label: {
                                        HStack(spacing: 8) {
                                            ArtworkView(entry: controller.queue[index], side: 30)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                            Text(controller.queue[index].title)
                                                .font(.caption)
                                                .lineLimit(1)
                                            Spacer(minLength: 0)
                                            Image(systemName: "play.fill")
                                                .font(.caption2)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Play queued track \(controller.queue[index].title)")
                                }
                            }
                        }
                        .frame(maxHeight: 145)
                    }
                    Button("Open full queue", systemImage: "arrow.up.left.and.arrow.down.right") {
                        change(false)
                        onOpenQueue()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.primary)
                .padding(14)
                .frame(width: 280)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21))
                .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(.white.opacity(0.20)))
                .matchedGeometryEffect(id: "queue-portal", in: portal)
                .transition(.opacity)
            } else {
                Button {
                    change(true)
                } label: {
                    Label("Queue", systemImage: "list.bullet")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: "queue-portal", in: portal)
                .accessibilityLabel("Expand glass queue portal")
            }
        }
        .shadow(color: .black.opacity(0.2), radius: expanded ? 16 : 7, y: 5)
    }

    private func change(_ next: Bool) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.43, dampingFraction: 0.88)) {
            expanded = next
        }
    }
}
