import Foundation

@main enum HomeDiscoveryChecks {
    static func song(_ suffix: Int, title: String? = nil, video: Bool = false) -> QueueEntry {
        .youtube(videoId: String(format: "track%06d", suffix), title: title ?? "Song \(suffix)", artist: "Artist", isVideo: video)
    }

    @MainActor static func main() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 19))!
        assert(HomeDayPart.at(date, calendar: calendar) == .evening)
        assert(HomeDayPart.at(calendar.date(byAdding: .hour, value: 5, to: date)!, calendar: calendar) == .night)
        assert(HomeMediaFilter.all.includes(video: true) && HomeMediaFilter.music.includes(video: false))
        assert(!HomeMediaFilter.music.includes(video: true) && !HomeMediaFilter.videos.includes(video: false))
        let history = [song(1), song(2)]
        let feed = [song(1), song(3), song(4), song(5, title: "SONG 1"), song(6, video: true)]
        let first = HomeMixBuilder.build(history: history, feed: feed, mood: .balanced, date: date, calendar: calendar)
        let second = HomeMixBuilder.build(history: history, feed: feed, mood: .balanced, date: date.addingTimeInterval(30), calendar: calendar)
        assert(first.map(\.id) == second.map(\.id))
        assert(first.count == 4 && Set(first.map(\.id)).count == 4)
        assert(!first.contains { $0.isVideo })
        let curious = HomeMixBuilder.build(history: history, feed: feed, mood: .curious, date: date, calendar: calendar)
        assert(Set(curious.map(\.id)) == Set([song(3).id, song(4).id]))
        assert(HomeMixBuilder.build(history: [], feed: [], mood: .familiar, date: date).isEmpty)
        assert(HomeMixBuilder.build(history: history, feed: feed, mood: .balanced, date: date, limit: 0).isEmpty)
        assert(HomeMixBuilder.build(history: history, feed: feed, mood: .balanced, date: date, limit: 2).count == 2)
        print("BESTANDEN: Home-Filter, Tageszeit, stabile Auswahl, Modi, Video-/Aufnahme-Deduplikation und leere Daten")

        var registry = QueueDragRegistry()
        let ticket = registry.register(.track(song(1)), session: 1, now: 10)
        let encoded = try JSONEncoder().encode(ticket)
        let payload = String(decoding: encoded, as: UTF8.self)
        assert(!payload.contains("track") && !payload.contains("source") && !payload.contains("http"))
        let decoded = try JSONDecoder().decode(QueueDragTicket.self, from: encoded)
        assert(registry.claim(decoded, session: 1, now: 20) != nil)
        assert(registry.claim(ticket, session: 1, now: 21) == nil)
        let stale = registry.register(.track(song(2)), session: 1, now: 30)
        assert(registry.claim(stale, session: 2, now: 31) == nil)
        let expired = registry.register(.track(song(3)), session: 2, now: 40)
        assert(registry.claim(expired, session: 2, now: 161) == nil)
        assert(registry.claim(QueueDragTicket(token: UUID()), session: 2, now: 162) == nil)
        print("BESTANDEN: Einmal-Drag ohne Mediendaten, Kontogrenze, Ablauf und unbekannte Tickets")

        func page(_ entries: [QueueEntry], next: String? = nil) -> DetailPageModel {
            DetailPageModel(title: "Album", songs: entries.map { .init(entry: $0) }, continuation: next)
        }
        func reset(_ pages: [DetailPageModel]) {
            InnertubeDetail.shared.pages = pages; InnertubeDetail.shared.onPage = nil
            PartyStore.shared.inParty = false; NetworkQuality.shared.connected = true; DetailPageModel.offline = nil
        }
        let controller = PlaybackController(); controller.queue = [song(90)]
        reset([page([song(1), song(2)], next: "page2"), page([song(3)])])
        let receipt = try await QueueNextAction.insert(.collection(browseID: "MPRE1", title: "Album"), into: controller)
        assert(receipt.count == 3 && controller.queue.map(\.id) == [song(90), song(1), song(2), song(3)].map(\.id))
        assert(controller.loads == 0 && controller.current?.id == song(90).id)
        let before = controller.queue
        reset([page([song(4)], next: "missing")])
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Partial"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)], next: "loop"), page([song(5)], next: "loop")])
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Loop"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page((0..<501).map { song($0) })])
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Huge"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)])]); InnertubeDetail.shared.onPage = { controller.playGeneration += 1 }
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Stale"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)])]); InnertubeDetail.shared.onPage = { PageSession.value += 1 }
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Account"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)])]); InnertubeDetail.shared.onPage = { controller.queueEditRevision += 1 }
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Queue"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)])]); InnertubeDetail.shared.onPage = { PartyStore.shared.inParty = true }
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Party"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([page([song(4)])])
        let cancelled = Task { @MainActor in
            try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Cancel"), into: controller)
        }
        InnertubeDetail.shared.onPage = { cancelled.cancel() }
        do { _ = try await cancelled.value; assertionFailure() }
        catch is CancellationError { assert(controller.queue == before) }
        catch { assertionFailure("Abbruch muss als Cancellation enden") }
        reset((0..<22).map { page([song($0)], next: "page\($0)") })
        do { _ = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Pages"), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([]); NetworkQuality.shared.connected = false; DetailPageModel.offline = page([song(8), song(9)])
        let offline = try await QueueNextAction.insert(.collection(browseID: "MPRE2", title: "Offline"), into: controller)
        assert(offline.count == 2 && controller.queue[1].id == song(8).id)
        controller.queue = before
        reset([]); PartyStore.shared.inParty = true
        do { _ = try await QueueNextAction.insert(.track(song(1)), into: controller); assertionFailure() }
        catch { assert(controller.queue == before) }
        reset([])
        _ = try await QueueNextAction.insert(.track(song(7)), into: controller)
        assert(controller.queue[1].id == song(7).id && controller.current?.id == song(90).id)
        let idle = PlaybackController(); idle.isIdle = true
        _ = try await QueueNextAction.insert(.track(song(8)), into: idle)
        assert(idle.current?.id == song(8).id && idle.loads == 1)
        print("BESTANDEN: Produktions-Queue-Aktion und Batch-Reihenfolge, Teillisten, Schleifen, Grenzen, veraltete Auswahl, Konto und Party")

        let card = ShelfCard(title: "Album", browseId: "MPRE1")
        assert(card.supportsCollectionPeek)
        assert(!ShelfCard(title: "Artist", browseId: "UC123").supportsCollectionPeek)
        let paired = ShelfCard(title: "Track or collection", videoId: song(1).id, browseId: "MPRE1")
        if case .collection? = paired.queueDragTarget(preferTrack: false) {} else { assertionFailure() }
        if case .track? = paired.queueDragTarget(preferTrack: true) {} else { assertionFailure() }
        let peek = AlbumPeekModel()
        reset([page([song(1), song(2), song(3), song(4)])])
        await peek.load(card)
        if case .loaded(let entries) = peek.phase { assert(entries.count == 3) } else { assertionFailure() }
        reset([]); await peek.load(card)
        if case .failed = peek.phase {} else { assertionFailure() }
        reset([page([song(8)])]); InnertubeDetail.shared.onPage = { PageSession.value += 1 }
        await peek.load(card)
        if case .loaded = peek.phase { assertionFailure("Fremde Kontoantwort übernommen") }
        let model = HomeDiscoveryModel()
        reset([]); PlaylistPinning.ids = []
        ListeningStore.shared.songs = [.init(id: song(1).id, title: "History", artist: "Artist", last: 10)]
        let shelves = [FeedShelf(title: "Feed", items: [ShelfCard(title: "Video", videoId: song(1).id, isVideo: true),
            ShelfCard(title: "Song", videoId: song(2).id), card])]
        await model.refresh(shelves: shelves, session: PageSession.generation())
        assert(model.history.isEmpty && model.feedTracks.count == 1 && model.collections.count == 1)
        await model.refresh(shelves: shelves, session: PageSession.generation() - 1)
        assert(model.feedTracks.isEmpty && model.history.isEmpty && model.collections.isEmpty)
        reset([page([song(3)])]); PlaylistPinning.ids = ["VLone", "VLtwo", "VLthree"]
        await model.refresh(shelves: [], session: PageSession.generation())
        assert(model.pins.count == 2 && model.pins[0].title == "Album")
        assert(model.pins[1].title == "Angeheftete Playlist" && model.pins[1].browseId == "VLtwo")
        reset([page([song(3)])]); InnertubeDetail.shared.onPage = { model.clear() }
        await model.refresh(shelves: [], session: PageSession.generation())
        assert(model.pins.isEmpty && !model.pinsLoading)
        print("BESTANDEN: Drei echte Preview-Titel, Fehler, Kontogrenze und Home-Datenmodell ohne Playback-Aufruf")
    }
}
