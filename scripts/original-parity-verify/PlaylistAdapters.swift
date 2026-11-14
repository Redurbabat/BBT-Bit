import Foundation

// Kontrollierte Netzwerk-/Speicheradapter. Die Abgleichmethoden werden vom
// Prüfskript unverändert aus DownloadStore in diese Klasse eingesetzt.
@MainActor final class NetworkQuality {
    static let shared = NetworkQuality()
    var connected = true; var metered = false
}
@MainActor enum PageSession { static var value: Int64 = 1; static func generation() -> Int64 { value } }
@MainActor final class PlatformSettings {
    static let shared = PlatformSettings()
    func getBoolean(key: String, default value: Bool) -> Bool { value }
    func getString(key: String, default value: String) -> String { value }
}
@MainActor final class PlaybackDebugLog {
    static let shared = PlaybackDebugLog()
    func record(_ message: String) {}
}
struct TestPage {
    var songs: [TestSong]; var continuation: String?; var thumbnailUrl: String? = nil
}
struct TestSong { let entry: QueueEntry; func asEntry(fallbackArt: String?) -> QueueEntry { entry } }
@MainActor final class InnertubeDetail {
    static let shared = InnertubeDetail()
    var pages: [TestPage] = []
    var onPage: (() -> Void)?
    var requests = 0
    func browse(browseId: String, force: Bool) async throws -> TestPage { try await take() }
    func more(token: String) async throws -> TestPage { try await take() }
    private func take() async throws -> TestPage {
        requests += 1
        await Task.yield()
        onPage?()
        guard !pages.isEmpty else { throw URLError(.networkConnectionLost) }
        return pages.removeFirst()
    }
}
@MainActor final class DownloadStore {
    enum RequestResult { case ignoredLocalTrack, started, alreadyExists }
    struct Job { enum Status { case queued, failed }; let id: String; let entry: QueueEntry; var status = Status.queued; var cancelled = false }
    struct Owner { let id: String; let browseId: String?; var requests: [String]; var playlistSync: PlaylistSyncRecord? }
    struct Index { var owners: [String: Owner] = [:]; var playlistSyncCheckedAt: [String: Date]? }
    var index = Index()
    var jobs: [Job] = []
    var writable = true, restoring = false, appActive = true, keepsPlaylistsUpdated = true
    var playlistSyncTask: Task<Void, Never>?
    var syncs: Set<String> = []
    var accountId = "fixture-account"
    var directory = FileManager.default.temporaryDirectory
    var pendingPlaylistUpdates = 0
    var collections: [Owner] { Array(index.owners.values) }
    var enqueued: [String] = []
    var persisted = 0
    func requestId(_ entry: QueueEntry, quality: String) -> String { entry.id }
    func enqueue(_ entry: QueueEntry, quality: String) -> RequestResult {
        enqueued.append(entry.id)
        jobs.append(Job(id: entry.id, entry: entry))
        return .started
    }
    func retry(_ id: String) -> RequestResult {
        if let i = jobs.firstIndex(where: { $0.id == id }) { jobs[i].status = .queued }
        return .started
    }
    func persist() { persisted += 1 }
    func pump() {}
    // PRODUCTION_PLAYLIST_SYNC
}

@main enum PlaylistSyncChecks {
    @MainActor static func main() async {
        func page(_ ids: [String], next: String? = nil) -> TestPage {
            TestPage(songs: ids.map { TestSong(entry: .youtube(videoId: $0, title: $0, artist: "Fixture")) }, continuation: next)
        }
        func store(seen: Set<String>? = ["kept", "deleted"]) -> DownloadStore {
            let result = DownloadStore()
            result.index.owners["playlist"] = .init(id: "playlist", browseId: "VLPL1", requests: ["kept"],
                playlistSync: seen.map { PlaylistSyncRecord(seenEntryIDs: $0) })
            InnertubeDetail.shared.pages = []; InnertubeDetail.shared.onPage = nil
            NetworkQuality.shared.metered = false
            return result
        }
        let addition = store()
        InnertubeDetail.shared.pages = [page(["kept", "deleted", "new", "new"])]
        addition.checkPlaylistUpdates(force: true)
        await addition.waitForPlaylistUpdates()
        assert(addition.enqueued == ["new"])
        assert(addition.index.owners["playlist"]?.requests == ["kept", "new"])
        assert(addition.index.playlistSyncCheckedAt?[addition.accountId] != nil)

        let partial = store()
        InnertubeDetail.shared.pages = [page(["new"], next: "missing-page")]
        partial.checkPlaylistUpdates(force: true)
        await partial.waitForPlaylistUpdates()
        assert(partial.enqueued.isEmpty && partial.persisted == 0)
        let previousRequests = InnertubeDetail.shared.requests
        partial.checkPlaylistUpdates()
        await partial.waitForPlaylistUpdates()
        assert(InnertubeDetail.shared.requests == previousRequests)

        let legacy = store(seen: nil)
        InnertubeDetail.shared.pages = [page(["kept", "previously-deleted"])]
        legacy.checkPlaylistUpdates(force: true)
        await legacy.waitForPlaylistUpdates()
        assert(legacy.enqueued.isEmpty)
        assert(legacy.index.owners["playlist"]?.playlistSync?.seenEntryIDs == ["kept", "previously-deleted"])

        let changedAccount = store()
        InnertubeDetail.shared.pages = [page(["new"])]
        InnertubeDetail.shared.onPage = { changedAccount.accountId = "another-account" }
        changedAccount.checkPlaylistUpdates(force: true)
        await changedAccount.waitForPlaylistUpdates()
        assert(changedAccount.enqueued.isEmpty && changedAccount.persisted == 0)

        let metered = store()
        NetworkQuality.shared.metered = true
        let beforeMetered = InnertubeDetail.shared.requests
        metered.checkPlaylistUpdates(force: true)
        await metered.waitForPlaylistUpdates()
        assert(InnertubeDetail.shared.requests == beforeMetered)

        let large = store()
        let fresh = (0..<51).map { "new-\($0)" }
        InnertubeDetail.shared.pages = [page(fresh)]
        large.checkPlaylistUpdates(force: true)
        await large.waitForPlaylistUpdates()
        assert(large.enqueued.isEmpty && large.pendingPlaylistUpdates == 51)
        InnertubeDetail.shared.pages = [page(fresh)]
        large.checkPlaylistUpdates(force: true, allowLargeBatch: true)
        await large.waitForPlaylistUpdates()
        assert(large.enqueued.count == 51)

        let loop = store()
        InnertubeDetail.shared.pages = [page(["new"], next: "loop"), page(["new2"], next: "loop")]
        loop.checkPlaylistUpdates(force: true)
        await loop.waitForPlaylistUpdates()
        assert(loop.enqueued.isEmpty && loop.persisted == 0)

        let removedOnline = store()
        InnertubeDetail.shared.pages = [page([])]
        removedOnline.checkPlaylistUpdates(force: true)
        await removedOnline.waitForPlaylistUpdates()
        assert(removedOnline.index.owners["playlist"]?.requests == ["kept"])

        let stopped = store()
        InnertubeDetail.shared.pages = [page(["new"])]
        InnertubeDetail.shared.onPage = { stopped.setAppActive(false) }
        stopped.checkPlaylistUpdates(force: true)
        await stopped.waitForPlaylistUpdates()
        assert(stopped.enqueued.isEmpty && stopped.persisted == 0)
        print("ok: 9 asynchrone Produktionsfälle für Playlist-Abgleich mit kontrollierten Adaptern")
    }
}
