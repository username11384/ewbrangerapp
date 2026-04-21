import Foundation
import CoreData
import UIKit

final class SightingRepository: SightingRepositoryProtocol {
    private let persistence: PersistenceController
    private let syncQueueManager: SyncQueueManager

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.syncQueueManager = SyncQueueManager(persistence: persistence)
    }

    func createSighting(
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        species: InvasiveSpecies,
        infestationSize: InfestationSize,
        notes: String?,
        photoFilenames: [String],
        rangerID: UUID
    ) async throws -> SightingLog {
        let context = persistence.backgroundContext
        return try await context.perform {
            let sighting = SightingLog(context: context)
            sighting.id = UUID()
            sighting.createdAt = Date()
            sighting.updatedAt = Date()
            sighting.latitude = latitude
            sighting.longitude = longitude
            sighting.horizontalAccuracy = horizontalAccuracy
            sighting.variant = species.rawValue
            sighting.infestationSize = infestationSize.rawValue
            sighting.notes = notes
            sighting.photoFilenames = photoFilenames as NSArray
            sighting.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            sighting.syncStatus = SyncStatus.pendingCreate.rawValue

            // Link ranger
            let rangerPredicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: rangerPredicate) {
                sighting.ranger = ranger
            }

            // Enqueue sync — same save transaction
            let dto = self.sightingToDTO(sighting)
            if let sightingID = sighting.id,
               let payload = try? JSONEncoder().encode(dto) {
                self.syncQueueManager.enqueue(
                    entityName: "SightingLog",
                    entityID: sightingID,
                    operationType: "create",
                    payload: payload,
                    context: context
                )
            }

            try context.save()
            return sighting
        }
    }

    func fetchAllSightings() throws -> [SightingLog] {
        try persistence.mainContext.fetchAll(
            SightingLog.self,
            sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
        )
    }

    func fetchSightings(since date: Date) throws -> [SightingLog] {
        try persistence.mainContext.fetchAll(
            SightingLog.self,
            predicate: NSPredicate(format: "updatedAt > %@", date as CVarArg),
            sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: true)]
        )
    }

    func deleteSighting(_ sighting: SightingLog) async throws {
        let context = persistence.backgroundContext
        let objectID = sighting.objectID
        try await context.perform {
            let obj = context.object(with: objectID)
            context.delete(obj)
            try context.save()
        }
    }

    private func sightingToDTO(_ sighting: SightingLog) -> SightingLogDTO {
        SightingLogDTO(
            id: sighting.id?.uuidString ?? UUID().uuidString,
            createdAt: sighting.createdAt?.iso8601String ?? Date().iso8601String,
            updatedAt: sighting.updatedAt?.iso8601String ?? Date().iso8601String,
            latitude: sighting.latitude,
            longitude: sighting.longitude,
            horizontalAccuracy: sighting.horizontalAccuracy,
            variant: sighting.variant ?? "unknown",
            infestationSize: sighting.infestationSize ?? "small",
            notes: sighting.notes,
            photoFilenames: sighting.photoFilenames as? [String] ?? [],
            deviceID: sighting.deviceID ?? "",
            serverID: sighting.serverID,
            syncStatus: Int(sighting.syncStatus),
            rangerID: sighting.ranger?.id?.uuidString ?? "",
            infestationZoneID: sighting.infestationZone?.id?.uuidString
        )
    }
}
