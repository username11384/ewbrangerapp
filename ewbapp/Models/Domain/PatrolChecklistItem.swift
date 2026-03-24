import Foundation

struct PatrolChecklistItem: Codable, Identifiable {
    let id: UUID
    var label: String
    var isComplete: Bool
    var completedAt: Date?

    init(id: UUID = UUID(), label: String, isComplete: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.label = label
        self.isComplete = isComplete
        self.completedAt = completedAt
    }
}
