import Foundation

enum TreatmentMethod: String, CaseIterable, Codable {
    case cutStump    = "cutStump"
    case splatGun    = "splatGun"
    case foliarSpray = "foliarSpray"
    case basalBark   = "basalBark"
    // Added for non-Lantana species
    case mechanical    = "mechanical"
    case stemInjection = "stemInjection"
    case fireManagement = "fireManagement"

    var displayName: String {
        switch self {
        case .cutStump:       return "Cut Stump"
        case .splatGun:       return "Splat Gun"
        case .foliarSpray:    return "Foliar Spray"
        case .basalBark:      return "Basal Bark"
        case .mechanical:     return "Mechanical Removal"
        case .stemInjection:  return "Stem Injection"
        case .fireManagement: return "Fire Management"
        }
    }

    var instructions: String {
        switch self {
        case .cutStump:
            return "Cut stem close to ground. Apply neat herbicide (e.g. Garlon 600) to cut surface immediately. Effective for stems >1cm diameter."
        case .splatGun:
            return "Apply herbicide in diesel using splat gun applicator to stem. Space injections 2–3cm apart around stem circumference."
        case .foliarSpray:
            return "Mix herbicide at label rate with water + penetrant. Spray to wet all foliage. Best applied to actively growing plants. Avoid in rain or extreme heat."
        case .basalBark:
            return "Apply herbicide in diesel (1:3 ratio) to lower 30cm of stem bark. Effective year-round. Do not apply to wet or corky bark."
        case .mechanical:
            return "Hand-pull, grub, or slash plants at ground level. Ensure roots are removed to prevent regrowth. Bag and dispose of seed heads. Follow up in 4–6 weeks."
        case .stemInjection:
            return "Drill or cut evenly spaced holes into the stem (1 per 3cm of diameter). Inject neat or diluted herbicide immediately. Effective for large woody vines and trees."
        case .fireManagement:
            return "Planned burning to reduce grass fuel load and stimulate native recovery. Coordinate with land managers. Follow fire permit requirements. Timing is critical — dry season preferred for grass species."
        }
    }

    var systemIconName: String {
        switch self {
        case .cutStump:       return "scissors"
        case .splatGun:       return "dot.squareshape.fill"
        case .foliarSpray:    return "humidity.fill"
        case .basalBark:      return "tree.fill"
        case .mechanical:     return "hand.raised.fill"
        case .stemInjection:  return "syringe.fill"
        case .fireManagement: return "flame.fill"
        }
    }
}
