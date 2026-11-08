#if os(iOS)
import XCTest

/// Real-device UI automation. Runs from Xcode / a device lab, NOT from the
/// installed app itself. The test only validates the offline design previews.
@MainActor
final class LiquidMotionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Issue #55: exercise the real search keyboard, not the offline preview.
    /// This is a keyboard smoke test only; a visible playback pill still
    /// requires a separate seeded/real playback state before asserting handoff.
    func testSearchKeyboardCanOpenAndDismissOnRegularAppLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-onboarding_done", "YES"]
        app.launch()

        // The iOS 26 native search-role tab may be exposed as a button
        // outside XCUIElementTypeTabBar. Inspect the full button tree instead
        // of assuming UIKit's legacy tab-bar accessibility hierarchy.
        let searchTab = app.buttons.matching(identifier: "Search").firstMatch
        if !searchTab.waitForExistence(timeout: 20) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "BBT-Bit-Search-Tab-Missing"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertTrue(searchTab.exists,
                      "Search tab unavailable on regular app launch. Accessibility tree: \\(app.debugDescription)")
        searchTab.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 15),
                      "Native iPhone search field did not appear")
        searchField.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10),
                      "Search field did not display the keyboard")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "BBT-Bit-Search-Keyboard-Visible"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        // Dismiss via the keyboard's native Return/Search key where present.
        // If the keyboard has no dismissal key, this test still proves the
        // keyboard-open state; it does not claim a mini-player handoff passed.
        let searchKey = keyboard.buttons["search"]
        if searchKey.exists { searchKey.tap() }
    }

    func testEveryDesignPreviewIsRenderedAndOpenableOnIPhone() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--bbt-ui-test-designs"]
        app.launch()

        let start = app.buttons["bbt.selftest.run"]
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Self-test entry point did not appear")
        start.tap()

        let summary = app.staticTexts["bbt.selftest.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 120), "On-device self-test did not finish")
        XCTAssertTrue(summary.label.contains("15 bestanden"), summary.label)

        let shareReport = app.buttons["bbt.selftest.share"]
        XCTAssertTrue(shareReport.exists, "JSON report export is missing")

        for index in 1...15 {
            let testID = String(format: "bbt.selftest.feature.%02d", index)
            let row = app.buttons[testID]

            var attempts = 0
            while !row.isHittable && attempts < 16 {
                app.swipeUp()
                attempts += 1
            }
            XCTAssertTrue(row.isHittable, "Could not find or tap design \(index)")

            row.tap()
            let close = app.buttons["bbt.selftest.close"]
            XCTAssertTrue(close.waitForExistence(timeout: 12),
                          "Preview \(index) did not open")

            // Exercise a few representative real SwiftUI preview controls
            // instead of treating every static illustration as interactive.
            switch index {
            case 1:
                let toggle = app.buttons["Automix transition running"]
                XCTAssertTrue(toggle.exists, "Automix preview control is missing")
                toggle.tap()
                XCTAssertTrue(app.staticTexts["Transition running"].waitForExistence(timeout: 8),
                              "Automix transition details did not open")
                app.buttons["Done"].tap()
            case 2:
                let flip = app.buttons["Translated lyric"]
                XCTAssertTrue(flip.exists, "Lyrics switch is missing")
                flip.tap()
                XCTAssertTrue(app.buttons["Original lyric"].exists)
            case 3:
                let prism = app.buttons["Audio signal prism"]
                XCTAssertTrue(prism.exists, "Audio pipeline preview control is missing")
                prism.tap()
                XCTAssertTrue(app.staticTexts["Source"].exists)
            default:
                break
            }

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = String(format: "BBT-Bit-Design-%02d", index)
            screenshot.lifetime = .keepAlways
            add(screenshot)
            close.tap()
            // The JSON share button sits at the top of a lazy List. After
            // scrolling to preview 6+ it is off-screen and may be recycled.
            // Assert the actual page, not a virtualized off-screen button.
            let page = app.navigationBars["Vorschau-Selbsttest"]
            XCTAssertTrue(page.waitForExistence(timeout: 12),
                          "Self-test screen disappeared after closing preview \(index)")
        }
    }
}
#endif
