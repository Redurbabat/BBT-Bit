import Foundation

/// Ergänzungsjournal: bekannte IDs bleiben auch nach einer bewussten Löschung bekannt.
struct PlaylistSyncRecord: Codable, Equatable, Sendable {
    var seenEntryIDs: Set<String>

    func additions(listing: [String]) -> [String] {
        var known = seenEntryIDs
        return listing.filter { known.insert($0).inserted }
    }

    mutating func handled(_ entryID: String) { seenEntryIDs.insert(entryID) }
}

enum PlaylistSyncPolicy {
    static let largeBatch = 50
    static func due(lastComplete: Date?, now: Date, foreground: Bool) -> Bool {
        guard let lastComplete else { return true }
        return now.timeIntervalSince(lastComplete) >= (foreground ? 6 : 12) * 3600
    }

    static func browseID(_ value: String) -> String? {
        let id = value.hasPrefix("VL") ? String(value.dropFirst(2)) : value
        guard id.hasPrefix("PL") || id.hasPrefix("RD") || id.hasPrefix("LM") else { return nil }
        return "VL" + id
    }
}
