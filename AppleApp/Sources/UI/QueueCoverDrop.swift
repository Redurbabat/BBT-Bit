import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

extension UTType {
    static let redBitQueueSelection = UTType(exportedAs: "com.babat.bbtbit.queue-selection", conformingTo: .data)
}

extension QueueDragTicket: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .redBitQueueSelection) { ticket in
            try JSONEncoder().encode(ticket)
        } importing: { data in
            guard data.count < 256 else { throw QueueCollectionError.incomplete }
            return try JSONDecoder().decode(QueueDragTicket.self, from: data)
        }
    }
}

@MainActor private enum QueueDragSessions {
    static var registry = QueueDragRegistry()
    static func provider(for target: QueueDragTarget) -> NSItemProvider {
        let ticket = registry.register(target, session: PageSession.generation(), now: ProcessInfo.processInfo.systemUptime)
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.redBitQueueSelection.identifier, visibility: .ownProcess) { completion in
            do { completion(try JSONEncoder().encode(ticket), nil) }
            catch { completion(nil, error) }
            return nil
        }
        return provider
    }
}

extension ShelfCard {
    func queueDragTarget(preferTrack: Bool) -> QueueDragTarget? {
        let collectionID = browseId.flatMap { !$0.isEmpty && !$0.hasPrefix("UC") ? $0 : nil }
        if let id = videoId, HomeMixBuilder.isYouTubeID(id), preferTrack || collectionID == nil {
            return .track(.youtube(videoId: id, title: title, artist: subtitle ?? "",
                thumbnailUrl: thumbnailUrl, isVideo: isVideo))
        }
        if let id = collectionID {
            return .collection(browseID: id, title: title)
        }
        return nil
    }
    var supportsCollectionPeek: Bool {
        guard let id = browseId, !id.isEmpty else { return false }
        return !id.hasPrefix("UC") && videoId == nil
    }
}

struct QueueCardDragSource: ViewModifier {
    let card: ShelfCard
    let preferTrack: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if let target = card.queueDragTarget(preferTrack: preferTrack) {
            content.onDrag { QueueDragSessions.provider(for: target) } preview: {
                ArtworkView(url: card.thumbnailUrl, data: nil, side: 72)
                    .clipShape(.rect(cornerRadius: 12))
            }
        } else { content }
    }
}

struct QueueCoverDropDestination: ViewModifier {
    @Environment(PlaybackController.self) private var controller
    @Environment(ToastCenter.self) private var toast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var targeted = false
    @State private var loading = false
    @State private var receipt: QueueNextAction.Receipt?
    @State private var receiptID = UUID()
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()

    func body(content: Content) -> some View {
        content
            .overlay {
                if targeted {
                    Capsule().strokeBorder(Color.accentColor, lineWidth: 2)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                if targeted || loading {
                    Text(loading ? "Sammlung wird geladen …" : "Loslassen für Als Nächstes")
                        .font(.caption.weight(.semibold))
                        .padding(8)
                        .background(Theme.Materials.opaque, in: Capsule())
                        .offset(y: -36)
                        .allowsHitTesting(false)
                } else if let receipt {
                    HStack(spacing: 7) {
                        ArtworkView(entry: receipt.first, side: 28).clipShape(.rect(cornerRadius: 6))
                        Text("Als Nächstes eingereiht").font(.caption.weight(.semibold))
                    }
                    .padding(6)
                    .background(Theme.Materials.opaque, in: Capsule())
                    .offset(y: -42)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: receiptID)
            .dropDestination(for: QueueDragTicket.self) { tickets, _ in
                guard tickets.count == 1, !loading, !PartyStore.shared.inParty,
                      let target = QueueDragSessions.registry.claim(tickets[0], session: PageSession.generation(),
                          now: ProcessInfo.processInfo.systemUptime) else { return false }
                loading = true
                let probe = AppTestEvents.begin(.coverDrop)
                let request = UUID(); requestID = request
                requestTask = Task { @MainActor in
                    defer { if requestID == request { loading = false } }
                    do {
                        let result = try await QueueNextAction.insert(target, into: controller)
                        guard !Task.isCancelled, requestID == request else { return }
                        receipt = result; receiptID = UUID()
                        AppTestEvents.finish(probe, .success, .queueUpdated)
                        toast.queueNotice("Als Nächstes: \(result.title)")
                    } catch is CancellationError { }
                    catch { toast.show(error.localizedDescription) }
                }
                return true
            } isTargeted: { targeted = $0 && !PartyStore.shared.inParty }
            .task(id: receiptID) {
                guard receipt != nil else { return }
                do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
                receipt = nil
            }
            .onDisappear { requestID = UUID(); requestTask?.cancel(); loading = false; receipt = nil }
    }
}

struct QueueCollectionNextButton: View {
    let browseID: String
    let title: String
    @Environment(PlaybackController.self) private var controller
    @Environment(ToastCenter.self) private var toast

    var body: some View {
        Button("Als Nächstes", systemImage: "text.insert") {
            Task { @MainActor in
                do {
                    let receipt = try await QueueNextAction.insert(.collection(browseID: browseID, title: title), into: controller)
                    toast.queueNotice("Als Nächstes: \(receipt.title)")
                } catch is CancellationError { }
                catch { toast.show(error.localizedDescription) }
            }
        }
        .disabled(PartyStore.shared.inParty)
    }
}
