import Foundation

// Kontrollierte Netzwerk-, Konto- und Ausgabeadapter; Auswahl, Loader,
// Request-Gates und Einfügen stammen aus den Produktionsdateien.
@MainActor enum PageSession { static var value: Int64 = 1; static func generation() -> Int64 { value } }
@MainActor final class NetworkQuality { static let shared = NetworkQuality(); var connected = true }
@MainActor final class PartyStore { static let shared = PartyStore(); var inParty = false }
@MainActor final class DownloadStore { static let shared = DownloadStore() }
@MainActor enum PlaylistPinning { static var ids: [String] = []; static func pinnedIds() -> [String] { ids } }
@MainActor final class ListeningStore {
    static let shared = ListeningStore()
    struct Track {
        let id: String, title: String, artist: String
        var art: String? = nil, album: String? = nil, artistId: String? = nil, albumId: String? = nil
        var last: Double? = nil
    }
    struct Summary { let songs: [Track] }
    var songs: [Track] = []
    func summary(includeGenres: Bool) -> Summary { Summary(songs: songs) }
}
struct DetailPageModel {
    struct SongPayload {
        let entry: QueueEntry
        func asEntry(fallbackArt: String?) -> QueueEntry { entry }
    }
    let title: String
    var subtitle = "Fixture"
    var thumbnailUrl: String? = nil
    let songs: [SongPayload]
    var continuation: String? = nil
    @MainActor static var offline: DetailPageModel?
    @MainActor static func downloadedCopy(browseId: String, from: DownloadStore) -> DetailPageModel? { offline }
}
@MainActor final class InnertubeDetail {
    static let shared = InnertubeDetail()
    var pages: [DetailPageModel] = []
    var onPage: (() -> Void)?
    var calls = 0
    func browse(browseId: String) async throws -> DetailPageModel { try await take() }
    func more(token: String) async throws -> DetailPageModel { try await take() }
    private func take() async throws -> DetailPageModel {
        calls += 1
        await Task.yield()
        onPage?()
        guard !pages.isEmpty else { throw URLError(.networkConnectionLost) }
        return pages.removeFirst()
    }
}
@MainActor final class PlaybackController {
    var playGeneration: UInt64 = 1
    var queueEditRevision: UInt64 = 0
    var queue: [QueueEntry] = []
    var playingIndex = 0
    var current: QueueEntry? { queue.indices.contains(playingIndex) ? queue[playingIndex] : nil }
    // Die echte Idle-Prüfung hängt vom Enginezustand ab, nicht von der Queue.
    var isIdle = false
    var loads = 0
    func noteLocalIntent() {}
    func removeAutoplayDuplicate(of: QueueEntry) {}
    func persistSession() {}
    func syncEngineQueueNext() {}
    func loadCurrent(_ index: Int) { loads += 1; isIdle = false }
    // PRODUCTION_PLAY_NEXT
}
