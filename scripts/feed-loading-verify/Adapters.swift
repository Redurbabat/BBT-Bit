import Foundation

// Kontrollierte Dienste; der vollständige FeedLoader stammt aus der Produktion.
struct PageContext: Equatable { let generation: Int64 }
@MainActor enum PageSession {
    static var value: Int64 = 1
    static func generation() -> Int64 { value }
    static func capture() -> PageContext { PageContext(generation: value) }
}
@MainActor final class EventCounter {
    private(set) var count = 0
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []
    func signal() {
        count += 1
        let ready = waiters.filter { $0.0 <= count }
        waiters.removeAll { $0.0 <= count }
        for (_, waiter) in ready { waiter.resume() }
    }
    func wait(for count: Int) async {
        if self.count >= count { return }
        await withCheckedContinuation { waiters.append((count, $0)) }
    }
}
@MainActor final class LaunchReadiness {
    static let shared = LaunchReadiness()
    let content = EventCounter()
    func contentAppeared() async { content.signal() }
}
@MainActor final class PlaybackDebugLog {
    static let shared = PlaybackDebugLog()
    func record(_ message: String) {}
}
@MainActor enum AuthController { static func reportIfSessionExpired(_ error: Error) {} }
enum UserFacingRequestError { static func message(_ error: Error) -> String { error.localizedDescription } }
@MainActor final class InnertubeFeed {
    static let shared = InnertubeFeed()
    let streamsStarted = EventCounter(), moreStarted = EventCounter()
    var streams: [AsyncThrowingStream<FeedResult, Error>.Continuation] = []
    var more: [CheckedContinuation<FeedResult, Error>] = []
    var tokens: [String] = []
    var immediate: Result<FeedResult, Error>?
    func progressive(home: Bool) -> AsyncThrowingStream<FeedResult, Error> {
        AsyncThrowingStream { continuation in
            streams.append(continuation); streamsStarted.signal()
        }
    }
    func moreHome(token: String) async throws -> FeedResult { try await take(token) }
    func moreExplore(token: String) async throws -> FeedResult { try await take(token) }
    private func take(_ token: String) async throws -> FeedResult {
        tokens.append(token)
        if let immediate { return try immediate.get() }
        return try await withCheckedThrowingContinuation { continuation in
            more.append(continuation); moreStarted.signal()
        }
    }
}
