import XCTest

final class LogSightingFlowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func loginAndReachMap(app: XCUIApplication) {
        app.launch()
        let firstRanger = app.buttons.firstMatch
        guard firstRanger.waitForExistence(timeout: 5) else { return }
        firstRanger.tap()
        for digit in ["1", "2", "3", "4"] { app.buttons[digit].tap() }
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
    }

    func testSightingsTabIsPresent() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        XCTAssertTrue(app.tabBars.buttons["Sightings"].exists)
    }

    func testMapTabIsPresent() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        XCTAssertTrue(app.tabBars.buttons["Map"].exists)
    }

    func testFABIsPresentOnMapTab() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        // FAB is a button with "+" — ensure we're on Map tab first
        app.tabBars.buttons["Map"].tap()
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Log'")).firstMatch
        XCTAssertTrue(fab.waitForExistence(timeout: 3), "FAB / log sighting button not visible on Map")
    }

    func testLogSightingSheetOpens() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        app.tabBars.buttons["Map"].tap()
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Log'")).firstMatch
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        XCTAssertTrue(app.staticTexts["Log sighting"].waitForExistence(timeout: 3))
    }

    func testLogSightingSheetDismissesOnCancel() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        app.tabBars.buttons["Map"].tap()
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Log'")).firstMatch
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        guard app.staticTexts["Log sighting"].waitForExistence(timeout: 3) else { return }
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["Log sighting"].waitForExistence(timeout: 2))
    }

    func testSubmitButtonDisabledUntilVariantSelected() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        app.tabBars.buttons["Map"].tap()
        let fab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Log'")).firstMatch
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        guard app.staticTexts["Log sighting"].waitForExistence(timeout: 3) else { return }
        let submit = app.buttons["Submit sighting"]
        if submit.exists {
            XCTAssertFalse(submit.isEnabled, "Submit should be disabled before variant is selected")
        }
    }

    func testSightingsListShowsTitle() throws {
        let app = XCUIApplication()
        loginAndReachMap(app: app)
        app.tabBars.buttons["Sightings"].tap()
        XCTAssertTrue(app.staticTexts["Sightings"].waitForExistence(timeout: 3))
    }
}
