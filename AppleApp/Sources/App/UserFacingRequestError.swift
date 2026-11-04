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
            return AppLanguage.localized("YouTube is requiring verification for this network. BBT-Bit cannot complete that check for you; try again later or use the official YouTube Music service.")
        }
        // The FFI bridge can include a full NSError dump (request URLs, task
        // identifiers and nested UserInfo). Those belong in diagnostics, not UI.
        let firstLine = raw.components(separatedBy: .newlines).first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if firstLine.isEmpty || firstLine.count > 220 ||
            firstLine.contains("UserInfo=") || firstLine.contains("Error Domain=") {
            return AppLanguage.localized("The request failed. Check your connection and try again.")
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

    private static var offlineMessage: String {
        AppLanguage.localized("BBT-Bit cannot access the internet. On iPhone, check Settings > Cellular > BBT-Bit (allow mobile data), Wi-Fi, and VPN, then retry.")
    }
}

struct YouTubeStreamError: Error, LocalizedError {
    /// The sentence a listener sees.
    let message: String
    /// What the shared module said, in full.
    ///
    /// Kept rather than discarded because it is the only place the per-client
    /// reasons exist and they are what a bug report needs. Never shown: it
    /// contains a video id and internal client names.
    let raw: String

    init(message: String, raw: String? = nil) {
        self.message = message
        self.raw = raw ?? message
    }

    enum Reason: String {
        case noPlayableStream = "NO_PLAYABLE_STREAM"
        case explicitUnsupported = "EXPLICIT_UNSUPPORTED"
        case ageRestricted = "AGE_RESTRICTED"
        case unavailable = "UNAVAILABLE"
        case botChecked = "BOT_CHECKED"
        case network = "NETWORK"
        case cancelled = "CANCELLED"

        init?(bridgeMessage: String) {
            guard let marker = bridgeMessage.range(of: "[reason=", options: .backwards) else { return nil }
            let code = bridgeMessage[marker.upperBound...].prefix { $0 != "," && $0 != "]" }
            self.init(rawValue: String(code))
        }
    }

    var errorDescription: String? { message }
    var reason: Reason? { Reason(bridgeMessage: raw) }

    var stopsAutomaticDownloadRetry: Bool {
        switch reason {
        case .noPlayableStream, .explicitUnsupported, .ageRestricted, .unavailable, .botChecked, .cancelled: return true
        case .network, nil: return Self.isBotCheck(self)
        }
    }

    var canTryCounterpart: Bool {
        if Self.isBotCheck(self) { return false }
        return reason == nil || reason == .noPlayableStream
    }

    static func isBotCheck(_ error: Error) -> Bool {
        let stream = error as? YouTubeStreamError
        return stream?.reason == .botChecked ||
            UserFacingRequestError.isYouTubeVerification(stream?.raw ?? error.localizedDescription)
    }

    /// Present the known bridge category without internal client diagnostics.
    static func say(_ raw: String) -> String {
        let said = raw.lowercased()
        if said.contains("code=-1009") || said.contains("no network route") ||
            said.contains("keine verbindung zum internet") {
            return UserFacingRequestError.message(raw)
        }
        switch Reason(bridgeMessage: raw) {
        case .noPlayableStream, .explicitUnsupported:
            return AppLanguage.localized("YouTube didn’t provide a compatible audio stream for this track.")
        case .ageRestricted:
            return AppLanguage.localized("This YouTube track requires age verification.")
        case .unavailable:
            return AppLanguage.localized("That track isn’t available right now.")
        case .network:
            return AppLanguage.localized("Couldn’t reach YouTube to open the audio stream. Check your connection and try again.")
        case .cancelled:
            return AppLanguage.localized("Stream resolution was cancelled.")
        case .botChecked:
            return UserFacingRequestError.message("YouTube is requiring verification for this network")
        case nil:
            break
        }
        if said.contains("signed-in playback:") {
            return AppLanguage.localized("Your signed-in session could not be restored. Check your connection or sign in again.")
        }
        if said.contains("temporarily unavailable") {
            return AppLanguage.localized("Playback is temporarily unavailable. Try again shortly.")
        }
        if UserFacingRequestError.isYouTubeVerification(raw) {
            return UserFacingRequestError.message(raw)
        }
        if said.contains("sign in") {
            return AppLanguage.localized("YouTube is asking this device to sign in before it will serve anything. That is YouTube's gate rather than anything to do with the track.")
        }
        if said.contains("needs to be reloaded") || said.contains("page needs") {
            return AppLanguage.localized("YouTube's player refused this connection. Trying again in a moment usually clears it.")
        }
        if said.contains("unavailable") || said.contains("not available") {
            return AppLanguage.localized("That track isn’t available right now.")
        }
        if said.contains("no signature timestamp") {
            return AppLanguage.localized("BitChord could not read YouTube’s player, so it could not open a stream. Check the connection and try again.")
        }
        return AppLanguage.localized("Couldn’t open a stream for that track.")
    }
}
