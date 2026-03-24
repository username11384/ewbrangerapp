import XCTest
import CoreData
@testable import ewbapp

final class SyncQueueManagerTests: XCTestCase {
    var persistence: PersistenceController!
    var manager: SyncQueueManager!

    override func setUpWithError() throws {
        persistence = PersistenceController.preview
        manager = SyncQueueManager(persistence: persistence)
    }

    func testEnqueueCreatesEntry() throws {
        let context = persistence.mainContext
        let entityID = UUID()
        let payload = try JSONEncoder().encode(["test": "data"])

        manager.enqueue(
            entityName: "SightingLog",
            entityID: entityID,
            operationType: "create",
            payload: payload,
            context: context
        )
        try context.save()

        let entries = try manager.pendingEntries(context: context)
        XCTAssertTrue(entries.contains { $0.entityID == entityID })
    }

    func testRemoveDeletesEntry() throws {
        let context = persistence.mainContext
        let payload = try JSONEncoder().encode(["test": "data"])
        let entityID = UUID()

        manager.enqueue(entityName: "SightingLog", entityID: entityID, operationType: "create", payload: payload, context: context)
        try context.save()

        let entries = try manager.pendingEntries(context: context)
        XCTAssertFalse(entries.isEmpty)
        entries.forEach { manager.remove(entry: $0, context: context) }
        try context.save()

        let remaining = try manager.pendingEntries(context: context)
        XCTAssertTrue(remaining.isEmpty)
    }
}
