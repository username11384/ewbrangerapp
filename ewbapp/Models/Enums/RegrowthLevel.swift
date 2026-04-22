import Foundation

enum RegrowthLevel: String, CaseIterable, Codable {
    case none     = "None"
    case light    = "Light"
    case moderate = "Moderate"
    case heavy    = "Heavy"

    var displayName: String { rawValue }

    /// Relative severity index (0–3) used for success-rate calculations.
    var severityIndex: Int {
        switch self {
        case .none:     return 0
        case .light:    return 1
        case .moderate: return 2
        case .heavy:    return 3
        }
    }
}
