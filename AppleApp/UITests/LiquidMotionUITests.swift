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

        // The iOS 26 simulator exposes the localized Search tab as a Button
        // with identifier "magnifyingglass" and label "Suchen" (not "Search").
        // Prefer the SF Symbol identifier; the label can change with locale.
        let searchTab = app.tabBars.buttons["magnifyingglass"]
        if !searchTab.waitForExistence(timeout: 20) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "BBT-Bit-Search-Tab-Missing"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertTrue(searchTab.exists,
                      "Search tab unavailable on regular app launch. Accessibility tree: \(app.debugDescription)")
        searchTab.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 15),
                      "Native iPhone search field did not appear")
        let pillID = "bbt.playback.pill.open"
        let pill = app.buttons[pillID]
        XCTAssertTrue(pill.waitForExistence(timeout: 10),
                      "Mini-player must be present even in the empty playback state")
        XCTAssertEqual(app.buttons.matching(identifier: pillID).count, 1,
                       "Expected exactly one mini-player before keyboard focus")

        searchField.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10),
                      "Search field did not display the keyboard")
        // Keep a diagnostic screenshot even when a subsequent geometry
        // assertion fails. XCTest otherwise loses the interesting layout.
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "BBT-Bit-Search-Keyboard-Visible"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        XCTAssertTrue(pill.waitForExistence(timeout: 10),
                      "Mini-player disappeared when the search keyboard opened")
        XCTAssertEqual(app.buttons.matching(identifier: pillID).count, 1,
                       "Native bottom accessory and keyboard inset duplicated the mini-player")
        XCTAssertTrue(pill.isHittable, "Mini-player is not reachable above the keyboard")
        XCTAssertLessThanOrEqual(pill.frame.maxY, keyboard.frame.minY + 4,
                                 "Mini-player overlaps the native keyboard")

        // Native return-key labels are localized (e.g. "Suchen" on a
        // German simulator). A missing key must fail, not skip the whole
        // test and conceal already-executed keyboard layout assertions.
        let searchKey = ["Suchen", "Search", "search"].map { keyboard.buttons[$0] }
            .first(where: { $0.exists })
        if searchKey == nil {
            let noKey = XCTAttachment(screenshot: app.screenshot())
            noKey.name = "BBT-Bit-Search-Key-Unavailable"
            noKey.lifetime = .keepAlways
            add(noKey)
        }
        XCTAssertNotNil(searchKey, "Native search keyboard has no recognized submit key")
        searchKey?.tap()
        XCTAssertFalse(keyboard.waitForExistence(timeout: 5),
                       "Search keyboard stayed open after submitting")
        XCTAssertTrue(pill.waitForExistence(timeout: 10),
                      "Mini-player missing after keyboard dismissal")
        XCTAssertEqual(app.buttons.matching(identifier: pillID).count, 1,
                       "Mini-player duplicated after keyboard dismissal")
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
                let toggle = app.buttons["Automix transition"]
                XCTAssertTrue(toggle.exists, "Automix preview control is missing")
                toggle.tap()
                XCTAssertTrue(app.staticTexts["Transition in progress"].exists)
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
