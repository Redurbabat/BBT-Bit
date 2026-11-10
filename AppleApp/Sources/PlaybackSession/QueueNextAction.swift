import Foundation

@MainActor enum QueueNextAction {
    struct Receipt { let title: String; let first: QueueEntry; let count: Int }

    static func stamp(_ controller: PlaybackController) -> QueueActionStamp {
        QueueActionStamp(session: PageSession.generation(), playback: controller.playGeneration,
            currentID: controller.current?.id, queueRevision: controller.queueEditRevision)
    }

    static func insert(_ target: QueueDragTarget, into controller: PlaybackController) async throws -> Receipt {
        let probe = AppTestEvents.begin(.queueNext)
        do {
            let receipt = try await performInsert(target, into: controller)
            AppTestEvents.finish(probe, .success, .queueUpdated)
            return receipt
        } catch is CancellationError { throw CancellationError() }
        catch QueueCollectionError.changed {
            AppTestEvents.finish(probe, .observation, .validState)
            throw QueueCollectionError.changed
        } catch QueueCollectionError.party {
            AppTestEvents.finish(probe, .unavailable, .validState)
            throw QueueCollectionError.party
        } catch {
            AppTestEvents.finish(probe, .failure, .requestFailed)
            throw error
        }
    }

    private static func performInsert(_ target: QueueDragTarget, into controller: PlaybackController) async throws -> Receipt {
        guard !PartyStore.shared.inParty else { throw QueueCollectionError.party }
        let request = stamp(controller)
        let entries: [QueueEntry], title: String
        switch target {
        case .track(let entry): entries = [entry]; title = entry.title
        case .collection(let browseID, let name):
            title = name
            entries = try await QueueCollectionLoader.load(first: {
                guard stamp(controller) == request else { throw QueueCollectionError.changed }
                let page: DetailPageModel
                if !NetworkQuality.shared.connected,
                   let offline = DetailPageModel.downloadedCopy(browseId: browseID, from: DownloadStore.shared) {
                    page = offline
                } else { page = try await InnertubeDetail.shared.browse(browseId: browseID) }
                return QueueCollectionPage(entries: page.songs.map { $0.asEntry(fallbackArt: page.thumbnailUrl) }, continuation: page.continuation)
            }, more: { token in
                guard stamp(controller) == request else { throw QueueCollectionError.changed }
                let page = try await InnertubeDetail.shared.more(token: token)
                return QueueCollectionPage(entries: page.songs.map { $0.asEntry(fallbackArt: page.thumbnailUrl) }, continuation: page.continuation)
            })
        }
        try Task.checkCancellation()
        guard !PartyStore.shared.inParty else { throw QueueCollectionError.party }
        guard stamp(controller) == request else { throw QueueCollectionError.changed }
        guard let first = entries.first else { throw QueueCollectionError.empty }
        controller.playNext(entries)
        return Receipt(title: title, first: first, count: entries.count)
    }
}
