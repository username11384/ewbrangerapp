import Foundation
import CoreData

final class ZoneRepository: ZoneRepositoryProtocol {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAllZones() throws -> [InfestationZone] {
        try persistence.mainContext.fetchAll(InfestationZone.self)
    }

    func createZone(name: String?, dominantVariant: LantanaVariant) async throws -> InfestationZone {
        let context = persistence.backgroundContext
        return try await context.perform {
            let zone = InfestationZone(context: context)
            zone.id = UUID()
            zone.createdAt = Date()
            zone.updatedAt = Date()
            zone.name = name
            zone.status = "active"
            zone.dominantVariant = dominantVariant.rawValue
            zone.syncStatus = SyncStatus.pendingCreate.rawValue
            try context.save()
            return zone
        }
    }

    func updateZone(_ zone: InfestationZone, name: String?, dominantVariant: LantanaVariant, status: String) async throws {
        let context = persistence.backgroundContext
        let objectID = zone.objectID
        try await context.perform {
            guard let obj = context.object(with: objectID) as? InfestationZone else { return }
            obj.name = name
            obj.dominantVariant = dominantVariant.rawValue
            obj.status = status
            obj.updatedAt = Date()
            obj.syncStatus = SyncStatus.pendingUpdate.rawValue
            try context.save()
        }
    }

    func deleteZone(_ zone: InfestationZone) async throws {
        let context = persistence.backgroundContext
        let objectID = zone.objectID
        try await context.perform {
            let obj = context.object(with: objectID)
            context.delete(obj)
            try context.save()
        }
    }

    func addSnapshot(to zone: InfestationZone, coordinates: [[Double]], area: Double, rangerID: UUID) async throws {
        let context = persistence.backgroundContext
        let zoneID = zone.objectID
        try await context.perform {
            guard let zoneObj = context.object(with: zoneID) as? InfestationZone else { return }
            let snapshot = InfestationZoneSnapshot(context: context)
            snapshot.id = UUID()
            snapshot.snapshotDate = Date()
            snapshot.polygonCoordinates = coordinates as NSArray
            snapshot.area = area
            snapshot.createdByRangerID = rangerID
            snapshot.zone = zoneObj
            try context.save()
        }
    }
}
