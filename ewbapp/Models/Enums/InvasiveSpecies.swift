import SwiftUI

// MARK: - InvasiveSpecies
// Multi-species replacement for the old LantanaVariant enum.
// CoreData stores the rawValue as a String — no schema change required.

enum SpeciesCategory: String {
    case shrub = "shrub"
    case vine  = "vine"
    case tree  = "tree"
    case grass = "grass"

    var displayName: String {
        switch self {
        case .shrub: return "Shrub"
        case .vine:  return "Vine"
        case .tree:  return "Tree"
        case .grass: return "Grass"
        }
    }

    var iconName: String {
        switch self {
        case .shrub: return "leaf.fill"
        case .vine:  return "tornado"
        case .tree:  return "tree.fill"
        case .grass: return "wind"
        }
    }
}

enum InvasiveSpecies: String, CaseIterable, Codable {
    case lantana          = "lantana"
    case rubberVine       = "rubberVine"
    case pricklyAcacia    = "pricklyAcacia"
    case sicklepod        = "sicklepod"
    case giantRatsTailGrass = "giantRatsTailGrass"
    case pondApple        = "pondApple"
    case unknown          = "unknown"

    // MARK: - Display

    var displayName: String {
        switch self {
        case .lantana:              return "Lantana"
        case .rubberVine:           return "Rubber Vine"
        case .pricklyAcacia:        return "Prickly Acacia"
        case .sicklepod:            return "Sicklepod"
        case .giantRatsTailGrass:   return "Giant Rat's Tail Grass"
        case .pondApple:            return "Pond Apple"
        case .unknown:              return "Unknown"
        }
    }

    var scientificName: String {
        switch self {
        case .lantana:              return "Lantana camara"
        case .rubberVine:           return "Cryptostegia grandiflora"
        case .pricklyAcacia:        return "Vachellia nilotica"
        case .sicklepod:            return "Senna obtusifolia"
        case .giantRatsTailGrass:   return "Sporobolus pyramidalis"
        case .pondApple:            return "Annona glabra"
        case .unknown:              return "Species unidentified"
        }
    }

    var category: SpeciesCategory {
        switch self {
        case .lantana:              return .shrub
        case .rubberVine:           return .vine
        case .pricklyAcacia:        return .tree
        case .sicklepod:            return .shrub
        case .giantRatsTailGrass:   return .grass
        case .pondApple:            return .tree
        case .unknown:              return .shrub
        }
    }

    // MARK: - Visual Identity

    var color: Color {
        switch self {
        case .lantana:              return .dsSpeciesLantana
        case .rubberVine:           return .dsSpeciesRubberVine
        case .pricklyAcacia:        return .dsSpeciesPricklyAcacia
        case .sicklepod:            return .dsSpeciesSicklepod
        case .giantRatsTailGrass:   return .dsSpeciesRatsTailGrass
        case .pondApple:            return .dsSpeciesPondApple
        case .unknown:              return .dsSpeciesUnknown
        }
    }

    /// SF Symbol that best represents this species' growth form
    var iconName: String {
        switch self {
        case .lantana:              return "leaf.fill"
        case .rubberVine:           return "arrow.clockwise.circle.fill"
        case .pricklyAcacia:        return "tree.fill"
        case .sicklepod:            return "moon.fill"
        case .giantRatsTailGrass:   return "wind"
        case .pondApple:            return "drop.fill"
        case .unknown:              return "questionmark.circle.fill"
        }
    }

    // MARK: - Field ID

    var distinguishingFeatures: String {
        switch self {
        case .lantana:
            return "Dense shrub with rough, wrinkled leaves. Flower heads contain multiple small flowers that change colour as they age — often pink/orange/yellow on the same head. Distinctive unpleasant smell when foliage is crushed."
        case .rubberVine:
            return "Vigorous woody vine climbing high into tree canopy. Large, leathery glossy leaves in opposite pairs. Pink or purple trumpet-shaped flowers. Seed pods in V-shaped pairs releasing white silky fibre."
        case .pricklyAcacia:
            return "Small thorny tree with pairs of straight white spines at leaf nodes. Yellow ball-shaped flowers. Long flat seed pods in clusters. Often found along creek lines and floodplains."
        case .sicklepod:
            return "Erect annual herb to 1.5m. Leaves have 3 pairs of leaflets with distinctive gland at base of lowest pair. Yellow flowers followed by long curved sickle-shaped seed pods. Characteristic unpleasant smell."
        case .giantRatsTailGrass:
            return "Tussock grass forming large dense clumps 1–1.5m tall. Narrow leaves. Distinctive tall flower spikes (ratails) 15–30cm long with rough, bristly texture. Often invades roadsides, cleared land, and open woodlands."
        case .pondApple:
            return "Small to medium riparian tree with large, oval, glossy leaves. Cream flowers followed by large warty yellow-green fruit (resembling a rough apple) floating in water. Found in freshwater wetlands and stream margins."
        case .unknown:
            return "Species not clearly identifiable in the field. Record location and photos. Treat as the most likely species based on habitat and growth form."
        }
    }

    // MARK: - Control

    var controlMethods: [TreatmentMethod] {
        switch self {
        case .lantana:
            return [.foliarSpray, .cutStump, .basalBark, .splatGun]
        case .rubberVine:
            return [.stemInjection, .cutStump, .foliarSpray, .basalBark]
        case .pricklyAcacia:
            return [.cutStump, .stemInjection, .foliarSpray]
        case .sicklepod:
            return [.mechanical, .foliarSpray]
        case .giantRatsTailGrass:
            return [.foliarSpray, .fireManagement, .mechanical]
        case .pondApple:
            return [.stemInjection, .cutStump, .foliarSpray]
        case .unknown:
            return [.foliarSpray, .cutStump]
        }
    }

    var seasonalNotes: String? {
        switch self {
        case .lantana:
            return "Autumn (Apr–May) is optimal for foliar spray. Wet season: check for biocontrol insects before spraying. Avoid treatment when plants are drought-stressed."
        case .rubberVine:
            return "Flowers Aug–Oct. This is the best time to identify new plants. Treat before seed set to prevent spread via floodwaters. Stem injection effective year-round."
        case .pricklyAcacia:
            return "Pods fall dry season (May–Sep), spreading seed. Focus removal efforts before pod fall. Biological control agents (seed-feeding weevils) may be active — check before spraying."
        case .sicklepod:
            return "Flowers and seeds prolifically in wet season. Mechanical removal is most effective when young (< 30cm). Remove before seeding."
        case .giantRatsTailGrass:
            return "Seed heads ripen in late dry season (Aug–Oct). Slashing/burning before seed set reduces spread. Wet season burning can be effective in suitable conditions."
        case .pondApple:
            return "Fruit floats and spreads via water. Focus removal on upstream plants first to prevent downstream spread. Most effective to treat when fruit is immature."
        case .unknown:
            return nil
        }
    }

    // MARK: - Biocontrol flag (Lantana only)
    var hasBiocontrolConcern: Bool { self == .lantana }

    // MARK: - Backward compatibility with old LantanaVariant raw values
    /// Maps legacy Lantana variant strings ("pink", "red", "pinkEdgedRed", "orange", "white")
    /// to .lantana so old CoreData records display correctly.
    static func from(legacyVariant raw: String) -> InvasiveSpecies {
        // First try a direct InvasiveSpecies match (for new records)
        if let direct = InvasiveSpecies(rawValue: raw) {
            return direct
        }
        // Map any old LantanaVariant value → .lantana
        let lantanaLegacyValues: Set<String> = ["pink", "red", "pinkEdgedRed", "orange", "white"]
        if lantanaLegacyValues.contains(raw) {
            return .lantana
        }
        return .unknown
    }
}
