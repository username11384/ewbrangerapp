import Foundation
import CoreData

protocol ZoneRepositoryProtocol {
    func fetchAllZones() throws -> [InfestationZone]
    func createZone(name: String?, dominantVariant: LantanaVariant) async throws -> InfestationZone
    func addSnapshot(to zone: InfestationZone, coordinates: [[Double]], area: Double, rangerID: UUID) async throws
}
