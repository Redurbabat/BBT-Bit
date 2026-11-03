import Foundation

func expect(_ actual: String, toContain expected: String) {
    guard actual.contains(expected) else {
        fputs("FAIL: Expected '\(expected)' in '\(actual)'\n", stderr)
        exit(1)
    }
}

let direct = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [:])
expect(UserFacingRequestError.message(direct), toContain: "Settings > Cellular")

// The Kotlin bridge wraps URLSession's error inside a text exception.
let wrapped = "Exception in http request: Error Domain=NSURLErrorDomain Code=-1009 \"Es besteht anscheinend keine Verbindung zum Internet.\" UserInfo={_NSURLErrorFailingURLStringErrorKey=https://music.youtube.com/youtubei/v1/browse}"
let offline = UserFacingRequestError.message(wrapped)
expect(offline, toContain: "BBT-Bit")
assert(!offline.contains("youtubei/v1/browse"))

let bot = UserFacingRequestError.message("YouTube is asking this network to confirm it isn't a bot")
expect(bot, toContain: "verification")
assert(!bot.contains("Settings > Cellular"))

// Service-level verification must be actionable, but not confused with offline,
 // age restrictions or a general authentication failure.
assert(UserFacingRequestError.isYouTubeVerification("YouTube is asking this network to confirm it isn't a bot"))
assert(UserFacingRequestError.isYouTubeVerification("YouTube is requiring verification for this network"))
assert(UserFacingRequestError.isYouTubeVerification("YouTube CAPTCHA required"))
assert(!UserFacingRequestError.isYouTubeVerification("Age verification required"))
assert(!UserFacingRequestError.isYouTubeVerification("Please sign in to continue"))
assert(UserFacingRequestError.message("YouTube CAPTCHA required").contains("verification"))

let watch = UserFacingRequestError.youtubeWatchURL(forVideoID: "aB_012345-z")
assert(watch?.absoluteString == "https://www.youtube.com/watch?v=aB_012345-z")
assert(UserFacingRequestError.youtubeWatchURL(forVideoID: nil) == nil)
assert(UserFacingRequestError.youtubeWatchURL(forVideoID: "../watch?v=x") == nil)
assert(UserFacingRequestError.youtubeWatchURL(forVideoID: "abc12345678&other=1") == nil)
assert(UserFacingRequestError.youtubeWatchURL(forVideoID: "short") == nil)

let unexpected = UserFacingRequestError.message("Error Domain=Other Code=42 UserInfo={secret=123}")
assert(unexpected == "The request failed. Check your connection and try again.")
assert(UserFacingRequestError.message("Server temporarily unavailable") == "Server temporarily unavailable")
print("PASS: network error classification, privacy and recovery hints")
