import Foundation
import CoreData

final class SyncQueueManager {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    /// Atomically saves the entity + creates a SyncQueue entry in the same context save.
    func enqueue(
        entityName: String,
        entityID: UUID,
        operationType: String,
        payload: Data,
        context: NSManagedObjectContext
    ) {
        let entry = SyncQueue(context: context)
        entry.id = UUID()
        entry.createdAt = Date()
        entry.entityName = entityName
        entry.entityID = entityID
        entry.operationType = operationType
        entry.payload = payload
        entry.attemptCount = 0
    }

    func pendingEntries(context: NSManagedObjectContext) throws -> [SyncQueue] {
        let request = SyncQueue.fetchRequest() as! NSFetchRequest<SyncQueue>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(request)
    }

    func markAttempt(entry: SyncQueue, error: String? = nil) {
        entry.attemptCount += 1
        entry.lastAttemptAt = Date()
        entry.lastErrorMessage = error
    }

    func remove(entry: SyncQueue, context: NSManagedObjectContext) {
        context.delete(entry)
    }

    var hasPersistentFailures: Bool {
        (try? persistence.mainContext.fetchAll(SyncQueue.self, predicate: NSPredicate(format: "attemptCount >= %d", SyncConfig.failureThreshold)))?.isEmpty == false
    }
}
