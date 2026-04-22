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

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LamaLamaRangers")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable automatic lightweight migration so adding new entities/attributes
            // across schema changes doesn't require manual migration mappings.
            if let desc = container.persistentStoreDescriptions.first {
                desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            }
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                // Migration failed (e.g. incompatible store from an older build).
                // For this demo app, nuke the store and start fresh — DemoSeeder will reseed.
                if let storeURL = description.url {
                    try? self.container.persistentStoreCoordinator.destroyPersistentStore(
                        at: storeURL,
                        ofType: description.type,
                        options: nil
                    )
                }
                // Retry with a clean store.
                do {
                    try self.container.persistentStoreCoordinator.addPersistentStore(
                        ofType: description.type,
                        configurationName: nil,
                        at: description.url,
                        options: nil
                    )
                } catch {
                    fatalError("Failed to recreate CoreData store after migration failure: \(error)")
                }
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
