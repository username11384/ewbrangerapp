import Foundation
import CoreData

final class PatrolRepository: PatrolRepositoryProtocol {
    private let persistence: PersistenceController
    private let syncQueueManager: SyncQueueManager

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.syncQueueManager = SyncQueueManager(persistence: persistence)
    }

    func createPatrol(areaName: String, rangerID: UUID) async throws -> PatrolRecord {
        let context = persistence.backgroundContext
        return try await context.perform {
            let patrol = PatrolRecord(context: context)
            patrol.id = UUID()
            patrol.createdAt = Date()
            patrol.updatedAt = Date()
            patrol.patrolDate = Date()
            patrol.startTime = Date()
            patrol.areaName = areaName
            patrol.notes = ""
            patrol.syncStatus = SyncStatus.pendingCreate.rawValue

            let defaultItems = PortStewartZones.defaultChecklist(for: areaName)
            if let encoded = try? JSONEncoder().encode(defaultItems) {
                patrol.checklistItems = encoded as NSData
            }

            let rangerPredicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: rangerPredicate) {
                patrol.ranger = ranger
            }

            try context.save()
            return patrol
        }
    }

    func updateChecklist(patrol: PatrolRecord, items: [PatrolChecklistItem]) async throws {
        let context = persistence.backgroundContext
        let objectID = patrol.objectID
        try await context.perform {
            guard let obj = context.object(with: objectID) as? PatrolRecord else { return }
            if let encoded = try? JSONEncoder().encode(items) {
                obj.checklistItems = encoded as NSData
            }
            obj.updatedAt = Date()
            obj.syncStatus = SyncStatus.pendingUpdate.rawValue
            try context.save()
        }
    }

    func finishPatrol(_ patrol: PatrolRecord) async throws {
        let context = persistence.backgroundContext
        let objectID = patrol.objectID
        try await context.perform {
            guard let obj = context.object(with: objectID) as? PatrolRecord else { return }
            obj.endTime = Date()
            obj.updatedAt = Date()
            obj.syncStatus = SyncStatus.pendingUpdate.rawValue
            try context.save()
        }
    }

    func fetchAllPatrols() throws -> [PatrolRecord] {
        try persistence.mainContext.fetchAll(
            PatrolRecord.self,
            sortDescriptors: [NSSortDescriptor(key: "patrolDate", ascending: false)]
        )
    }

    func deletePatrol(_ patrol: PatrolRecord) async throws {
        let context = persistence.backgroundContext
        let objectID = patrol.objectID
        try await context.perform {
            let obj = context.object(with: objectID)
            context.delete(obj)
            try context.save()
        }
    }

    func fetchActivePatrol(rangerID: UUID) throws -> PatrolRecord? {
        let predicate = NSPredicate(format: "endTime == nil AND ranger.id == %@", rangerID as CVarArg)
        return try persistence.mainContext.fetchFirst(
            PatrolRecord.self,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "startTime", ascending: false)]
        )
    }
}
