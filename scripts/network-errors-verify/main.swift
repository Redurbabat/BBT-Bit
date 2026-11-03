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

let unexpected = UserFacingRequestError.message("Error Domain=Other Code=42 UserInfo={secret=123}")
assert(unexpected == "The request failed. Check your connection and try again.")
assert(UserFacingRequestError.message("Server temporarily unavailable") == "Server temporarily unavailable")
print("PASS: network error classification, privacy and recovery hints")
