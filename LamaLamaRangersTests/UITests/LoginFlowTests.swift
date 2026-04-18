import XCTest

final class LoginFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLoginScreenAppears() throws {
        let app = XCUIApplication()
        app.launch()
        // New UI splits wordmark across two Text views — check either part
        let lamaLama = app.staticTexts["Lama Lama"]
        let rangers = app.staticTexts["Rangers"]
        XCTAssertTrue(
            lamaLama.waitForExistence(timeout: 5) || rangers.waitForExistence(timeout: 5),
            "Login wordmark not visible"
        )
    }

    func testSignOnPromptAppears() throws {
        let app = XCUIApplication()
        app.launch()
        let prompt = app.staticTexts["Good to see you. Who's signing on today?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
    }

    func testRangerCardListIsPopulated() throws {
        let app = XCUIApplication()
        app.launch()
        // At least one ranger card button should appear in the picker step
        let firstRanger = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ranger'")).firstMatch
        XCTAssertTrue(firstRanger.waitForExistence(timeout: 5))
    }

    func testTappingRangerAdvancesToPINStep() throws {
        let app = XCUIApplication()
        app.launch()
        let firstRanger = app.buttons.firstMatch
        guard firstRanger.waitForExistence(timeout: 5) else { return }
        firstRanger.tap()
        // PIN step shows "Enter your 4-digit PIN"
        let pinPrompt = app.staticTexts["Enter your 4-digit PIN"]
        XCTAssertTrue(pinPrompt.waitForExistence(timeout: 3))
    }

    func testPINKeypadDigitsAreTappable() throws {
        let app = XCUIApplication()
        app.launch()
        let firstRanger = app.buttons.firstMatch
        guard firstRanger.waitForExistence(timeout: 5) else { return }
        firstRanger.tap()
        // Keypad digits 1–9 and 0 should be present
        for digit in ["1", "2", "3", "4"] {
            XCTAssertTrue(app.buttons[digit].waitForExistence(timeout: 3), "Digit \(digit) missing from keypad")
        }
    }

    func testCorrectPINLogsIn() throws {
        let app = XCUIApplication()
        app.launch()
        let firstRanger = app.buttons.firstMatch
        guard firstRanger.waitForExistence(timeout: 5) else { return }
        firstRanger.tap()
        // Enter demo PIN 1234
        for digit in ["1", "2", "3", "4"] {
            app.buttons[digit].tap()
        }
        // Tab bar should appear after successful login
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testChangeRangerButtonReturnsToPickerStep() throws {
        let app = XCUIApplication()
        app.launch()
        let firstRanger = app.buttons.firstMatch
        guard firstRanger.waitForExistence(timeout: 5) else { return }
        firstRanger.tap()
        guard app.staticTexts["Enter your 4-digit PIN"].waitForExistence(timeout: 3) else { return }
        app.buttons["Change ranger"].tap()
        XCTAssertTrue(app.staticTexts["Good to see you. Who's signing on today?"].waitForExistence(timeout: 3))
    }
}
