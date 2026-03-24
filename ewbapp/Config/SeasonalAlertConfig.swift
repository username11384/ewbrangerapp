import Foundation

enum SeasonalAlertConfig {
    // Months (1-based) when autumn treatment window is active
    static let autumnTreatmentMonths: Set<Int> = [4, 5]

    // Months when wet season biocontrol may be active
    static let wetSeasonMonths: Set<Int> = [11, 12, 1, 2, 3]

    // Months when dry season warning applies
    static let drySeasonMonths: Set<Int> = [6, 7, 8, 9]

    // UserDefaults key for rain event flag
    static let recentRainKey = "recentRainEvent"

    // How long the rain flag stays active (days)
    static let rainFlagDuration: TimeInterval = 14 * 24 * 3600
}
