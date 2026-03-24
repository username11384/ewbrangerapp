import Foundation

struct PatrolRecordDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let patrolDate: String
    let startTime: String
    let endTime: String?
    let areaName: String
    let checklistItemsJSON: String
    let notes: String
    let rangerID: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case patrolDate = "patrol_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case areaName = "area_name"
        case checklistItemsJSON = "checklist_items_json"
        case notes
        case rangerID = "ranger_id"
    }
}
