import XCTest
@testable import ewbapp

final class SeasonalAlertTests: XCTestCase {

    func testAutumnAlertInApril() {
        let april = makeDate(month: 4)
        let alerts = SeasonalAlert.activeAlerts(for: april, recentRain: false)
        XCTAssertTrue(alerts.contains { $0.title.contains("Autumn") })
    }

    func testWetSeasonAlertInDecember() {
        let dec = makeDate(month: 12)
        let alerts = SeasonalAlert.activeAlerts(for: dec, recentRain: false)
        XCTAssertTrue(alerts.contains { $0.title.contains("Biocontrol") })
    }

    func testDrySeasonAlertInJuly() {
        let july = makeDate(month: 7)
        let alerts = SeasonalAlert.activeAlerts(for: july, recentRain: false)
        XCTAssertTrue(alerts.contains { $0.title.contains("Dry") })
    }

    func testRainAlertWhenFlagged() {
        let alerts = SeasonalAlert.activeAlerts(for: Date(), recentRain: true)
        XCTAssertTrue(alerts.contains { $0.title.contains("Rain") })
    }

    func testNoRainAlertWhenNotFlagged() {
        let june = makeDate(month: 6) // Not wet season, no rain
        let alerts = SeasonalAlert.activeAlerts(for: june, recentRain: false)
        XCTAssertFalse(alerts.contains { $0.title.contains("Rain") })
    }

    private func makeDate(month: Int) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = month
        components.day = 15
        return Calendar.current.date(from: components)!
    }
}
