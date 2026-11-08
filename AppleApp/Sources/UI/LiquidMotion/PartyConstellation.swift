import SwiftUI

/// Teilnehmer, Rollen und Verbindung kommen unverändert aus dem PartyStore.
struct PartyConstellation: View {
    @Environment(PartyStore.self) private var party
    @Environment(PlaybackController.self) private var controller
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMember: String?

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
            ZStack {
                Ellipse()
                    .stroke(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                    .frame(width: max(0, proxy.size.width - 64), height: 230)
                ArtworkView(entry: controller.current, side: 84)
                    .frame(width: 84, height: 84).clipShape(.rect(cornerRadius: 18))
                    .accessibilityLabel(controller.current?.title ?? AppLanguage.localized("Not Playing"))
                ForEach(Array(party.state.members.prefix(10).enumerated()), id: \.element.memberId) { index, member in
                    let angle = Double(index) * 2 * Double.pi / Double(max(1, min(10, party.state.members.count))) - Double.pi / 2
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.84)) {
                            selectedMember = selectedMember == member.memberId ? nil : member.memberId
                        }
                    } label: {
                        PartyAvatar(url: member.avatarUrl, name: member.name, size: selectedMember == member.memberId ? 52 : 46)
                            .overlay {
                                Circle()
                                    .strokeBorder(member.connected ? Color.cyan : Color.gray,
                                                  lineWidth: selectedMember == member.memberId ? 3 : 1.5)
                            }
                            .frame(width: 56, height: 56)
                            .overlay(alignment: .bottomTrailing) {
                                if member.isHost {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.yellow)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(cos(angle)) * max(0, proxy.size.width / 2 - 32), y: CGFloat(sin(angle)) * 115)
                    .accessibilityLabel("\(member.name), \(AppLanguage.localized(member.isHost ? "Host" : "Listener")), \(AppLanguage.localized(member.connected ? "Connected" : "Offline"))")
                }
            }
            .frame(width: proxy.size.width, height: 300)
            }
            .frame(height: 300)
            if let selectedMember,
               let member = party.state.members.first(where: { $0.memberId == selectedMember }) {
                Text("\(member.name) · \(AppLanguage.localized(member.isHost ? "Host" : "Listener"))")
                    .font(.caption.weight(.semibold))
                    .transition(.opacity)
            } else {
                Text("Tap a listener to inspect their role.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .background { LiquidLiveCaptureMarker(id: "party") }
    }
}
