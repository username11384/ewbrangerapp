import Foundation

enum TreatmentMethod: String, CaseIterable, Codable {
    case cutStump = "cutStump"
    case splatGun = "splatGun"
    case foliarSpray = "foliarSpray"
    case basalBark = "basalBark"

    var displayName: String {
        switch self {
        case .cutStump: return "Cut Stump"
        case .splatGun: return "Splat Gun"
        case .foliarSpray: return "Foliar Spray"
        case .basalBark: return "Basal Bark"
        }
    }

    var instructions: String {
        switch self {
        case .cutStump:
            return "Cut stem close to ground. Apply neat Garlon 600 to cut surface immediately. Effective for stems >1cm diameter."
        case .splatGun:
            return "Apply Garlon 600 in diesel using splat gun applicator to stem. Space injections 2–3cm apart around stem circumference."
        case .foliarSpray:
            return "Mix Garlon 600 at 5mL/L with water + penetrant. Spray to wet all foliage. Best applied to actively growing plants. Avoid in rain."
        case .basalBark:
            return "Apply Garlon 600 in diesel at 1:3 ratio to lower 30cm of stem bark. Effective year-round. Do not apply to wet bark."
        }
    }

    var systemIconName: String {
        switch self {
        case .cutStump: return "scissors"
        case .splatGun: return "dot.squareshape.fill"
        case .foliarSpray: return "humidity.fill"
        case .basalBark: return "tree.fill"
        }
    }
}
