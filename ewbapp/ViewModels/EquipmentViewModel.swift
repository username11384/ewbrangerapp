import Combine
import CoreData
import Foundation

@MainActor
final class EquipmentViewModel: ObservableObject {
    @Published var equipment: [Equipment] = []
    @Published var maintenanceRecords: [MaintenanceRecord] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
        load()
    }

    // MARK: - Computed

    var overdueItems: [Equipment] {
        let today = Date()
        return equipment.filter { item in
            guard let due = item.nextMaintenanceDue else { return false }
            return due < today
        }
    }

    var dueSoonItems: [Equipment] {
        let today = Date()
        guard let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: today) else { return [] }
        return equipment.filter { item in
            guard let due = item.nextMaintenanceDue else { return false }
            return due >= today && due <= twoWeeks
        }
    }

    // MARK: - Load

    func load() {
        equipment = (try? persistence.mainContext.fetchAll(
            Equipment.self,
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        )) ?? []
        maintenanceRecords = (try? persistence.mainContext.fetchAll(
            MaintenanceRecord.self,
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        )) ?? []
    }

    // MARK: - Add Equipment

    func addEquipment(name: String, type: String, serial: String?, notes: String?) {
        let context = persistence.backgroundContext
        context.perform {
            let item = Equipment(context: context)
            item.id = UUID()
            item.name = name
            item.equipmentType = type
            item.serialNumber = serial?.isEmpty == false ? serial : nil
            item.notes = notes?.isEmpty == false ? notes : nil
            item.isActive = true
            item.createdAt = Date()
            item.updatedAt = Date()
            do { try context.save() } catch { print("[EquipmentViewModel] addEquipment save failed: \(error)") }
        }
        // Refresh on main after background save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.load() }
    }

    // MARK: - Log Maintenance

    func logMaintenance(
        for item: Equipment,
        type: String,
        description: String,
        performedBy: String,
        cost: Double?
    ) {
        let context = persistence.backgroundContext
        let itemID = item.objectID
        context.perform {
            guard let equipObj = context.object(with: itemID) as? Equipment else { return }
            let record = MaintenanceRecord(context: context)
            record.id = UUID()
            record.equipmentID = equipObj.id ?? UUID()
            record.maintenanceType = type
            record.descriptionText = description
            record.performedBy = performedBy
            record.costAmount = cost ?? 0
            record.date = Date()
            record.equipment = equipObj

            equipObj.lastMaintenanceDate = Date()
            equipObj.nextMaintenanceDue = Calendar.current.date(byAdding: .day, value: 90, to: Date())
            equipObj.updatedAt = Date()

            do { try context.save() } catch { print("[EquipmentViewModel] logMaintenance save failed: \(error)") }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.load() }
    }

    // MARK: - Delete

    func deleteEquipment(_ item: Equipment) {
        let context = persistence.backgroundContext
        let objID = item.objectID
        context.perform {
            let obj = context.object(with: objID)
            context.delete(obj)
            do { try context.save() } catch { print("[EquipmentViewModel] delete failed: \(error)") }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.load() }
    }

    func records(for item: Equipment) -> [MaintenanceRecord] {
        maintenanceRecords.filter { $0.equipmentID == item.id }
    }
}
