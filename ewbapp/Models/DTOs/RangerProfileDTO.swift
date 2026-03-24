import Foundation

struct RangerProfileDTO: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let supabaseUID: String
    let displayName: String
    let role: String
    let avatarFilename: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case supabaseUID = "supabase_uid"
        case displayName = "display_name"
        case role
        case avatarFilename = "avatar_filename"
    }
}
