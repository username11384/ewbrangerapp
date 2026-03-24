import Foundation
import CoreData

final class TaskRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAllTasks(rangerID: UUID? = nil) throws -> [RangerTask] {
        var predicates: [NSPredicate] = []
        if let id = rangerID {
            predicates.append(NSPredicate(format: "assignedRanger.id == %@", id as CVarArg))
        }
        let predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try persistence.mainContext.fetchAll(
            RangerTask.self,
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(key: "isComplete", ascending: true),
                NSSortDescriptor(key: "dueDate", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
        )
    }

    func createTask(
        title: String,
        notes: String?,
        priority: TaskPriority,
        dueDate: Date?,
        rangerID: UUID
    ) async throws -> RangerTask {
        let context = persistence.backgroundContext
        return try await context.perform {
            let task = RangerTask(context: context)
            task.id = UUID()
            task.createdAt = Date()
            task.updatedAt = Date()
            task.title = title
            task.notes = notes
            task.priority = priority.rawValue
            task.dueDate = dueDate
            task.isComplete = false
            task.syncStatus = SyncStatus.pendingCreate.rawValue

            let predicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: predicate) {
                task.assignedRanger = ranger
            }
            try context.save()
            return task
        }
    }

    /// Auto-create a follow-up task from a treatment's followUpDate
    func createFollowUpTask(for treatment: TreatmentRecord, rangerID: UUID) async throws {
        guard let followUpDate = treatment.followUpDate else { return }
        let context = persistence.backgroundContext
        let treatmentID = treatment.objectID
        try await context.perform {
            guard let t = context.object(with: treatmentID) as? TreatmentRecord,
                  t.followUpTask == nil else { return }   // already has one
            let task = RangerTask(context: context)
            task.id = UUID()
            task.createdAt = Date()
            task.updatedAt = Date()
            let method = TreatmentMethod(rawValue: t.method ?? "")?.displayName ?? "Treatment"
            task.title = "Regrowth check — \(method)"
            task.notes = "Check treatment site for regrowth. Linked to \(method) treatment."
            task.priority = TaskPriority.medium.rawValue
            task.dueDate = followUpDate
            task.isComplete = false
            task.syncStatus = SyncStatus.pendingCreate.rawValue
            task.sourceTreatment = t

            let predicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: predicate) {
                task.assignedRanger = ranger
            }
            try context.save()
        }
    }

    func toggleComplete(_ task: RangerTask) async throws {
        let context = persistence.backgroundContext
        let objectID = task.objectID
        try await context.perform {
            guard let obj = context.object(with: objectID) as? RangerTask else { return }
            obj.isComplete.toggle()
            obj.completedAt = obj.isComplete ? Date() : nil
            obj.updatedAt = Date()
            obj.syncStatus = SyncStatus.pendingUpdate.rawValue
            try context.save()
        }
    }

    func updateTask(_ task: RangerTask, title: String, notes: String?, priority: TaskPriority, dueDate: Date?) async throws {
        let context = persistence.backgroundContext
        let objectID = task.objectID
        try await context.perform {
            guard let obj = context.object(with: objectID) as? RangerTask else { return }
            obj.title = title
            obj.notes = notes
            obj.priority = priority.rawValue
            obj.dueDate = dueDate
            obj.updatedAt = Date()
            obj.syncStatus = SyncStatus.pendingUpdate.rawValue
            try context.save()
        }
    }

    func deleteTask(_ task: RangerTask) async throws {
        let context = persistence.backgroundContext
        let objectID = task.objectID
        try await context.perform {
            context.delete(context.object(with: objectID))
            try context.save()
        }
    }
}
