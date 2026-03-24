import Foundation

struct ZoneSnapshotDTO: Codable {
    let id: String
    let createdAt: String
    let snapshotDate: String
    let polygonCoordinates: [[Double]]
    let area: Double
    let createdByRangerID: String
    let zoneID: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case snapshotDate = "snapshot_date"
        case polygonCoordinates = "polygon_coordinates"
        case area
        case createdByRangerID = "created_by_ranger_id"
        case zoneID = "zone_id"
    }
}
