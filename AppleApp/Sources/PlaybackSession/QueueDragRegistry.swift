import Foundation

struct QueueDragTicket: Codable, Hashable, Sendable { let token: UUID }

enum QueueDragTarget: Sendable {
    case track(QueueEntry)
    case collection(browseID: String, title: String)
}

/// Nur eine kurzlebige Einmal-Kennung verlässt den View. Metadaten, lokale
/// Pfade und Stream-Adressen bleiben in diesem prozessinternen Register.
struct QueueDragRegistry {
    private struct Stored {
        let target: QueueDragTarget
        let session: Int64
        let created: TimeInterval
    }
    private var entries: [UUID: Stored] = [:]

    mutating func register(_ target: QueueDragTarget, session: Int64, now: TimeInterval) -> QueueDragTicket {
        entries = entries.filter { $0.value.session == session && now - $0.value.created < 120 && now >= $0.value.created }
        if entries.count >= 24, let oldest = entries.min(by: { $0.value.created < $1.value.created })?.key {
            entries.removeValue(forKey: oldest)
        }
        let ticket = QueueDragTicket(token: UUID())
        entries[ticket.token] = Stored(target: target, session: session, created: now)
        return ticket
    }

    mutating func claim(_ ticket: QueueDragTicket, session: Int64, now: TimeInterval) -> QueueDragTarget? {
        guard let saved = entries.removeValue(forKey: ticket.token), saved.session == session,
              now >= saved.created, now - saved.created < 120 else { return nil }
        return saved.target
    }
}

struct QueueActionStamp: Equatable {
    let session: Int64
    let playback: UInt64
    let currentID: String?
    let queueRevision: UInt64
}

struct QueueCollectionPage: Sendable {
    let entries: [QueueEntry]
    let continuation: String?
}

enum QueueCollectionError: LocalizedError {
    case empty, incomplete, changed, party
    var errorDescription: String? {
        switch self {
        case .empty: "Diese Sammlung enthält keine abspielbaren Titel."
        case .incomplete: "Die Sammlung konnte nicht vollständig geladen werden. Bitte öffne sie und versuche es erneut."
        case .changed: "Die Wiedergabe oder das Konto wurde geändert. Bitte erneut einreihen."
        case .party: "Verwende während Gemeinsam hören bitte die gemeinsame Warteschlange."
        }
    }
}

@MainActor enum QueueCollectionLoader {
    static func load(first: () async throws -> QueueCollectionPage,
                     more: (String) async throws -> QueueCollectionPage) async throws -> [QueueEntry] {
        try Task.checkCancellation()
        var page = try await first()
        try Task.checkCancellation()
        var entries = page.entries, tokens: Set<String> = []
        guard entries.count <= 500 else { throw QueueCollectionError.incomplete }
        while let token = page.continuation, !token.isEmpty {
            guard tokens.count < 20, tokens.insert(token).inserted else { throw QueueCollectionError.incomplete }
            page = try await more(token)
            try Task.checkCancellation()
            guard entries.count + page.entries.count <= 500 else { throw QueueCollectionError.incomplete }
            entries += page.entries
        }
        guard !entries.isEmpty else { throw QueueCollectionError.empty }
        return entries
    }
}
