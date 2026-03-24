import XCTest

final class LoginFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLoginScreenAppears() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Lama Lama Rangers"].waitForExistence(timeout: 5))
    }

    func testRangerSelectionAndPINEntry() throws {
        let app = XCUIApplication()
        app.launch()
        // Wait for ranger list
        let firstRanger = app.buttons.firstMatch
        if firstRanger.waitForExistence(timeout: 3) {
            firstRanger.tap()
        }
        // Tap PIN digits
        let one = app.buttons["1"]
        if one.waitForExistence(timeout: 3) {
            one.tap(); one.tap(); one.tap(); one.tap()
        }
    }
}
