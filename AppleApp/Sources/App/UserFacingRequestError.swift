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
        if lower.contains("not a bot") || lower.contains("confirm you are not a bot") ||
            lower.contains("confirm it isn't a bot") || lower.contains("confirm it isn’t a bot") {
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

    private static func isOffline(_ lower: String) -> Bool {
        lower.contains("code=-1009") || lower.contains("code = -1009") ||
        lower.contains("no network route") || lower.contains("network is unreachable") ||
        lower.contains("notconnectedtointernet") ||
        lower.contains("keine verbindung zum internet")
    }

    private static let offlineMessage =
        "BBT-Bit cannot access the internet. On iPhone, check Settings > Cellular > BBT-Bit (allow mobile data), Wi-Fi, and VPN, then retry."
}
