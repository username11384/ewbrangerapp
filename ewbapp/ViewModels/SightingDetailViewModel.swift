import Combine
import Foundation
import CoreData

@MainActor
final class SightingDetailViewModel: ObservableObject {
    @Published var sighting: SightingLog
    @Published var treatments: [TreatmentRecord] = []

    private let treatmentRepository: TreatmentRepository
    private let persistence: PersistenceController

    init(sighting: SightingLog, persistence: PersistenceController) {
        self.sighting = sighting
        self.persistence = persistence
        self.treatmentRepository = TreatmentRepository(persistence: persistence)
        loadTreatments()
    }

    func loadTreatments() {
        treatments = (try? treatmentRepository.fetchTreatments(for: sighting)) ?? []
    }

    var variant: LantanaVariant {
        LantanaVariant(rawValue: sighting.variant ?? "") ?? .unknown
    }

    var size: InfestationSize {
        InfestationSize(rawValue: sighting.infestationSize ?? "") ?? .small
    }

    var syncStatus: SyncStatus {
        SyncStatus(rawValue: sighting.syncStatus) ?? .pendingCreate
    }

    var canEdit: Bool {
        syncStatus != .synced
    }

    var photoFilenames: [String] {
        sighting.photoFilenames as? [String] ?? []
    }
}
