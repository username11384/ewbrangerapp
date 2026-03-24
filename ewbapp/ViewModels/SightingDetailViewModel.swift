import Combine
import Foundation
import CoreData

@MainActor
final class SightingDetailViewModel: ObservableObject {
    @Published var sighting: SightingLog
    @Published var treatments: [TreatmentRecord] = []
    @Published var allZones: [InfestationZone] = []

    private let treatmentRepository: TreatmentRepository
    private let zoneRepository: ZoneRepository
    private let persistence: PersistenceController

    init(sighting: SightingLog, persistence: PersistenceController) {
        self.sighting = sighting
        self.persistence = persistence
        self.treatmentRepository = TreatmentRepository(persistence: persistence)
        self.zoneRepository = ZoneRepository(persistence: persistence)
        loadTreatments()
        loadZones()
    }

    func loadTreatments() {
        treatments = (try? treatmentRepository.fetchTreatments(for: sighting)) ?? []
    }

    func loadZones() {
        allZones = (try? zoneRepository.fetchAllZones()) ?? []
    }

    func assignToZone(_ zone: InfestationZone?) {
        Task {
            try? await zoneRepository.assignSighting(sighting, to: zone)
            await MainActor.run { loadZones() }
        }
    }

    var assignedZone: InfestationZone? { sighting.infestationZone }

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
