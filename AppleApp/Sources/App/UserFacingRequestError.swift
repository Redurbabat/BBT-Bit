import Foundation

/// Presents recoverable network failures without exposing URLSession/Kotlin
/// exception internals. The shared Kotlin bridge can wrap a native NSError in
/// a message string, so classify both direct NSError values and nested text.
enum UserFacingRequestError {
    static func message(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == URLError.notConnectedToInternet.rawValue {
            return offlineMessage
        }
        return message(error.localizedDescription)
    }

    static func message(_ raw: String) -> String {
        let lower = raw.lowercased()
        if isOffline(lower) { return offlineMessage }
        if isYouTubeVerification(raw) {
            return "YouTube is requiring verification for this network. BBT-Bit cannot complete that check for you; try again later or use the official YouTube Music service."
        }
        // The FFI bridge can include a full NSError dump (request URLs, task
        // identifiers and nested UserInfo). Those belong in diagnostics, not UI.
        let firstLine = raw.components(separatedBy: .newlines).first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if firstLine.isEmpty || firstLine.count > 220 ||
            firstLine.contains("UserInfo=") || firstLine.contains("Error Domain=") {
            return "The request failed. Check your connection and try again."
        }
        return firstLine
    }

    /// This is a service/network-wide gate, not evidence that a particular song
    /// is unavailable. Keep its classification consistent in the resolver and UI.
    static func isYouTubeVerification(_ raw: String) -> Bool {
        let lower = raw.lowercased()
        return lower.contains("not a bot") ||
            lower.contains("isn't a bot") || lower.contains("isn’t a bot") ||
            lower.contains("verification for this network") ||
            (lower.contains("youtube") && lower.contains("captcha"))
    }

    /// Only construct an official link for a canonical YouTube video identifier.
    /// Reject paths, query fragments, and arbitrary IDs from external catalogues.
    static func youtubeWatchURL(forVideoID videoID: String?) -> URL? {
        guard let videoID, videoID.utf8.count == 11,
              videoID.utf8.allSatisfy({ byte in
                  (65...90).contains(byte) || (97...122).contains(byte) ||
                  (48...57).contains(byte) || byte == 45 || byte == 95
              }) else { return nil }
        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.youtube.com"
        url.path = "/watch"
        url.queryItems = [URLQueryItem(name: "v", value: videoID)]
        return url.url
    }

    private static func isOffline(_ lower: String) -> Bool {
        lower.contains("code=-1009") || lower.contains("code = -1009") ||
        lower.contains("no network route") || lower.contains("network is unreachable") ||
        lower.contains("notconnectedtointernet") ||
        lower.contains("keine verbindung zum internet")
    }

    private static let offlineMessage =
        "BBT-Bit cannot access the internet. On iPhone, check Settings > Cellular > BBT-Bit (allow mobile data), Wi-Fi, and VPN, then retry."
}
