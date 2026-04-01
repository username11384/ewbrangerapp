import XCTest
import CoreData
@testable import ewbapp

final class PesticideQuantityTests: XCTestCase {
    var persistence: PersistenceController!

    override func setUpWithError() throws {
        persistence = PersistenceController(inMemory: true)
    }

    func testLogUsageDecrementsStock() async {
        let context = persistence.backgroundContext
        // Create stock with 100 units
        var stockID: NSManagedObjectID!
        await context.perform {
            let stock = PesticideStock(context: context)
            stock.id = UUID()
            stock.createdAt = Date()
            stock.updatedAt = Date()
            stock.productName = "Test Herbicide"
            stock.unit = "L"
            stock.currentQuantity = 100.0
            stock.minThreshold = 10.0
            stock.syncStatus = SyncStatus.synced.rawValue
            try! context.save()
            stockID = stock.objectID
        }

        let vm = await PesticideViewModel(persistence: persistence)

        // Log 25L usage
        let rangerID = UUID()
        await context.perform {
            let ranger = RangerProfile(context: context)
            ranger.id = rangerID
            ranger.displayName = "Test"
            ranger.role = "ranger"
            ranger.createdAt = Date()
            ranger.updatedAt = Date()
            ranger.syncStatus = SyncStatus.synced.rawValue
            try! context.save()
        }

        let stock = await context.perform { context.object(with: stockID) as! PesticideStock }
        await vm.logUsage(for: stock, quantity: 25.0, notes: nil, rangerID: rangerID)

        // Verify stock decreased
        await context.perform {
            let updated = context.object(with: stockID) as! PesticideStock
            XCTAssertEqual(updated.currentQuantity, 75.0, "Stock should decrease from 100 to 75 after using 25")
        }
    }

    func testMultipleUsagesDecrementCorrectly() async {
        let context = persistence.backgroundContext
        var stockID: NSManagedObjectID!
        let rangerID = UUID()

        await context.perform {
            let ranger = RangerProfile(context: context)
            ranger.id = rangerID
            ranger.displayName = "Test"
            ranger.role = "ranger"
            ranger.createdAt = Date()
            ranger.updatedAt = Date()
            ranger.syncStatus = SyncStatus.synced.rawValue

            let stock = PesticideStock(context: context)
            stock.id = UUID()
            stock.createdAt = Date()
            stock.updatedAt = Date()
            stock.productName = "Test"
            stock.unit = "L"
            stock.currentQuantity = 50.0
            stock.minThreshold = 5.0
            stock.syncStatus = SyncStatus.synced.rawValue
            try! context.save()
            stockID = stock.objectID
        }

        let vm = await PesticideViewModel(persistence: persistence)
        let stock = await context.perform { context.object(with: stockID) as! PesticideStock }

        await vm.logUsage(for: stock, quantity: 10.0, notes: nil, rangerID: rangerID)
        await vm.logUsage(for: stock, quantity: 15.0, notes: nil, rangerID: rangerID)

        await context.perform {
            let updated = context.object(with: stockID) as! PesticideStock
            XCTAssertEqual(updated.currentQuantity, 25.0, "Stock should be 50 - 10 - 15 = 25")
        }
    }
}
