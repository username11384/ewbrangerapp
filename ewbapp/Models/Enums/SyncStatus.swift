import Foundation

enum SyncStatus: Int16, Codable {
    case pendingCreate = 0
    case pendingUpdate = 1
    case pendingDelete = 2
    case synced        = 3

    var iconSystemName: String {
        switch self {
        case .pendingCreate, .pendingUpdate: return "arrow.up.circle"
        case .pendingDelete: return "trash.circle"
        case .synced: return "checkmark.circle.fill"
        }
    }
}
