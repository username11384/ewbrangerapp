import Foundation

// MARK: - ChecklistItem

struct ChecklistItem: Identifiable {
    let id: UUID
    let title: String
    let category: String // "Safety", "Weed", "Wildlife", "Infrastructure"

    init(id: UUID = UUID(), title: String, category: String) {
        self.id = id
        self.title = title
        self.category = category
    }
}

// MARK: - AreaChecklists

/// Per-area custom checklist items keyed by zone name (matching PortStewartZones.patrolAreas).
enum AreaChecklists {
    static let items: [String: [ChecklistItem]] = [
        "North Beach Dunes": [
            ChecklistItem(title: "Check vehicle access track condition", category: "Infrastructure"),
            ChecklistItem(title: "Inspect dune fencing for damage", category: "Infrastructure"),
            ChecklistItem(title: "Photo any weed hotspot along dune face", category: "Weed"),
            ChecklistItem(title: "Record beach-cast debris or hazards", category: "Safety"),
            ChecklistItem(title: "Check shorebird nesting areas", category: "Wildlife"),
            ChecklistItem(title: "Document spinifex cover extent", category: "Weed"),
        ],
        "River Mouth Flats": [
            ChecklistItem(title: "Assess water crossing safety before crossing", category: "Safety"),
            ChecklistItem(title: "Check for saltwater crocodile signs", category: "Wildlife"),
            ChecklistItem(title: "Inspect floodplain for Para grass spread", category: "Weed"),
            ChecklistItem(title: "Photo new weed infestations", category: "Weed"),
            ChecklistItem(title: "Check fish traps or cultural sites undisturbed", category: "Infrastructure"),
            ChecklistItem(title: "Record migratory waterbird species present", category: "Wildlife"),
        ],
        "Camping Ground Perimeter": [
            ChecklistItem(title: "Check campfire rings for hazard", category: "Safety"),
            ChecklistItem(title: "Inspect toilet and waste facilities", category: "Infrastructure"),
            ChecklistItem(title: "Clear walking tracks of fallen debris", category: "Infrastructure"),
            ChecklistItem(title: "Photo any new weed incursion near campsites", category: "Weed"),
            ChecklistItem(title: "Check signage is legible and in place", category: "Infrastructure"),
            ChecklistItem(title: "Record any wildlife disturbance or damage", category: "Wildlife"),
        ],
        "Airstrip Corridor": [
            ChecklistItem(title: "Walk full length of airstrip — no obstructions", category: "Safety"),
            ChecklistItem(title: "Check windsock condition and visibility", category: "Infrastructure"),
            ChecklistItem(title: "Inspect grass cover on strip surface", category: "Infrastructure"),
            ChecklistItem(title: "Photo Sorghum or Buffel grass encroachment", category: "Weed"),
            ChecklistItem(title: "Confirm perimeter markers are intact", category: "Infrastructure"),
            ChecklistItem(title: "Check for animal burrows on strip edges", category: "Wildlife"),
        ],
        "Southern Scrub Belt": [
            ChecklistItem(title: "Check vehicle track for wash-outs", category: "Infrastructure"),
            ChecklistItem(title: "Identify Lantana thickets — GPS mark each", category: "Weed"),
            ChecklistItem(title: "Photo Rubber Vine flowering or fruiting", category: "Weed"),
            ChecklistItem(title: "Check treatment sites from last patrol", category: "Weed"),
            ChecklistItem(title: "Note regrowth on previously treated plants", category: "Weed"),
            ChecklistItem(title: "Record mammal tracks or diggings", category: "Wildlife"),
        ],
        "Creek Line East": [
            ChecklistItem(title: "Assess bank erosion at crossing points", category: "Infrastructure"),
            ChecklistItem(title: "Check water quality — clarity and odour", category: "Safety"),
            ChecklistItem(title: "Inspect Pond Apple and Water Hyacinth", category: "Weed"),
            ChecklistItem(title: "Photo any new aquatic weed patches", category: "Weed"),
            ChecklistItem(title: "Record freshwater turtle or fish activity", category: "Wildlife"),
            ChecklistItem(title: "Check for unauthorised vehicle tracks", category: "Safety"),
        ],
        "Creek Line West": [
            ChecklistItem(title: "Assess bank erosion at crossing points", category: "Infrastructure"),
            ChecklistItem(title: "Check water quality — clarity and odour", category: "Safety"),
            ChecklistItem(title: "Inspect riparian zone for weed incursion", category: "Weed"),
            ChecklistItem(title: "Photo Camphor Laurel or Sicklepod spread", category: "Weed"),
            ChecklistItem(title: "Record freshwater turtle or fish activity", category: "Wildlife"),
            ChecklistItem(title: "Check for unauthorised vehicle tracks", category: "Safety"),
        ],
        "Headland Track": [
            ChecklistItem(title: "Check cliff edge safety barriers", category: "Safety"),
            ChecklistItem(title: "Inspect track surface for erosion", category: "Infrastructure"),
            ChecklistItem(title: "Photo weed species on rocky headland", category: "Weed"),
            ChecklistItem(title: "Record seabird nesting or roosting activity", category: "Wildlife"),
            ChecklistItem(title: "Check interpretive signage condition", category: "Infrastructure"),
            ChecklistItem(title: "Confirm emergency cache location accessible", category: "Safety"),
        ],
        "Mangrove Edge": [
            ChecklistItem(title: "Check crocodile warning signs in place", category: "Safety"),
            ChecklistItem(title: "Do not approach water edge without spotter", category: "Safety"),
            ChecklistItem(title: "Inspect mangrove fringe for Spare-thorned Acacia", category: "Weed"),
            ChecklistItem(title: "Photo any mangrove dieback areas", category: "Wildlife"),
            ChecklistItem(title: "Record mud-flat bird species (shorebirds)", category: "Wildlife"),
            ChecklistItem(title: "Check boardwalk or entry track condition", category: "Infrastructure"),
        ],
        "Central Clearing": [
            ChecklistItem(title: "Check equipment shed is secured", category: "Infrastructure"),
            ChecklistItem(title: "Inspect herbicide storage area for leaks", category: "Safety"),
            ChecklistItem(title: "Restock first-aid kit if needed", category: "Safety"),
            ChecklistItem(title: "Photo any weed spread into clearing margins", category: "Weed"),
            ChecklistItem(title: "Record any feral animal tracks or signs", category: "Wildlife"),
            ChecklistItem(title: "Confirm radio / satellite communicator charged", category: "Safety"),
        ],
    ]

    /// Returns checklist items for the given area, or a fallback set if the area is not found.
    static func items(for area: String) -> [ChecklistItem] {
        items[area] ?? fallback(for: area)
    }

    private static func fallback(for area: String) -> [ChecklistItem] {
        [
            ChecklistItem(title: "Walk full boundary of \(area)", category: "Safety"),
            ChecklistItem(title: "Photo new infestations", category: "Weed"),
            ChecklistItem(title: "Record all invasive plant sightings", category: "Weed"),
            ChecklistItem(title: "Check previous treatment sites", category: "Weed"),
            ChecklistItem(title: "Note regrowth on treated plants", category: "Weed"),
        ]
    }
}
