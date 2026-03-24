import CoreData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var mainContext: NSManagedObjectContext {
        container.viewContext
    }

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LamaLamaRangers")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load CoreData store: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    }

    // MARK: - Preview / Testing
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Seed preview data
        let context = controller.mainContext
        let ranger = RangerProfile(context: context)
        ranger.id = UUID()
        ranger.displayName = "Preview Ranger"
        ranger.role = RangerRole.ranger.rawValue
        ranger.isCurrentDevice = true
        ranger.createdAt = Date()
        ranger.updatedAt = Date()
        ranger.syncStatus = SyncStatus.synced.rawValue
        try? context.save()
        return controller
    }()

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
}
