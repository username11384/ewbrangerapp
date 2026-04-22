import Foundation

// MARK: - RangerStatus

struct RangerStatus: Codable, Identifiable {
    var id: String           // deviceID
    var rangerName: String
    var lastSeen: Date
    var currentZone: String?
    var statusMessage: StatusMessage
    var batteryLevel: Float?

    enum StatusMessage: String, Codable, CaseIterable {
        case onPatrol       = "On Patrol"
        case baseCamp       = "Base Camp"
        case needAssistance = "Need Assistance"
        case returning      = "Returning"
    }
}
