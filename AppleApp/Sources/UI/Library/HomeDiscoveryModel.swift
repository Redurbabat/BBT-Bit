import Foundation
import Observation

@MainActor @Observable final class HomeDiscoveryModel {
    private(set) var pins: [ShelfCard] = []
    private(set) var history: [QueueEntry] = []
    private(set) var feedTracks: [QueueEntry] = []
    private(set) var collections: [ShelfCard] = []
    private(set) var pinsLoading = false
    private var requestID = UUID()

    func clear() {
        requestID = UUID(); pins = []; history = []; feedTracks = []; collections = []; pinsLoading = false
    }

    func seedHistory(excluding videos: Set<String> = []) {
        history = ListeningStore.shared.summary(includeGenres: false).songs
            .filter { HomeMixBuilder.isYouTubeID($0.id) && !videos.contains($0.id) }
            .sorted { ($0.last ?? 0) > ($1.last ?? 0) }
            .prefix(100).map {
                .youtube(videoId: $0.id, title: $0.title, artist: $0.artist,
                    thumbnailUrl: $0.art, albumName: $0.album, artistId: $0.artistId, albumId: $0.albumId)
            }
    }

    func refresh(shelves: [FeedShelf], session: Int64?) async {
        guard session == PageSession.generation() else { clear(); return }
        let request = UUID(); requestID = request
        let cards = shelves.flatMap(\.items)
        feedTracks = cards.compactMap { card in
            guard let id = card.videoId, !card.isVideo, HomeMixBuilder.isYouTubeID(id) else { return nil }
            return .youtube(videoId: id, title: card.title, artist: card.subtitle ?? "", thumbnailUrl: card.thumbnailUrl)
        }
        var collectionIDs: Set<String> = []
        collections = cards.filter { $0.supportsCollectionPeek && collectionIDs.insert($0.id).inserted }
        let videos = Set(cards.filter(\.isVideo).compactMap(\.videoId))
        seedHistory(excluding: videos)
        let ids = Array(PlaylistPinning.pinnedIds().prefix(2))
        pins = ids.map { id in
            cards.first { $0.browseId == id || $0.browseId == "VL\(id)" }
                ?? ShelfCard(title: "Angeheftete Playlist", browseId: id)
        }
        pinsLoading = !ids.isEmpty
        defer { if requestID == request { pinsLoading = false } }
        for (index, id) in ids.enumerated() {
            guard !Task.isCancelled, requestID == request, session == PageSession.generation() else { return }
            if pins[index].thumbnailUrl != nil { continue }
            do {
                let page: DetailPageModel
                if !NetworkQuality.shared.connected,
                   let offline = DetailPageModel.downloadedCopy(browseId: id, from: DownloadStore.shared) {
                    page = offline
                } else { page = try await InnertubeDetail.shared.browse(browseId: id) }
                guard !Task.isCancelled, requestID == request, session == PageSession.generation(), pins.indices.contains(index) else { return }
                pins[index] = ShelfCard(title: page.title, subtitle: page.subtitle, thumbnailUrl: page.thumbnailUrl, browseId: id)
            } catch {
                // Der echte Pin bleibt auch ohne erreichbare Metadaten bedienbar.
            }
        }
    }
}
