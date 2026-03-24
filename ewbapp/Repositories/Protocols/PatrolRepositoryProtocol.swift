import Foundation
import CoreData

protocol PatrolRepositoryProtocol {
    func createPatrol(areaName: String, rangerID: UUID) async throws -> PatrolRecord
    func updateChecklist(patrol: PatrolRecord, items: [PatrolChecklistItem]) async throws
    func finishPatrol(_ patrol: PatrolRecord) async throws
    func fetchAllPatrols() throws -> [PatrolRecord]
    func fetchActivePatrol(rangerID: UUID) throws -> PatrolRecord?
}
