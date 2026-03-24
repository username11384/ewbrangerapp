import Foundation
import CoreData

final class TreatmentRepository {
    private let persistence: PersistenceController
    private let syncQueueManager: SyncQueueManager

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.syncQueueManager = SyncQueueManager(persistence: persistence)
    }

    func addTreatment(
        to sighting: SightingLog,
        method: TreatmentMethod,
        herbicideProduct: String?,
        outcomeNotes: String?,
        followUpDate: Date?,
        rangerID: UUID
    ) async throws -> TreatmentRecord {
        let context = persistence.backgroundContext
        let sightingID = sighting.objectID
        return try await context.perform {
            let treatment = TreatmentRecord(context: context)
            treatment.id = UUID()
            treatment.createdAt = Date()
            treatment.updatedAt = Date()
            treatment.treatmentDate = Date()
            treatment.method = method.rawValue
            treatment.herbicideProduct = herbicideProduct
            treatment.outcomeNotes = outcomeNotes
            treatment.followUpDate = followUpDate
            treatment.photoFilenames = [] as NSArray
            treatment.syncStatus = SyncStatus.pendingCreate.rawValue

            let sightingObj = context.object(with: sightingID) as? SightingLog
            treatment.sighting = sightingObj

            let rangerPredicate = NSPredicate(format: "id == %@", rangerID as CVarArg)
            if let ranger = try? context.fetchFirst(RangerProfile.self, predicate: rangerPredicate) {
                treatment.ranger = ranger
            }

            // Enqueue sync
            let dto = TreatmentRecordDTO(
                id: treatment.id!.uuidString,
                createdAt: treatment.createdAt!.iso8601String,
                updatedAt: treatment.updatedAt!.iso8601String,
                treatmentDate: treatment.treatmentDate!.iso8601String,
                method: treatment.method!,
                herbicideProduct: treatment.herbicideProduct,
                outcomeNotes: treatment.outcomeNotes,
                followUpDate: treatment.followUpDate?.iso8601String,
                photoFilenames: [],
                sightingID: sightingObj?.id?.uuidString ?? "",
                rangerID: rangerID.uuidString
            )
            if let payload = try? JSONEncoder().encode(dto) {
                self.syncQueueManager.enqueue(
                    entityName: "TreatmentRecord",
                    entityID: treatment.id!,
                    operationType: "create",
                    payload: payload,
                    context: context
                )
            }

            try context.save()
            return treatment
        }
    }

    func fetchTreatments(for sighting: SightingLog) throws -> [TreatmentRecord] {
        let predicate = NSPredicate(format: "sighting == %@", sighting)
        return try persistence.mainContext.fetchAll(
            TreatmentRecord.self,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "treatmentDate", ascending: false)]
        )
    }
}
