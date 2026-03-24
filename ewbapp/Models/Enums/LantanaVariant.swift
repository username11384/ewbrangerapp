import SwiftUI

enum LantanaVariant: String, CaseIterable, Codable {
    case pink = "pink"
    case red = "red"
    case pinkEdgedRed = "pinkEdgedRed"
    case orange = "orange"
    case white = "white"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .pink: return "Pink"
        case .red: return "Red"
        case .pinkEdgedRed: return "Pink-Edged Red"
        case .orange: return "Orange"
        case .white: return "White"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .pink: return Color(red: 1.0, green: 0.41, blue: 0.71)
        case .red: return Color(red: 0.86, green: 0.08, blue: 0.24)
        case .pinkEdgedRed: return Color(red: 0.9, green: 0.25, blue: 0.45)
        case .orange: return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .unknown: return Color.gray
        }
    }

    var controlMethods: [TreatmentMethod] {
        switch self {
        case .pink: return [.foliarSpray, .splatGun]
        case .red: return [.cutStump, .basalBark]
        case .pinkEdgedRed: return [.cutStump, .foliarSpray]
        case .orange: return [.foliarSpray, .basalBark]
        case .white: return [.foliarSpray, .splatGun]
        case .unknown: return [.foliarSpray]
        }
    }

    var distinguishingFeatures: String {
        switch self {
        case .pink: return "Soft pink flowers, often fading to yellow centres. Common in disturbed areas."
        case .red: return "Deep red-orange flowers. Most aggressive spreader. Toxic berries."
        case .pinkEdgedRed: return "Pink outer petals with red centre. Hybrid characteristics."
        case .orange: return "Bright orange-yellow flowers. Common along watercourses."
        case .white: return "White to cream flowers. Less vigorous but still invasive."
        case .unknown: return "Variant not clearly identifiable. Treat as per nearest match."
        }
    }

    var hasBiocontrolConcern: Bool { self == .pink }
}
