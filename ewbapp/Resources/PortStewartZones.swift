import Foundation

struct PortStewartZones {
    static let patrolAreas: [String] = [
        "North Beach Dunes",
        "River Mouth Flats",
        "Camping Ground Perimeter",
        "Airstrip Corridor",
        "Southern Scrub Belt",
        "Creek Line East",
        "Creek Line West",
        "Headland Track",
        "Mangrove Edge",
        "Central Clearing"
    ]

    static let defaultChecklist: [PatrolChecklistItem] = [
        PatrolChecklistItem(label: "Check GPS is recording"),
        PatrolChecklistItem(label: "Photograph new infestations"),
        PatrolChecklistItem(label: "Record all Lantana sightings"),
        PatrolChecklistItem(label: "Check previous treatment sites"),
        PatrolChecklistItem(label: "Note regrowth on treated plants"),
        PatrolChecklistItem(label: "Check pesticide supply before departing")
    ]

    static func defaultChecklist(for area: String) -> [PatrolChecklistItem] {
        var items = Self.defaultChecklist
        items.insert(PatrolChecklistItem(label: "Walk full boundary of \(area)"), at: 0)
        return items
    }
}
