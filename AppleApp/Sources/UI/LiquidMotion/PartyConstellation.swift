import SwiftUI

/// The connected members rendered as an inspectable constellation.
/// Membership, host role and connection indicators come from PartyStore.
struct PartyConstellation: View {
    @Environment(PartyStore.self) private var party
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMember: String?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Ellipse()
                    .stroke(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                    .frame(width: 260, height: 150)
                Image(systemName: "music.note")
                    .font(.title)
                    .foregroundStyle(.cyan)
                    .frame(width: 64, height: 64)
                    .background(.thinMaterial, in: Circle())
                ForEach(Array(party.state.members.prefix(10).enumerated()), id: \.element.memberId) { index, member in
                    let angle = Double(index) * 2 * Double.pi / Double(max(1, min(10, party.state.members.count))) - Double.pi / 2
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.84)) {
                            selectedMember = selectedMember == member.memberId ? nil : member.memberId
                        }
                    } label: {
                        PartyAvatar(url: member.avatarUrl, name: member.name, size: selectedMember == member.memberId ? 52 : 42)
                            .overlay {
                                Circle()
                                    .strokeBorder(member.connected ? Color.cyan : Color.gray,
                                                  lineWidth: selectedMember == member.memberId ? 3 : 1.5)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                if member.isHost {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.yellow)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(cos(angle)) * 130, y: CGFloat(sin(angle)) * 75)
                    .accessibilityLabel("\(member.name), \(member.isHost ? "host" : "listener"), \(member.connected ? "connected" : "offline")")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 245)
            if let selectedMember,
               let member = party.state.members.first(where: { $0.memberId == selectedMember }) {
                Text("\(member.name) · \(member.isHost ? "Host" : "Listener")")
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
