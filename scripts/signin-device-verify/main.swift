import Foundation

var failures = 0
func check(_ description: String, _ condition: Bool) {
    if !condition {
        fputs("FAIL: \(description)\n", stderr)
        failures += 1
    }
}

let system = OperatingSystemVersion(majorVersion: 18, minorVersion: 5, patchVersion: 1)
let iphone = SignInUserAgent.mobileSafari(osVersion: system)
let ipad = SignInUserAgent.mobileSafari(osVersion: system, isPad: true)

check("iPhone is identified as iPhone", iphone.contains("(iPhone; CPU iPhone OS 18_5_1"))
check("iPad is identified as iPad", ipad.contains("(iPad; CPU OS 18_5_1"))
check("neither mobile UA claims to be Macintosh", !iphone.contains("(Macintosh;") && !ipad.contains("(Macintosh;"))
check("both UAs have a mobile browser token", iphone.contains("Mobile/") && ipad.contains("Mobile/"))
check("both UAs have Safari browser tokens", iphone.contains("Safari/") && ipad.contains("Safari/"))
check("the mobile identities are accepted as valid browser UAs",
      SignInUserAgent.isAcceptable(iphone) && SignInUserAgent.isAcceptable(ipad))
check("the normal iPhone WebKit UA is recognized",
      SignInUserAgent.isAcceptable("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/604.1"))
check("non-browser UAs are refused", !SignInUserAgent.isAcceptable("curl/8.4.0"))
#if os(iOS)
check("iOS runtime does not use the Macintosh platform token",
      !SignInUserAgent.browser().contains("(Macintosh;"))
#elseif os(macOS)
check("native Mac app still identifies as Mac",
      SignInUserAgent.browser().contains("(Macintosh;"))
#endif
if failures != 0 { exit(1) }
print("PASS: Safari device identity regression checks")
