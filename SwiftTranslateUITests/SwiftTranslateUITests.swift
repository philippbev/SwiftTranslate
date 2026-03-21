import XCTest

/// UI tests for SwiftTranslate covering the five main user flows.
///
/// **Setup:** Add a UI Testing Bundle target named `SwiftTranslateUITests`
/// in Xcode (File → New → Target → macOS → UI Testing Bundle).
/// Set the "Target Application" to `SwiftTranslate`.
/// These tests require macOS 15.0+ and run offline (no network needed).
final class SwiftTranslateUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        // Bring the translator window to the front
        app.activate()
        openTranslatorWindow()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    // MARK: - Flow 1: Translate text and verify output appears

    func testTranslateTextShowsOutput() {
        let sourceField = app.textViews["sourceTextField"]
        sourceField.click()
        sourceField.typeText("Hello world")

        app.buttons["translateButton"].click()

        let outputField = app.textViews["outputTextField"]
        let appeared = outputField.waitForExistence(timeout: 10)
        XCTAssertTrue(appeared, "Output text view should exist")
        XCTAssertFalse(outputField.value as? String == "", "Translation output should not be empty")
    }

    // MARK: - Flow 2: Swap languages and verify pair updates

    func testSwapLanguagesUpdatesPair() {
        // Read initial source label
        let sourceBefore = app.staticTexts["sourceLangLabel"].value as? String ?? ""

        app.buttons["swapButton"].click()

        let sourceAfter = app.staticTexts["sourceLangLabel"].value as? String ?? ""
        XCTAssertNotEqual(sourceBefore, sourceAfter, "Source language label should change after swap")
    }

    // MARK: - Flow 3: Clear input empties both fields

    func testClearEmptiesBothFields() {
        let sourceField = app.textViews["sourceTextField"]
        sourceField.click()
        sourceField.typeText("Hallo Welt")

        app.buttons["clearButton"].click()

        let sourceValue = sourceField.value as? String ?? ""
        XCTAssertEqual(sourceValue, "", "Source field should be empty after clear")

        let outputField = app.textViews["outputTextField"]
        let outputValue = outputField.value as? String ?? ""
        XCTAssertEqual(outputValue, "", "Output field should be empty after clear")
    }

    // MARK: - Flow 4: Open Settings and toggle a setting

    func testSettingsToggleWorks() {
        // Open settings via keyboard shortcut ⌘,
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows["SwiftTranslate-Einstellungen"]
            .firstMatch
        let appeared = settingsWindow.waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "Settings window should appear")

        // Toggle "Auto-translate on paste"
        let toggle = settingsWindow.checkBoxes.firstMatch
        let before = toggle.value as? Int ?? 0
        toggle.click()
        let after = toggle.value as? Int ?? 0
        XCTAssertNotEqual(before, after, "Toggle value should flip")

        // Restore
        toggle.click()
    }

    // MARK: - Flow 5: History shows entry after translation

    func testHistoryShowsEntryAfterTranslation() {
        // Perform a translation first
        let sourceField = app.textViews["sourceTextField"]
        sourceField.click()
        sourceField.typeText("Guten Morgen")
        app.buttons["translateButton"].click()

        // Wait for translation to finish
        let outputField = app.textViews["outputTextField"]
        _ = outputField.waitForExistence(timeout: 10)

        // Open history
        app.buttons["historyButton"].click()

        let historyEntry = app.staticTexts["Guten Morgen"]
        let entryAppeared = historyEntry.waitForExistence(timeout: 3)
        XCTAssertTrue(entryAppeared, "History should contain the translated entry")
    }

    // MARK: - Helpers

    private func openTranslatorWindow() {
        // Try opening via ⌘N or activating the existing window
        let window = app.windows["SwiftTranslate"]
        if !window.exists {
            app.typeKey("n", modifierFlags: .command)
            _ = window.waitForExistence(timeout: 3)
        }
    }
}
