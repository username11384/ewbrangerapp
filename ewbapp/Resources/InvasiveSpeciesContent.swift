import Foundation

// MARK: - InvasiveSpeciesContent
// Field guide content for all tracked invasive plant species.
// Replaces the old LantanaVariantContent with a multi-species system.

enum InvasiveSpeciesContent {

    struct SpeciesInfo {
        let species: InvasiveSpecies
        let commonName: String
        let scientificName: String
        /// Asset catalog image name — falls back gracefully if nil
        let imageName: String?
        let identifyingFeatures: String
        let controlMethods: [TreatmentMethod]
        let seasonalNotes: String?
        let priorityLevel: PriorityLevel

        enum PriorityLevel: String {
            case critical = "Critical"
            case high     = "High"
            case moderate = "Moderate"
        }
    }

    static let all: [SpeciesInfo] = [
        SpeciesInfo(
            species: .lantana,
            commonName: "Lantana",
            scientificName: "Lantana camara",
            imageName: "demo_lantana_1",
            identifyingFeatures: """
            Dense, branching shrub 0.5–4m tall. Stems are square in cross-section with small downward-curved prickles.

            Leaves: Opposite, oval, 2–10cm, with toothed margins and a rough sandpaper-like surface. Strong unpleasant smell when crushed.

            Flowers: Small tubular flowers in flat-topped clusters (2–3cm across). Flowers change colour with age — often mixed pink, orange, and yellow on the same head. Multiple colour forms occur.

            Fruit: Small, fleshy berries, green turning shiny black when ripe. Berries are toxic to livestock and humans.

            Habitat: Roadsides, creek lines, disturbed land, cleared areas, coastal scrub.
            """,
            controlMethods: [.foliarSpray, .cutStump, .basalBark, .splatGun],
            seasonalNotes: "Autumn (Apr–May) optimal for foliar spray and basal bark. During wet season, check for lantana bug (Aconophora compressa) before applying herbicide to pink-flowered plants — biocontrol insects may be present. Avoid spraying drought-stressed plants.",
            priorityLevel: .critical
        ),

        SpeciesInfo(
            species: .rubberVine,
            commonName: "Rubber Vine",
            scientificName: "Cryptostegia grandiflora",
            imageName: nil,
            identifyingFeatures: """
            Vigorous woody vine or scrambling shrub reaching high into tree canopy. Produces milky latex sap when cut.

            Leaves: Opposite, broadly oval, 5–10cm, dark glossy green with prominent central vein. Thick and leathery.

            Flowers: Large (5–7cm) pink to pale purple funnel-shaped flowers. Flowers Aug–Oct.

            Seed pods: Distinctive V-shaped pairs, 8–12cm long, grey-green turning brown. When dry they split to release seeds attached to white silky fibres that float on wind and water.

            Habitat: River banks, floodplains, creek lines, open woodland. Spreads via floodwater.
            """,
            controlMethods: [.stemInjection, .cutStump, .foliarSpray, .basalBark],
            seasonalNotes: "Peak flowering Aug–Oct — best identification time. Treat before seed set (Oct–Nov) to prevent floodwater dispersal. Stem injection is effective year-round and minimises herbicide exposure near waterways.",
            priorityLevel: .critical
        ),

        SpeciesInfo(
            species: .pricklyAcacia,
            commonName: "Prickly Acacia",
            scientificName: "Vachellia nilotica",
            imageName: nil,
            identifyingFeatures: """
            Small thorny tree 3–7m tall with a spreading, often flat-topped canopy.

            Thorns: Pairs of straight white spines 3–8cm long at each leaf node — distinctive and sharp.

            Leaves: Bipinnate (feathery), dark green, 3–8cm.

            Flowers: Bright yellow, ball-shaped (1cm diameter), clustered at nodes. Highly fragrant. Flowers mainly dry season.

            Pods: Flat, constricted between seeds, forming a knobbly chain 8–20cm long in clusters. Grey-green turning brown.

            Bark: Dark grey, deeply furrowed on mature trees.

            Habitat: Floodplains, creek margins, black soil plains, disturbed pastoral land.
            """,
            controlMethods: [.cutStump, .stemInjection, .foliarSpray],
            seasonalNotes: "Pods form and fall dry season (May–Sep), spreading seed widely. Prioritise removal of seed-bearing trees before pod fall. Biological control agents (seed weevils) may be present — check before spraying.",
            priorityLevel: .high
        ),

        SpeciesInfo(
            species: .sicklepod,
            commonName: "Sicklepod",
            scientificName: "Senna obtusifolia",
            imageName: nil,
            identifyingFeatures: """
            Erect annual herb or short-lived shrub, 0.5–1.5m tall.

            Leaves: Compound with 3 pairs of oval leaflets (2–5cm each). A small gland is visible at the base of the lowest pair of leaflets — a key ID feature.

            Flowers: Yellow, 5 petals, 1–1.5cm. Flowers in leaf axils.

            Pods: Long (10–20cm), narrow, slightly curved like a sickle. Seeds are square-ish, grey-brown.

            Smell: Plant has a characteristic unpleasant smell.

            Habitat: Disturbed roadsides, paddock edges, creek banks, cleared land. Common in higher-rainfall areas.
            """,
            controlMethods: [.mechanical, .foliarSpray],
            seasonalNotes: "Flowers and seeds in wet season (Nov–Apr). Mechanical removal is most effective when plants are young (< 30cm). Prioritise removal before seed set to prevent population growth.",
            priorityLevel: .moderate
        ),

        SpeciesInfo(
            species: .giantRatsTailGrass,
            commonName: "Giant Rat's Tail Grass",
            scientificName: "Sporobolus pyramidalis",
            imageName: nil,
            identifyingFeatures: """
            Robust perennial tussock grass forming large dense clumps 0.5–1.5m tall.

            Leaves: Long, narrow, flat to folded, with a rolled/compressed sheath. Leaf blades are rough to touch.

            Seed heads: Distinctive tall 'rattails' 15–30cm long, rough and bristly. Multiple spikes form a large open panicle. Seeds very small and abundant.

            Roots: Tough, deep root system making mechanical removal difficult once established.

            Habitat: Roadsides, disturbed paddocks, cleared areas, open woodland. Spreads rapidly on disturbed soils.
            """,
            controlMethods: [.foliarSpray, .fireManagement, .mechanical],
            seasonalNotes: "Seed heads ripen late dry season (Aug–Oct). Slashing or burning before seed set significantly reduces spread. Hot late dry-season burns can reduce established clumps. Wet season burning can also be effective in suitable fire management plans.",
            priorityLevel: .high
        ),

        SpeciesInfo(
            species: .pondApple,
            commonName: "Pond Apple",
            scientificName: "Annona glabra",
            imageName: nil,
            identifyingFeatures: """
            Small to medium riparian tree, 3–12m tall.

            Leaves: Large (10–20cm), oval, glossy dark green with prominent veins. Alternate arrangement.

            Flowers: Cream to pale yellow, 3–4cm, with 3 fleshy petals. Slightly unpleasant smell.

            Fruit: Large (7–12cm), irregular spherical, yellow-green, warty surface — resembling a rough apple. The fruit floats and is dispersed by water.

            Habitat: Freshwater wetlands, stream and river margins, swamps, estuarine fringes. Forms dense thickets that displace native riparian vegetation.
            """,
            controlMethods: [.stemInjection, .cutStump, .foliarSpray],
            seasonalNotes: "Fruit floats and spreads downstream. Prioritise removal of upstream plants to prevent downstream seed dispersal. Treat when fruit is immature (before it drops). Stem injection minimises herbicide runoff near waterways.",
            priorityLevel: .high
        ),
    ]

    static func info(for species: InvasiveSpecies) -> SpeciesInfo? {
        all.first { $0.species == species }
    }
}
