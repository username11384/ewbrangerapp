import Foundation

// MARK: - PatrolViewModel + Area Checklist

extension PatrolViewModel {
    /// The custom checklist items defined for the currently active (or selected) area.
    /// Returns items from AreaChecklists keyed by the active patrol's area name,
    /// or falls back to the selected area name when no patrol is active.
    var currentAreaChecklist: [ChecklistItem] {
        let area = activePatrol?.areaName ?? selectedAreaName
        return AreaChecklists.items(for: area)
    }
}
