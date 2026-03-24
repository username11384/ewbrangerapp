import Foundation
import CoreData

final class RangerRepository: RangerRepositoryProtocol {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchCurrentRanger() throws -> RangerProfile? {
        try persistence.mainContext.fetchFirst(
            RangerProfile.self,
            predicate: NSPredicate(format: "isCurrentDevice == YES")
        )
    }

    func fetchAllRangers() throws -> [RangerProfile] {
        try persistence.mainContext.fetchAll(
            RangerProfile.self,
            sortDescriptors: [NSSortDescriptor(key: "displayName", ascending: true)]
        )
    }

    func createRanger(displayName: String, role: RangerRole, supabaseUID: String) async throws -> RangerProfile {
        let context = persistence.backgroundContext
        return try await context.perform {
            let ranger = RangerProfile(context: context)
            ranger.id = UUID()
            ranger.createdAt = Date()
            ranger.updatedAt = Date()
            ranger.displayName = displayName
            ranger.role = role.rawValue
            ranger.supabaseUID = supabaseUID
            ranger.isCurrentDevice = false
            ranger.syncStatus = SyncStatus.pendingCreate.rawValue
            try context.save()
            return ranger
        }
    }

    func setCurrentDevice(rangerID: UUID) async throws {
        let context = persistence.backgroundContext
        try await context.perform {
            // Clear existing current device
            let all = try context.fetchAll(RangerProfile.self)
            for ranger in all {
                ranger.isCurrentDevice = false
            }
            // Set new current
            let predicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try context.fetchFirst(RangerProfile.self, predicate: predicate) {
                ranger.isCurrentDevice = true
            }
            try context.save()
        }
    }
}
