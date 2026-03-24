import Foundation

struct TreatmentRecordDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let treatmentDate: String
    let method: String
    let herbicideProduct: String?
    let outcomeNotes: String?
    let followUpDate: String?
    let photoFilenames: [String]
    let sightingID: String
    let rangerID: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case treatmentDate = "treatment_date"
        case method
        case herbicideProduct = "herbicide_product"
        case outcomeNotes = "outcome_notes"
        case followUpDate = "follow_up_date"
        case photoFilenames = "photo_filenames"
        case sightingID = "sighting_id"
        case rangerID = "ranger_id"
    }
}
