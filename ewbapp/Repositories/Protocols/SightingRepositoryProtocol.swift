import Foundation
import CoreData

protocol SightingRepositoryProtocol {
    func createSighting(
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        variant: LantanaVariant,
        infestationSize: InfestationSize,
        notes: String?,
        photoFilenames: [String],
        rangerID: UUID
    ) async throws -> SightingLog

    func fetchAllSightings() throws -> [SightingLog]
    func fetchSightings(since date: Date) throws -> [SightingLog]
    func deleteSighting(_ sighting: SightingLog) async throws
}
