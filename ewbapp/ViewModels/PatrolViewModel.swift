import Combine
import Foundation
import CoreData

@MainActor
final class PatrolViewModel: ObservableObject {
    @Published var patrols: [PatrolRecord] = []
    @Published var activePatrol: PatrolRecord?
    @Published var activeChecklistItems: [PatrolChecklistItem] = []
    @Published var selectedAreaName: String = PortStewartZones.patrolAreas[0]

    private let repository: PatrolRepository
    private let rangerID: UUID

    init(persistence: PersistenceController, rangerID: UUID) {
        self.repository = PatrolRepository(persistence: persistence)
        self.rangerID = rangerID
        load()
    }

    func load() {
        patrols = (try? repository.fetchAllPatrols()) ?? []
        activePatrol = try? repository.fetchActivePatrol(rangerID: rangerID)
        if let patrol = activePatrol {
            activeChecklistItems = loadChecklist(from: patrol)
        }
    }

    func startPatrol() async {
        guard activePatrol == nil else { return }
        do {
            let patrol = try await repository.createPatrol(areaName: selectedAreaName, rangerID: rangerID)
            activePatrol = patrol
            activeChecklistItems = loadChecklist(from: patrol)
            patrols.insert(patrol, at: 0)
        } catch {
            print("Failed to create patrol: \(error)")
        }
    }

    func toggleItem(_ item: PatrolChecklistItem) async {
        guard let patrol = activePatrol else { return }
        var items = activeChecklistItems
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isComplete.toggle()
            items[idx].completedAt = items[idx].isComplete ? Date() : nil
        }
        activeChecklistItems = items
        try? await repository.updateChecklist(patrol: patrol, items: items)
    }

    func finishPatrol() async {
        guard let patrol = activePatrol else { return }
        do {
            try await repository.finishPatrol(patrol)
            activePatrol = nil
            activeChecklistItems = []
            load()
        } catch {
            print("Failed to finish patrol: \(error)")
        }
    }

    private func loadChecklist(from patrol: PatrolRecord) -> [PatrolChecklistItem] {
        guard let data = patrol.checklistItems as? Data,
              let items = try? JSONDecoder().decode([PatrolChecklistItem].self, from: data) else {
            return PortStewartZones.defaultChecklist(for: patrol.areaName ?? "")
        }
        return items
    }

    var completionPercentage: Double {
        guard !activeChecklistItems.isEmpty else { return 0 }
        let completed = activeChecklistItems.filter { $0.isComplete }.count
        return Double(completed) / Double(activeChecklistItems.count)
    }
}
