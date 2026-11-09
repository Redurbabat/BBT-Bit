import Foundation

/// Antworten gelten nur für die Auswahl und das Konto, die sie angefordert haben.
struct AutoplaySeedState {
    struct Request: Equatable {
        let token: UUID
        let entryID: String
        let playbackGeneration: UInt64
        let sessionGeneration: Int64
    }
    private(set) var pending: Request?
    private var seeds: [String: String] = [:]
    private var session: Int64?
    private var retryAfter: [String: Date] = [:]

    mutating func seed(for entryID: String, sessionGeneration: Int64) -> String? {
        resetSession(sessionGeneration)
        return seeds[entryID]
    }

    mutating func begin(entryID: String, playbackGeneration: UInt64, sessionGeneration: Int64, now: Date) -> Request? {
        resetSession(sessionGeneration)
        guard seeds[entryID] == nil, (retryAfter[entryID] ?? .distantPast) <= now else { return nil }
        if let pending, pending.entryID == entryID, pending.playbackGeneration == playbackGeneration { return nil }
        let request = Request(token: UUID(), entryID: entryID,
            playbackGeneration: playbackGeneration, sessionGeneration: sessionGeneration)
        pending = request
        return request
    }

    @discardableResult
    mutating func finish(_ request: Request, seed: String?, currentID: String?, playbackGeneration: UInt64,
                         sessionGeneration: Int64, now: Date) -> Bool {
        guard pending == request else { return false }
        pending = nil
        guard request.entryID == currentID, request.playbackGeneration == playbackGeneration,
              request.sessionGeneration == sessionGeneration else { return false }
        guard let seed, seed.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil else {
            retryAfter[request.entryID] = now.addingTimeInterval(15)
            return false
        }
        if seeds.count >= 32 { seeds.removeAll(); retryAfter.removeAll() }
        seeds[request.entryID] = seed
        return true
    }

    private mutating func resetSession(_ value: Int64) {
        guard session != value else { return }
        session = value; seeds.removeAll(); retryAfter.removeAll(); pending = nil
    }
}
