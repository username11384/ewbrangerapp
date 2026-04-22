import Foundation

// MARK: - RangerStatus

struct RangerStatus: Codable, Identifiable {
    let id: String          // deviceID / peerID display name
    var rangerName: String
    var lastSeen: Date
    var currentZone: String?
    var statusMessage: String   // "On Patrol", "Base Camp", "Need Assistance", "Returning"
    var batteryLevel: Float?
}

// MARK: - Status options

extension RangerStatus {
    static let statusOptions: [String] = [
        "On Patrol",
        "Base Camp",
        "Need Assistance",
        "Returning"
    ]
}
