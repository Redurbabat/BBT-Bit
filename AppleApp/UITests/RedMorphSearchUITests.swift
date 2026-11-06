#if os(iOS)
import XCTest
import UIKit

/// Echter SwiftUI-Suchbildschirm mit Debug-Launchargument, keine simulierte
/// Wiedergabe und kein externer Sucherfolg als Testvoraussetzung.
@MainActor
final class RedMorphSearchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testIPhoneSearchFieldStaysAboveKeyboard() throws {
        // Auf iPad verwendet die Suche absichtlich die native Toolbar.
        // Die feste Suchzeile ist ausschließlich für das iPhone vorgesehen.
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("RED-Morph-Suchfeld wird nur auf iPhones eingeblendet.")
        }

        let app = XCUIApplication()
        app.launchArguments += ["--bbt-ui-test-search"]
        app.launch()

        let field = app.textFields["bbt.search.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 20),
                      "Das RED-Morph-Suchfeld wurde nicht angezeigt.")

        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        XCTAssertLessThan(field.frame.midY, window.frame.midY,
                          "Die Suche muss vor dem Tippen im oberen Bildschirmbereich liegen.")

        field.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 12),
                      "Nach dem Fokussieren der Suche fehlt die native Tastatur.")
        XCTAssertLessThan(field.frame.maxY, keyboard.frame.minY,
                          "Das Suchfeld darf nicht hinter oder in der Tastatur liegen.")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "RED-Morph-Suche-mit-Tastatur"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        field.typeText("A")
        // Die ID bleibt unter Englisch, Deutsch und weiteren App-Sprachen stabil.
        let clearButton = app.buttons["bbt.search.clear"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 8),
                      "Der Clear-Button ist beim Bearbeiten nicht erreichbar.")
        clearButton.tap()
        XCTAssertTrue(field.exists, "Das Suchfeld darf beim Löschen nicht verschwinden.")
        XCTAssertFalse(clearButton.exists, "Bei leerer Suche muss Clear wieder verschwinden.")

        // Ein zweiter Fokuszyklus erkennt hängen gebliebene Keyboard-/Focus-
        // Zustände nach dem Leeren, ohne Netzwerkantworten vorauszusetzen.
        field.tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: 8),
                      "Nach dem Löschen muss die Suche erneut fokussierbar sein.")
        XCTAssertLessThan(field.frame.maxY, keyboard.frame.minY,
                          "Auch beim zweiten Fokus darf die Tastatur das Suchfeld nicht überdecken.")
    }
}
#endif
