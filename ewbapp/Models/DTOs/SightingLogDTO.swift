import Foundation

struct SightingLogDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let variant: String
    let infestationSize: String
    let notes: String?
    let photoFilenames: [String]
    let deviceID: String
    let serverID: String?
    let syncStatus: Int
    let rangerID: String
    let infestationZoneID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case latitude
        case longitude
        case horizontalAccuracy = "horizontal_accuracy"
        case variant
        case infestationSize = "infestation_size"
        case notes
        case photoFilenames = "photo_filenames"
        case deviceID = "device_id"
        case serverID = "server_id"
        case syncStatus = "sync_status"
        case rangerID = "ranger_id"
        case infestationZoneID = "infestation_zone_id"
    }
}
