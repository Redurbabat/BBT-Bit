import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

@main enum FeedLoadingChecks {
    @MainActor static func main() async {
        let watchdog = Task {
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            print("FEHLER: Feed-Prüfung wartet unerwartet auf einen kontrollierten Dienst")
            exit(2)
        }
        defer { watchdog.cancel() }
        var failures = 0, checks = 0
        func expect(_ condition: Bool, _ message: String) {
            checks += 1
            if !condition { failures += 1; print("FEHLER: \(message)") }
        }
        func card(_ id: Int, video: Bool = false) -> ShelfCard {
            ShelfCard(title: "Titel \(id)", videoId: String(format: "track%06d", id), isVideo: video)
        }
        func rows(_ loader: FeedLoader) -> [FeedShelf] {
            if case .loaded(let rows) = loader.phase { return rows }
            return []
        }
        let backend = InnertubeFeed.shared, content = LaunchReadiness.shared.content
        let loader = FeedLoader(.home)
        let initial = FeedResult(shelves: [FeedShelf(title: "Trending", items: [card(1)])], continuation: "page1")
        let first = Task { await loader.load(force: false, epoch: 1) }
        await backend.streamsStarted.wait(for: 1)
        backend.streams[0].yield(initial)
        await content.wait(for: 1)
        expect(!loader.canLoadMore, "Während des progressiven Erstladens darf keine Folgeseite angeboten werden")
        backend.immediate = .success(FeedResult(shelves: [], continuation: "page1"))
        await loader.loadMore()
        expect(backend.tokens.isEmpty, "Während des Erstladens darf kein Continuation-Request starten")
        backend.streams[0].yield(initial)
        await content.wait(for: 2)
        backend.streams[0].finish(); await first.value
        expect(loader.canLoadMore, "Nach vollständigem Erstladen muss die Folgeseite erreichbar sein")
        backend.immediate = .success(FeedResult(shelves: [
            FeedShelf(title: "Trending", items: [card(1), card(2, video: true), card(3)]),
            FeedShelf(title: "Weitere Musik", items: [card(4), card(4)])
        ], continuation: "page2"))
        await loader.loadMore()
        expect(rows(loader).map(\.title) == ["Trending", "Weitere Musik"], "Regalreihenfolge erhalten")
        expect(rows(loader).first?.items.map(\.id) == [card(1), card(2), card(3)].map(\.id),
            "Zusätzliche Titel desselben Regals dürfen nicht verschwinden")
        expect(rows(loader).first?.items.filter(\.isVideo).count == 1, "Nachgeladene Videos müssen filterbar bleiben")
        expect(rows(loader).last?.items.count == 1, "Doppelte Karten einer neuen Zeile zusammenführen")
        let before = rows(loader)
        backend.immediate = .failure(URLError(.timedOut))
        await loader.loadMore()
        expect(rows(loader) == before && loader.refreshError != nil, "Fehler erhält den lesbaren Feed")
        expect(!loader.loadingMore && loader.canLoadMore, "Fehler beendet Spinner und erlaubt Wiederholung")
        backend.immediate = .success(FeedResult(shelves: [], continuation: "retry"))
        await loader.loadMore()
        expect(loader.refreshError == nil, "Erfolgreiche Wiederholung muss den alten Fehler zurücksetzen")

        backend.immediate = nil
        let oldPage = Task { await loader.loadMore() }
        await backend.moreStarted.wait(for: 1)
        PageSession.value += 1
        let switched = Task { await loader.load(force: true, epoch: 2) }
        await backend.streamsStarted.wait(for: 2)
        backend.streams[1].yield(FeedResult(shelves: [FeedShelf(title: "Neues Konto", items: [card(10)])], continuation: "new1"))
        await content.wait(for: 3)
        backend.streams[1].finish(); await switched.value
        expect(!loader.loadingMore && loader.canLoadMore, "Alte Folgeseite darf das neue Konto nicht blockieren")
        if !loader.loadingMore {
            let newPage = Task { await loader.loadMore() }
            await backend.moreStarted.wait(for: 2)
            backend.more[0].resume(returning: FeedResult(shelves: [FeedShelf(title: "Altes Konto", items: [card(11)])], continuation: nil))
            await oldPage.value
            expect(loader.loadingMore, "Alte Antwort darf den Spinner des neuen Requests nicht beenden")
            expect(rows(loader).map(\.title) == ["Neues Konto"], "Alte Kontoantwort verwerfen")
            newPage.cancel()
            backend.more[1].resume(returning: FeedResult(shelves: [FeedShelf(title: "Abgebrochen", items: [card(12)])], continuation: nil))
            await newPage.value
            expect(rows(loader).map(\.title) == ["Neues Konto"] && !loader.loadingMore,
                "Abgebrochene Folgeseite darf den Feed nicht verändern")
        } else {
            backend.more[0].resume(throwing: URLError(.cancelled)); await oldPage.value
        }

        let empty = FeedLoader(.explore)
        let emptyLoad = Task { await empty.load(force: false, epoch: 2) }
        await backend.streamsStarted.wait(for: 3)
        backend.streams[2].yield(FeedResult(shelves: [], continuation: nil))
        backend.streams[2].finish(); await emptyLoad.value
        if case .loaded(let shelves) = empty.phase {
            expect(shelves.isEmpty && !empty.canLoadMore, "Leerer Feed endet ohne Spinner")
        } else { expect(false, "Erfolgreicher leerer Feed darf nicht im Ladezustand bleiben") }

        let moreIndex = backend.more.count, streamIndex = backend.streams.count
        let nextContent = content.count + 1
        let lateError = Task { await loader.loadMore() }
        await backend.moreStarted.wait(for: moreIndex + 1)
        let refreshed = Task { await loader.load(force: true, epoch: 2) }
        await backend.streamsStarted.wait(for: streamIndex + 1)
        backend.streams[streamIndex].yield(FeedResult(shelves: [FeedShelf(title: "Frisch", items: [card(20)])], continuation: "fresh1"))
        await content.wait(for: nextContent)
        backend.streams[streamIndex].finish(); await refreshed.value
        backend.more[moreIndex].resume(throwing: URLError(.timedOut)); await lateError.value
        expect(loader.refreshError == nil && rows(loader).map(\.title) == ["Frisch"],
            "Verspäteter Fehler vor Pull-to-refresh darf den frischen Feed nicht verändern")
        expect(loader.canLoadMore && !loader.loadingMore, "Pull-to-refresh erhält erreichbare Folgeseiten")

        print("\(checks) Feed-Prüfungen: \(checks - failures) bestanden, \(failures) fehlgeschlagen")
        if failures > 0 { exit(1) }
    }
}
