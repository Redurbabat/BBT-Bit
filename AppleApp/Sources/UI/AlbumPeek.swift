import SwiftUI
import Observation

@MainActor @Observable final class AlbumPeekModel {
    enum Phase { case loading, loaded([QueueEntry]), failed }
    private(set) var phase: Phase = .loading
    private var requestID = UUID()

    func load(_ card: ShelfCard) async {
        guard let id = card.browseId else { phase = .failed; return }
        let probe = AppTestEvents.begin(.albumPreview)
        let request = UUID(), generation = PageSession.generation()
        requestID = request; phase = .loading
        do {
            let page: DetailPageModel
            if !NetworkQuality.shared.connected,
               let offline = DetailPageModel.downloadedCopy(browseId: id, from: DownloadStore.shared) {
                page = offline
            } else { page = try await InnertubeDetail.shared.browse(browseId: id) }
            guard !Task.isCancelled, requestID == request, generation == PageSession.generation() else { return }
            let entries = page.songs.prefix(3).map { $0.asEntry(fallbackArt: page.thumbnailUrl) }
            phase = entries.isEmpty ? .failed : .loaded(entries)
            AppTestEvents.finish(probe, entries.isEmpty ? .failure : .success, entries.isEmpty ? .emptyResponse : .responseReceived)
        } catch {
            guard !Task.isCancelled, requestID == request, generation == PageSession.generation() else { return }
            phase = .failed
            AppTestEvents.finish(probe, .failure, .requestFailed)
        }
    }
}

struct AlbumPeekContents: View {
    let card: ShelfCard
    var compact = false
    @Environment(AuthController.self) private var auth
    @State private var model = AlbumPeekModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ArtworkView(url: card.thumbnailUrl, data: nil, side: compact ? 72 : 112)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.title).font(.headline).lineLimit(3)
                    if let subtitle = card.subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }
                }
            }
            Text("Erste Titel").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            switch model.phase {
            case .loading:
                ProgressView("Titel werden geladen …").frame(minHeight: 44)
            case .failed:
                Text("Die Vorschau ist gerade nicht verfügbar.").font(.subheadline).foregroundStyle(.secondary)
                if !compact {
                    Button("Erneut laden") { Task { await model.load(card) } }.frame(minHeight: 44)
                }
            case .loaded(let entries):
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    HStack(spacing: 10) {
                        Text("\(index + 1)").monospacedDigit().foregroundStyle(.secondary).frame(width: 20)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title).font(.subheadline.weight(.medium)).lineLimit(1)
                            Text(entry.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }.frame(minHeight: 44)
                }
            }
        }
        .task(id: "\(card.id)-\(auth.sessionEpoch)") { await model.load(card) }
    }
}

struct AlbumPeekPreview: View {
    let card: ShelfCard
    var body: some View {
        AlbumPeekContents(card: card, compact: true).padding(16).frame(width: 300)
    }
}

struct CollectionPeekAccess: ViewModifier {
    let card: ShelfCard
    @State private var presented = false

    /// Kein sichtbarer „…“-Knopf mehr auf dem Cover (Nutzerwunsch 11.11.: zu groß,
    /// verdeckt das Bild). Die Aktionen kommen per langem Druck
    /// (shelfCardContextMenu mit Album-Vorschau) oder in der Sammlung selbst;
    /// VoiceOver erreicht die Vorschau über eine benannte Aktion.
    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: Text("Album-Vorschau")) {
                if card.supportsCollectionPeek { presented = true }
            }
            .sheet(isPresented: $presented) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            AlbumPeekContents(card: card)
                            if let id = card.browseId {
                                QueueCollectionNextButton(browseID: id, title: card.title)
                                    .buttonStyle(.borderedProminent).frame(minHeight: 44)
                                NavigationLink("Sammlung öffnen") { DetailView(browseId: id, initialTitle: card.title) }
                                    .frame(minHeight: 44)
                            }
                        }.padding(24)
                    }
                    .navigationTitle("Album-Vorschau")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { presented = false } } }
                }
                #if os(iOS)
                .presentationDetents([.medium, .large])
                #else
                .frame(minWidth: 420, minHeight: 480)
                #endif
            }
    }
}
