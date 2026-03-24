import Foundation

enum RangerRole: String, CaseIterable, Codable {
    case ranger = "ranger"
    case seniorRanger = "seniorRanger"
    case coordinator = "coordinator"

    var displayName: String {
        switch self {
        case .ranger: return "Ranger"
        case .seniorRanger: return "Senior Ranger"
        case .coordinator: return "Coordinator"
        }
    }
}
