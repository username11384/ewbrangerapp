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
                message: "April–May is optimal for foliar spray and basal bark treatments on most shrubs and trees. Plants are actively translocating nutrients.",
                severity: .info
            ))
        }

        // Post-rain regrowth alert (all invasive plants)
        if recentRain {
            alerts.append(SeasonalAlert(
                title: "Post-Rain Regrowth Likely",
                message: "Recent rainfall accelerates regrowth of treated plants. Check previously treated sites for Lantana, Sicklepod, and grass species within 2–3 weeks.",
                severity: .warning
            ))
        }

        // Dry season — reduced foliar efficacy (June–September)
        if (6...9).contains(month) {
            alerts.append(SeasonalAlert(
                title: "Dry Season — Reduced Foliar Efficacy",
                message: "Foliar spraying is less effective on drought-stressed plants. Prefer cut-stump, basal bark, or stem injection methods. Good period for Rubber Vine and Prickly Acacia control.",
                severity: .warning
            ))
        }

        // Rubber Vine flowering / seed set (August–November)
        if (8...11).contains(month) {
            alerts.append(SeasonalAlert(
                title: "Rubber Vine Flowering",
                message: "Aug–Nov: Rubber Vine is actively flowering and setting seed. Prioritise treatment before seed pods split to prevent floodwater dispersal.",
                severity: .warning
            ))
        }

        // Prickly Acacia pod fall (May–September)
        if (5...9).contains(month) {
            alerts.append(SeasonalAlert(
                title: "Prickly Acacia Seed Dispersal",
                message: "Dry season pod fall is spreading Prickly Acacia seed. Focus on removal of seed-bearing trees before pods drop.",
                severity: .info
            ))
        }

        // Giant Rat's Tail Grass seed heads (August–October)
        if (8...10).contains(month) {
            alerts.append(SeasonalAlert(
                title: "Grass Seed Set",
                message: "Giant Rat's Tail Grass seed heads are maturing. Treat or slash before seed dispersal to reduce next season's germination.",
                severity: .info
            ))
        }

        // Wet season — biocontrol opportunity for Lantana (November–March)
        if month >= 11 || month <= 3 {
            alerts.append(SeasonalAlert(
                title: "Wet Season: Lantana Biocontrol Active",
                message: "Check for lantana bug (Aconophora compressa) before spraying Lantana. Biocontrol insects may be present and should be protected.",
                severity: .info
            ))
        }

        return alerts
    }
}
