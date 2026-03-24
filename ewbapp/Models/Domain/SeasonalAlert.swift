import Foundation

struct SeasonalAlert {
    let title: String
    let message: String
    let severity: Severity

    enum Severity {
        case info, warning, critical
    }

    /// Returns active seasonal alerts based on the current date and rain-event flag.
    static func activeAlerts(for date: Date = Date(), recentRain: Bool = false) -> [SeasonalAlert] {
        var alerts: [SeasonalAlert] = []
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)

        // Autumn chemical treatment window (April–May in Cape York)
        if month == 4 || month == 5 {
            alerts.append(SeasonalAlert(
                title: "Autumn Treatment Window",
                message: "April–May is the optimal period for foliar spray and basal bark treatments. Plants are actively translocating nutrients.",
                severity: .info
            ))
        }

        // Post-rain regrowth alert
        if recentRain {
            alerts.append(SeasonalAlert(
                title: "Post-Rain Regrowth Expected",
                message: "Recent rainfall increases Lantana regrowth rate. Check previously treated sites within 2–3 weeks.",
                severity: .warning
            ))
        }

        // Dry season — reduced efficacy warning (June–September)
        if (6...9).contains(month) {
            alerts.append(SeasonalAlert(
                title: "Dry Season — Reduced Foliar Efficacy",
                message: "Foliar spraying is less effective when plants are drought-stressed. Prefer cut-stump or basal bark methods.",
                severity: .warning
            ))
        }

        // Wet season — biocontrol opportunity (November–March)
        if month >= 11 || month <= 3 {
            alerts.append(SeasonalAlert(
                title: "Wet Season: Biocontrol Active",
                message: "Check for lantana bug (Aconophora compressa) before spraying pink variants. Biocontrol insects may be present.",
                severity: .info
            ))
        }

        return alerts
    }
}
