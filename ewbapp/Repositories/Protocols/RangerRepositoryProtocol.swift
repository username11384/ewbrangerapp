import Foundation
import CoreData

protocol RangerRepositoryProtocol {
    func fetchCurrentRanger() throws -> RangerProfile?
    func fetchAllRangers() throws -> [RangerProfile]
    func createRanger(displayName: String, role: RangerRole, supabaseUID: String) async throws -> RangerProfile
    func setCurrentDevice(rangerID: UUID) async throws
}
