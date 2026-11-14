import Foundation

enum HomeMediaFilter: String, CaseIterable, Identifiable {
    case all, music, videos
    var id: String { rawValue }
    var title: String {
        switch self { case .all: "Alle"; case .music: "Musik"; case .videos: "Videos" }
    }
    func includes(video: Bool) -> Bool {
        switch self { case .all: true; case .music: !video; case .videos: video }
    }
}

enum HomeMixMood: String, CaseIterable, Identifiable {
    case balanced, familiar, curious
    var id: String { rawValue }
    var title: String {
        switch self { case .balanced: "Gemischt"; case .familiar: "Vertraut"; case .curious: "Neugierig" }
    }
}

enum HomeDayPart: String {
    case morning, day, evening, night
    var title: String {
        switch self {
        case .morning: "Dein Morgenmix"
        case .day: "Dein Tagesmix"
        case .evening: "Dein Abendmix"
        case .night: "Dein Nachtmix"
        }
    }
    static func at(_ date: Date, calendar: Calendar = .current) -> HomeDayPart {
        switch calendar.component(.hour, from: date) {
        case 5..<11: .morning
        case 11..<17: .day
        case 17..<23: .evening
        default: .night
        }
    }
}

enum HomeMixBuilder {
    static func build(history: [QueueEntry], feed: [QueueEntry], mood: HomeMixMood,
                      date: Date, calendar: Calendar = .current, limit: Int = 24) -> [QueueEntry] {
        guard limit > 0 else { return [] }
        let known = Set(history.map(\.id))
        let knownRecordings = Set(history.map(recordingKey))
        let seed = "\(calendar.startOfDay(for: date).timeIntervalSince1970)-\(HomeDayPart.at(date, calendar: calendar).rawValue)"
        let fresh = feed.filter { !known.contains($0.id) && !knownRecordings.contains(recordingKey($0)) }.sorted {
            let a = stableRank(seed + $0.id), b = stableRank(seed + $1.id)
            return a == b ? $0.id < $1.id : a < b
        }
        var candidates: [QueueEntry] = []
        switch mood {
        case .curious: candidates = fresh
        case .familiar:
            for i in 0..<max(history.count, fresh.count) {
                if history.indices.contains(i) { candidates.append(history[i]) }
                if i % 3 == 0, fresh.indices.contains(i / 3) { candidates.append(fresh[i / 3]) }
            }
            candidates += fresh
        case .balanced:
            for i in 0..<max(history.count, fresh.count) {
                if fresh.indices.contains(i) { candidates.append(fresh[i]) }
                if history.indices.contains(i) { candidates.append(history[i]) }
            }
        }
        var ids: Set<String> = [], recordings: Set<String> = []
        return Array(candidates.filter { entry in
            guard !entry.isVideo, entry.source.hasPrefix("yt:"),
                  isYouTubeID(entry.videoId ?? "") else { return false }
            let recording = recordingKey(entry)
            guard !ids.contains(entry.id), !recordings.contains(recording) else { return false }
            ids.insert(entry.id); recordings.insert(recording)
            return true
        }.prefix(min(limit, 100)))
    }

    static func isYouTubeID(_ id: String) -> Bool {
        id.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil
    }

    private static func stableRank(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    private static func recordingKey(_ entry: QueueEntry) -> String {
        (entry.title + "|" + entry.artist).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
