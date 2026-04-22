import Foundation
import Combine

// MARK: - ChecklistItemState

/// In-memory toggle state for a single ChecklistItem during an active patrol session.
struct ChecklistItemState: Identifiable {
    let item: ChecklistItem
    var isChecked: Bool = false
    var checkedAt: Date? = nil

    var id: UUID { item.id }

    mutating func toggle() {
        isChecked.toggle()
        checkedAt = isChecked ? Date() : nil
    }
}

// MARK: - PatrolChecklistViewModel

/// Holds the per-patrol-session checklist state for the current area.
/// State is in-memory only — resets each time a new area checklist is loaded.
@MainActor
final class PatrolChecklistViewModel: ObservableObject {
    @Published private(set) var states: [ChecklistItemState] = []
    @Published private(set) var areaName: String = ""

    // MARK: Derived

    var completedCount: Int { states.filter(\.isChecked).count }
    var totalCount: Int { states.count }

    var completionFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    // MARK: Public API

    /// Load checklist items for the given area, resetting any prior state.
    func load(for area: String) {
        areaName = area
        states = AreaChecklists.items(for: area).map { ChecklistItemState(item: $0) }
    }

    /// Toggle the checked state of the item with the given id.
    func toggle(id: UUID) {
        guard let idx = states.firstIndex(where: { $0.id == id }) else { return }
        states[idx].toggle()
    }

    /// Reset all items back to unchecked (e.g. on patrol start).
    func reset() {
        for idx in states.indices {
            states[idx].isChecked = false
            states[idx].checkedAt = nil
        }
    }

    // MARK: Category helpers

    var categories: [String] {
        var seen = Set<String>()
        return states.compactMap { state -> String? in
            let cat = state.item.category
            return seen.insert(cat).inserted ? cat : nil
        }
    }

    func states(for category: String) -> [ChecklistItemState] {
        states.filter { $0.item.category == category }
    }
}
