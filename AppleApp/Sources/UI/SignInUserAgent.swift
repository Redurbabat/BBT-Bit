import Foundation
#if os(iOS)
import UIKit
#endif

/// Browser identity for the sign-in page and its matching account-menu request.
///
/// Google can refuse authentication inside WKWebView. Pretending that an iPhone
/// is a Mac did not make the login trustworthy; it also caused Google to list
/// a misleading macOS device under recent account activity. This file now
/// reports the actual platform. A genuine system-browser OAuth flow is needed
/// if Google refuses the embedded sign-in; a false desktop identity is not a
/// supported fallback.
enum SignInUserAgent {
    /// Use the same platform identity for the WebKit page and the signed
    /// account-menu request. On iPad, explicitly use an iPad identity rather
    /// than WebKit's optional desktop-style Macintosh identity.
    @MainActor
    static func browser() -> String {
        #if os(iOS)
        mobileSafari(isPad: UIDevice.current.userInterfaceIdiom == .pad)
        #else
        desktopSafari()
        #endif
    }

    /// Mobile Safari-shaped identity with the *real* device family and iOS
    /// version, never a Macintosh platform token. Pure so it can be regression
    /// tested on macOS without a physical iPhone.
    static func mobileSafari(
        osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion,
        isPad: Bool = false
    ) -> String {
        let version = osVersion.patchVersion > 0
            ? "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
            : "\(osVersion.majorVersion)_\(osVersion.minorVersion)"
        let device = isPad ? "iPad; CPU OS" : "iPhone; CPU iPhone OS"
        return "Mozilla/5.0 (\(device) \(version) like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
            + "Version/\(osVersion.majorVersion).\(osVersion.minorVersion) "
            + "Mobile/15E148 Safari/604.1"
    }

    /// Retained for the *real macOS application* only.
    static func desktopSafari(
        osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    ) -> String {
        let major = osVersion.majorVersion
        let minor = osVersion.minorVersion
        let patch = osVersion.patchVersion
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
            + "Version/\(safariVersion) Safari/605.1.15"
            + " (bitchord; macOS \(major).\(minor).\(patch))"
    }

    static let safariVersion = "17.6"

    /// A platform's own mobile browser identity is valid; do not reject it
    /// merely because it is mobile. This is a syntax check, not an assurance
    /// that Google's authentication service will accept an embedded web view.
    static func needsReplacing(defaultAgent: String) -> Bool {
        !isAcceptable(defaultAgent)
    }

    static func isAcceptable(_ agent: String) -> Bool {
        guard !agent.isEmpty, !agent.contains("\n"), !agent.contains("\r") else { return false }
        guard agent.hasPrefix("Mozilla/") else { return false }
        guard agent.contains("AppleWebKit/"), agent.contains("Safari/") else { return false }
        return agent.contains("Version/") || agent.contains("Mobile/")
    }
}
