import Foundation

enum InfestationSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var areaDescription: String {
        switch self {
        case .small: return "< 5 m²"
        case .medium: return "5 – 50 m²"
        case .large: return "> 50 m²"
        }
    }
}
