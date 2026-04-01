import Combine
import Foundation
import CoreData

@MainActor
final class PesticideViewModel: ObservableObject {
    @Published var stocks: [PesticideStock] = []
    @Published var lowStockItems: [PesticideStock] = []

    private let persistence: PersistenceController
    private let syncQueueManager: SyncQueueManager

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.syncQueueManager = SyncQueueManager(persistence: persistence)
        load()
    }

    func load() {
        stocks = (try? persistence.mainContext.fetchAll(
            PesticideStock.self,
            sortDescriptors: [NSSortDescriptor(key: "productName", ascending: true)]
        )) ?? []
        lowStockItems = stocks.filter { $0.currentQuantity <= $0.minThreshold }
    }

    func addStock(productName: String, unit: String, initialQuantity: Double, minThreshold: Double) async {
        let context = persistence.backgroundContext
        await context.perform {
            let stock = PesticideStock(context: context)
            stock.id = UUID()
            stock.createdAt = Date()
            stock.updatedAt = Date()
            stock.productName = productName
            stock.unit = unit
            stock.currentQuantity = initialQuantity
            stock.minThreshold = minThreshold
            stock.syncStatus = SyncStatus.pendingCreate.rawValue
            do { try context.save() } catch { print("[PesticideViewModel] addStock save failed: \(error)") }
        }
        load()
    }

    func logUsage(for stock: PesticideStock, quantity: Double, notes: String?, rangerID: UUID) async {
        let context = persistence.backgroundContext
        let stockID = stock.objectID
        await context.perform {
            guard let stockObj = context.object(with: stockID) as? PesticideStock else { return }
            let usage = PesticideUsageRecord(context: context)
            usage.id = UUID()
            usage.createdAt = Date()
            usage.updatedAt = Date()
            usage.usedQuantity = quantity
            usage.usedAt = Date()
            usage.notes = notes
            usage.stock = stockObj
            usage.syncStatus = SyncStatus.pendingCreate.rawValue

            let rangerPredicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: rangerPredicate) {
                usage.ranger = ranger
            }

            // Decrement currentQuantity by usage amount
            stockObj.currentQuantity -= quantity
            stockObj.updatedAt = Date()
            stockObj.syncStatus = SyncStatus.pendingUpdate.rawValue

            do { try context.save() } catch { print("[PesticideViewModel] logUsage save failed: \(error)") }
        }
        load()
    }

    func usageHistory(for stock: PesticideStock) -> [PesticideUsageRecord] {
        let records = stock.usageRecords?.allObjects as? [PesticideUsageRecord] ?? []
        return records.sorted { ($0.usedAt ?? Date()) > ($1.usedAt ?? Date()) }
    }
}
